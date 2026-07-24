const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const path = require('path');

// Load env vars
dotenv.config();

// Connect to Database
connectDB();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', (req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  next();
}, express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/documents', require('./routes/documentRoutes'));
app.use('/api/workflow', require('./routes/workflowRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/departments', require('./routes/departmentRoutes'));
app.use('/api/duty-categories', require('./routes/dutyCategoryRoutes'));
app.use('/api/feedback', require('./routes/feedbackRoutes'));

// Basic route
app.get('/', (req, res) => {
  res.send('AntiGravity API is running...');
});

// ── Public Document Verification Page ─────────────────────────────────────
app.get('/verify/:id', async (req, res) => {
  try {
    const Document = require('./models/Document');
    const doc = await Document.findById(req.params.id)
      .populate('studentId', 'name registerNo dept year division');

    if (!doc) {
      return res.status(404).send(`<!DOCTYPE html><html><head><title>Not Found</title>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>body{font-family:sans-serif;background:#0f0f1a;color:#fff;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;padding:20px;box-sizing:border-box;}
        .card{background:#1a1a2e;border-radius:16px;padding:32px;max-width:480px;width:100%;text-align:center;border:1px solid #333;}
        h2{color:#ef4444;} p{color:#aaa;}</style></head>
        <body><div class="card"><h2>⚠️ Invalid QR Code</h2><p>This document could not be found or the QR code is invalid.</p></div></body></html>`);
    }

    const approvalChain = doc.approvals
      .filter(a => !((a.comment || '').includes('Duty Leave Marked')))
      .map(a => ({
        name: a.approverId && typeof a.approverId === 'object' ? a.approverId['name'] || 'Staff' : 'Staff',
        role: (a.role || '').toUpperCase(),
        action: a.action,
      }));

    const isApproved = doc.status === 'final_approved';
    const studentName = doc.studentId && typeof doc.studentId === 'object' ? doc.studentId['name'] || '—' : '—';
    const studentReg  = doc.studentId && typeof doc.studentId === 'object' ? doc.studentId['registerNo'] || '—' : '—';
    const studentDept = doc.studentId && typeof doc.studentId === 'object' ? doc.studentId['dept'] || '—' : '—';
    const dateStr = doc.createdAt ? new Date(doc.createdAt).toLocaleDateString('en-IN', { day:'2-digit', month:'long', year:'numeric' }) : '—';

    const statusColor  = isApproved ? '#22c55e' : doc.status === 'rejected' ? '#ef4444' : '#f59e0b';
    const statusLabel  = isApproved ? '✅ VERIFIED & APPROVED' : doc.status === 'rejected' ? '❌ REJECTED' : '⏳ PENDING';
    const statusBg     = isApproved ? '#14532d22' : doc.status === 'rejected' ? '#7f1d1d22' : '#78350f22';

    const chainRows = approvalChain.map((a, i) => `
      <div style="display:flex;align-items:center;gap:12px;padding:10px 0;border-bottom:1px solid #2a2a3e;">
        <div style="width:32px;height:32px;border-radius:50%;background:${a.action==='approved'?'#22c55e22':'#ef444422'};border:1.5px solid ${a.action==='approved'?'#22c55e':'#ef4444'};display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0;">${a.action==='approved'?'✓':'✗'}</div>
        <div>
          <div style="font-weight:600;color:#e2e2f0;font-size:13px;">${a.name}</div>
          <div style="color:#8888aa;font-size:11px;">${a.role}</div>
        </div>
        <div style="margin-left:auto;color:${a.action==='approved'?'#22c55e':'#ef4444'};font-size:11px;font-weight:600;">${a.action.toUpperCase()}</div>
      </div>`).join('');

    res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Document Verification — DocTransit</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#0a0a14;color:#e2e2f0;min-height:100vh;padding:20px;}
    .wrap{max-width:520px;margin:0 auto;padding-top:20px;}
    .header{text-align:center;margin-bottom:24px;}
    .logo{font-size:28px;font-weight:900;background:linear-gradient(135deg,#7c3aed,#4f46e5);-webkit-background-clip:text;-webkit-text-fill-color:transparent;letter-spacing:-1px;}
    .sub{color:#6666aa;font-size:12px;margin-top:4px;}
    .status-banner{padding:16px 20px;border-radius:12px;background:${statusBg};border:1.5px solid ${statusColor};text-align:center;margin-bottom:20px;}
    .status-text{color:${statusColor};font-size:16px;font-weight:700;letter-spacing:.5px;}
    .card{background:#12121e;border:1px solid #2a2a3e;border-radius:16px;padding:20px;margin-bottom:16px;}
    .card-title{color:#7c3aed;font-size:10px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;margin-bottom:14px;}
    .row{display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid #1e1e30;}
    .row:last-child{border-bottom:none;}
    .lbl{color:#8888aa;font-size:12px;}
    .val{color:#e2e2f0;font-size:13px;font-weight:600;text-align:right;max-width:60%;}
    .doc-id{font-size:9px;color:#555;text-align:center;margin-top:12px;word-break:break-all;}
    .footer{text-align:center;color:#444;font-size:11px;margin-top:24px;padding-bottom:24px;}
  </style>
</head>
<body>
  <div class="wrap">
    <div class="header">
      <div class="logo">DocTransit</div>
      <div class="sub">SIMAT Secure Document Verification</div>
    </div>

    <div class="status-banner">
      <div class="status-text">${statusLabel}</div>
    </div>

    <div class="card">
      <div class="card-title">Document Details</div>
      <div class="row"><span class="lbl">Document</span><span class="val">${doc.title}</span></div>
      <div class="row"><span class="lbl">Category</span><span class="val">${doc.flow || doc.category}</span></div>
      <div class="row"><span class="lbl">Date Submitted</span><span class="val">${dateStr}</span></div>
    </div>

    <div class="card">
      <div class="card-title">Student Details</div>
      <div class="row"><span class="lbl">Name</span><span class="val">${studentName}</span></div>
      <div class="row"><span class="lbl">Register No.</span><span class="val">${studentReg}</span></div>
      <div class="row"><span class="lbl">Department</span><span class="val">${studentDept}</span></div>
    </div>

    <div class="card">
      <div class="card-title">Approval Chain (${approvalChain.length} step${approvalChain.length!==1?'s':''})</div>
      ${chainRows || '<div style="color:#555;font-size:12px;text-align:center;padding:12px">No approvals yet</div>'}
    </div>

    <div class="doc-id">Document ID: ${doc._id}</div>
    <div class="footer">Verified by DocTransit · SREEPATHY INSTITUTE OF MANAGEMENT AND TECHNOLOGY</div>
  </div>
</body>
</html>`);
  } catch (e) {
    res.status(500).send('<h2>Server error during verification</h2>');
  }
});


// Error Handling Middlewares
app.use((req, res, next) => {
  res.status(404).json({ message: `Route not found - ${req.originalUrl}` });
});

app.use((err, req, res, next) => {
  const statusCode = res.statusCode === 200 ? 500 : res.statusCode;
  console.error('SERVER ERROR:', err.stack);
  res.status(statusCode).json({
    message: err.message,
    stack: process.env.NODE_ENV === 'production' ? null : err.stack,
  });
});

const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0';

app.listen(PORT, HOST, () => {
  console.log(`Server running on ${HOST}:${PORT}`);
});
