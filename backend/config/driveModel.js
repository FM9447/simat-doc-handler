const { randomUUID } = require('crypto');
const { callDriveDb } = require('./driveDb');

const modelRegistry = new Map();

function deepClone(value) {
  return value === undefined ? undefined : JSON.parse(JSON.stringify(value));
}

function getByPath(obj, path) {
  if (!obj || !path) return undefined;
  return path.split('.').reduce((acc, key) => (acc == null ? undefined : acc[key]), obj);
}

function setByPath(obj, path, value) {
  const parts = path.split('.');
  let current = obj;
  for (let i = 0; i < parts.length - 1; i++) {
    const p = parts[i];
    if (!current[p] || typeof current[p] !== 'object') current[p] = {};
    current = current[p];
  }
  current[parts[parts.length - 1]] = value;
}

function pickFields(obj, fieldsSpec) {
  if (!fieldsSpec) return obj;
  const fields = String(fieldsSpec).split(/\s+/).filter(Boolean);
  if (!fields.length) return obj;

  const include = fields.filter((f) => !f.startsWith('-'));
  const exclude = fields.filter((f) => f.startsWith('-')).map((f) => f.slice(1));

  if (include.length) {
    const next = { _id: obj._id };
    for (const f of include) {
      if (obj[f] !== undefined) next[f] = obj[f];
    }
    return next;
  }

  const next = { ...obj };
  for (const f of exclude) delete next[f];
  return next;
}

function valueMatches(actual, expected) {
  if (expected && typeof expected === 'object' && !Array.isArray(expected)) {
    if ('$in' in expected) return expected.$in.includes(actual);
    if ('$ne' in expected) return actual !== expected.$ne;
    if ('$exists' in expected) {
      const exists = actual !== undefined && actual !== null;
      return expected.$exists ? exists : !exists;
    }
  }
  if (Array.isArray(actual)) {
    if (Array.isArray(expected)) return expected.every((item) => actual.includes(item));
    return actual.includes(expected);
  }
  return actual === expected;
}

function matchesFilter(doc, filter = {}) {
  if (!filter || !Object.keys(filter).length) return true;

  if (filter.$or) {
    if (!Array.isArray(filter.$or) || !filter.$or.some((sub) => matchesFilter(doc, sub))) {
      return false;
    }
  }

  for (const [key, expected] of Object.entries(filter)) {
    if (key === '$or') continue;

    const actual = getByPath(doc, key);
    if (!valueMatches(actual, expected)) return false;
  }
  return true;
}

function applyUpdate(doc, update = {}) {
  if (!update || typeof update !== 'object') return doc;

  if ('$set' in update) {
    for (const [k, v] of Object.entries(update.$set || {})) {
      setByPath(doc, k, v);
    }
  }

  if ('$pull' in update) {
    for (const [k, v] of Object.entries(update.$pull || {})) {
      const current = getByPath(doc, k);
      if (Array.isArray(current)) {
        setByPath(doc, k, current.filter((item) => item !== v));
      }
    }
  }

  for (const [k, v] of Object.entries(update)) {
    if (k.startsWith('$')) continue;
    setByPath(doc, k, v);
  }

  return doc;
}

function getTimestamp(record) {
  return new Date(record.updatedAt || record.createdAt || 0).getTime() || 0;
}

function buildEntityMap(records) {
  const entityMap = new Map();
  for (const record of records) {
    const entityId = record._entityId || record._id;
    if (!entityId) continue;

    const current = entityMap.get(entityId);
    if (!current || getTimestamp(record) >= getTimestamp(current)) {
      entityMap.set(entityId, record);
    }
  }
  return entityMap;
}

function normalizeEntity(record) {
  const clone = deepClone(record) || {};
  const entityId = clone._entityId || clone._id;
  if (entityId) clone._id = entityId;
  return clone;
}

async function fetchCollectionEntities(collection) {
  const response = await callDriveDb('find', collection, {});
  const rows = Array.isArray(response?.data) ? response.data : [];
  const entityMap = buildEntityMap(rows);
  const entities = [];

  for (const item of entityMap.values()) {
    if (item.__deleted) continue;
    entities.push(normalizeEntity(item));
  }

  return entities;
}

class Query {
  constructor(model, filter = {}, opts = {}) {
    this.model = model;
    this.filter = filter;
    this.single = !!opts.single;
    this.populates = [];
    this.selectSpec = null;
    this.sortSpec = null;
    this.limitCount = null;
  }

  populate(path, select) {
    this.populates.push({ path, select });
    return this;
  }

  select(spec) {
    this.selectSpec = spec;
    return this;
  }

  sort(spec) {
    this.sortSpec = spec;
    return this;
  }

  limit(count) {
    this.limitCount = count;
    return this;
  }

  async _populateOne(doc, path, select) {
    const refResolver = this.model._refs[path];
    if (!refResolver) return;

    const RefModel = refResolver();
    if (!RefModel) return;

    const parts = path.split('.');

    const walk = async (target, idx) => {
      if (!target) return;
      const key = parts[idx];
      if (!(key in target)) return;

      if (idx === parts.length - 1) {
        const raw = target[key];

        const populateValue = async (value) => {
          if (!value) return value;
          if (typeof value === 'object' && value._id) return pickFields(value, select);
          const fetched = await RefModel.findById(value);
          return fetched ? pickFields(fetched.toObject ? fetched.toObject() : fetched, select) : value;
        };

        if (Array.isArray(raw)) {
          const out = [];
          for (const v of raw) out.push(await populateValue(v));
          target[key] = out;
        } else {
          target[key] = await populateValue(raw);
        }
        return;
      }

      const next = target[key];
      if (Array.isArray(next)) {
        for (const item of next) {
          await walk(item, idx + 1);
        }
      } else {
        await walk(next, idx + 1);
      }
    };

    await walk(doc, 0);
  }

  async exec() {
    let rows = await this.model._findMany(this.filter);

    if (this.sortSpec && typeof this.sortSpec === 'object') {
      const [[key, direction]] = Object.entries(this.sortSpec);
      rows.sort((a, b) => {
        const av = getByPath(a, key);
        const bv = getByPath(b, key);
        if (av === bv) return 0;
        if (direction < 0) return av > bv ? -1 : 1;
        return av > bv ? 1 : -1;
      });
    }

    if (typeof this.limitCount === 'number') {
      rows = rows.slice(0, this.limitCount);
    }

    const docs = rows.map((row) => this.model.hydrate(row));

    for (const doc of docs) {
      for (const p of this.populates) {
        await this._populateOne(doc, p.path, p.select);
      }

      if (this.selectSpec) {
        const selected = pickFields(doc.toObject(), this.selectSpec);
        Object.keys(doc).forEach((key) => {
          if (!key.startsWith('_')) delete doc[key];
        });
        Object.assign(doc, selected);
      }
    }

    return this.single ? (docs[0] || null) : docs;
  }

  then(resolve, reject) {
    return this.exec().then(resolve, reject);
  }
}

function createModel({ modelName, collection, defaults = {}, baseFilter = {}, refs = {} }) {
  class DriveModel {
    constructor(data = {}) {
      Object.assign(this, deepClone(defaults), deepClone(data));
    }

    static get collection() {
      return collection;
    }

    static get _baseFilter() {
      return baseFilter;
    }

    static get _refs() {
      return refs;
    }

    static hydrate(data) {
      const record = new DriveModel(data);
      return record;
    }

    static _withBaseFilter(filter = {}) {
      return { ...deepClone(this._baseFilter), ...deepClone(filter) };
    }

    static async _findMany(filter = {}) {
      const all = await fetchCollectionEntities(collection);
      const mergedFilter = this._withBaseFilter(filter);
      return all.filter((item) => matchesFilter(item, mergedFilter));
    }

    static find(filter = {}) {
      return new Query(this, filter, { single: false });
    }

    static findOne(filter = {}) {
      return new Query(this, filter, { single: true });
    }

    static findById(id) {
      return new Query(this, { _id: id }, { single: true });
    }

    static async create(data = {}) {
      const doc = new DriveModel(data);
      return doc.save();
    }

    static async countDocuments(filter = {}) {
      const docs = await this._findMany(filter);
      return docs.length;
    }

    static async updateMany(filter = {}, update = {}) {
      const docs = await this._findMany(filter);
      let modifiedCount = 0;
      for (const raw of docs) {
        const next = applyUpdate(deepClone(raw), deepClone(update));
        const doc = this.hydrate(next);
        await doc.save();
        modifiedCount += 1;
      }
      return { modifiedCount };
    }

    static async deleteMany(filter = {}) {
      const docs = await this._findMany(filter);
      for (const raw of docs) {
        await this._softDelete(raw._id);
      }
      return { deletedCount: docs.length };
    }

    static async _softDelete(id) {
      const entityId = id;
      const payload = {
        ...deepClone(baseFilter),
        _entityId: entityId,
        __deleted: true,
        updatedAt: new Date().toISOString(),
      };
      await callDriveDb('insert', collection, payload);
    }

    static async findByIdAndDelete(id) {
      const found = await this.findById(id);
      if (!found) return null;
      await this._softDelete(id);
      return found;
    }

    static async findByIdAndUpdate(id, update = {}) {
      const found = await this.findById(id);
      if (!found) return null;
      applyUpdate(found, deepClone(update));
      return found.save();
    }

    static async findOneAndUpdate(filter = {}, update = {}, options = {}) {
      let found = await this.findOne(filter);

      if (!found && options.upsert) {
        const base = this._withBaseFilter(filter);
        const initial = applyUpdate(base, deepClone(update));
        found = await this.create(initial);
        return found;
      }

      if (!found) return null;

      const original = deepClone(found.toObject());
      applyUpdate(found, deepClone(update));
      const saved = await found.save();
      return options.new ? saved : this.hydrate(original);
    }

    markModified() {
      return;
    }

    async deleteOne() {
      if (!this._id) return;
      await DriveModel._softDelete(this._id);
    }

    toObject() {
      const plain = {};
      for (const [key, value] of Object.entries(this)) {
        if (typeof value === 'function') continue;
        plain[key] = value;
      }
      return deepClone(plain);
    }

    async save() {
      const now = new Date().toISOString();
      const current = this.toObject();
      const entityId = current._entityId || current._id || randomUUID();

      const payload = {
        ...deepClone(baseFilter),
        ...current,
        _entityId: entityId,
        updatedAt: now,
      };

      if (!payload.createdAt) payload.createdAt = now;

      const response = await callDriveDb('insert', collection, payload);
      const saved = normalizeEntity(response?.data || payload);
      saved._entityId = entityId;

      Object.keys(this).forEach((k) => delete this[k]);
      Object.assign(this, saved);
      return this;
    }
  }

  modelRegistry.set(modelName, DriveModel);
  return DriveModel;
}

function getModel(name) {
  return modelRegistry.get(name);
}

module.exports = {
  createModel,
  getModel,
};
