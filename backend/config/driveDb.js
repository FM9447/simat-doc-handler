const crypto = require('crypto');

const DRIVE_DB_ENDPOINT =
  process.env.DRIVE_DB_ENDPOINT ||
  'https://script.google.com/macros/s/AKfycbwfPvUMaMc0hopJGZB2zEmJtDtQoEg45IzW9uEOzseNc0x0lvmVLpxqh7mrVDWSLA4U/exec';

const DRIVE_DB_API_KEY = process.env.DRIVE_DB_API_KEY;

function ensureApiKey() {
  if (!DRIVE_DB_API_KEY) {
    throw new Error('DRIVE_DB_API_KEY is not configured');
  }
}

async function callDriveDb(action, collection, data = {}) {
  ensureApiKey();

  const payload = {
    apiKey: DRIVE_DB_API_KEY,
    action,
    collection,
    data,
  };

  const response = await fetch(DRIVE_DB_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const raw = await response.text();
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (_) {
    throw new Error(`Drive DB invalid JSON response (${response.status}): ${raw.slice(0, 500)}`);
  }

  if (!response.ok) {
    throw new Error(parsed?.message || `Drive DB HTTP ${response.status}`);
  }

  if (parsed.status && parsed.status !== 'success') {
    throw new Error(parsed.message || `Drive DB action failed: ${action}`);
  }

  return parsed;
}

function normalizeBase64(input) {
  const normalized = input.replace(/-/g, '+').replace(/_/g, '/');
  const padLength = (4 - (normalized.length % 4)) % 4;
  return normalized + '='.repeat(padLength);
}

function encodeSessionToken(payload) {
  return Buffer.from(JSON.stringify(payload)).toString('base64url');
}

function decodeSessionToken(token) {
  try {
    const json = Buffer.from(normalizeBase64(token), 'base64').toString('utf8');
    return JSON.parse(json);
  } catch (_) {
    return null;
  }
}

function sha256Hex(value) {
  return crypto.createHash('sha256').update(String(value)).digest('hex');
}

module.exports = {
  DRIVE_DB_ENDPOINT,
  callDriveDb,
  encodeSessionToken,
  decodeSessionToken,
  sha256Hex,
};
