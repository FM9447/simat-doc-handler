const express = require('express');
const router = express.Router();
const Document = require('../models/Document');

function buildHtml(data) {
  const {
    verified, title, category, dateStr,
    studentName, studentReg, studentDept,
    statusColor, statusBg, statusLabel,
    approvalChain, docId
  } = data;

  const chainRows = approvalChain.map(function(a) {
    var bgColor = a.action === 'approved' ? '#22c55e22' : '#ef444422';
    var borderColor = a.action === 'approved' ? '#22c55e' : '#ef4444';
    var icon = a.action === 'approved' ? '&#10003;' : '&#10007;';
    var actionColor = a.action === 'approved' ? '#22c55e' : '#ef4444';
    return '<div style="display:flex;align-items:center;gap:12px;padding:10px 0;border-bottom:1px solid #2a2a3e;">' +
      '<div style="width:32px;height:32px;border-radius:50%;background:' + bgColor + ';border:1.5px solid ' + borderColor + ';display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0;">' + icon + '</div>' +
      '<div><div style="font-weight:600;color:#e2e2f0;font-size:13px;">' + a.name + '</div>' +
      '<div style="color:#8888aa;font-size:11px;">' + a.role + '</div></div>' +
      '<div style="margin-left:auto;color:' + actionColor + ';font-size:11px;font-weight:600;">' + a.action.toUpperCase() + '</div>' +
      '</div>';
  }).join('');

  var noApprovals = '<div style="color:#555;font-size:12px;text-align:center;padding:12px">No approvals yet</div>';
  var steps = approvalChain.length;
  var stepsLabel = steps + ' step' + (steps !== 1 ? 's' : '');

  return '<!DOCTYPE html><html lang="en"><head>' +
    '<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">' +
    '<title>Document Verification - DocTransit</title>' +
    '<style>' +
    '*{box-sizing:border-box;margin:0;padding:0}' +
    'body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#0a0a14;color:#e2e2f0;min-height:100vh;padding:20px;}' +
    '.wrap{max-width:520px;margin:0 auto;padding-top:20px;}' +
    '.header{text-align:center;margin-bottom:24px;}' +
    '.logo{font-size:28px;font-weight:900;background:linear-gradient(135deg,#7c3aed,#4f46e5);-webkit-background-clip:text;-webkit-text-fill-color:transparent;letter-spacing:-1px;}' +
    '.sub{color:#6666aa;font-size:12px;margin-top:4px;}' +
    '.status-banner{padding:16px 20px;border-radius:12px;background:' + statusBg + ';border:1.5px solid ' + statusColor + ';text-align:center;margin-bottom:20px;}' +
    '.status-text{color:' + statusColor + ';font-size:16px;font-weight:700;letter-spacing:.5px;}' +
    '.card{background:#12121e;border:1px solid #2a2a3e;border-radius:16px;padding:20px;margin-bottom:16px;}' +
    '.card-title{color:#7c3aed;font-size:10px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;margin-bottom:14px;}' +
    '.row{display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid #1e1e30;}' +
    '.row:last-child{border-bottom:none;}' +
    '.lbl{color:#8888aa;font-size:12px;}' +
    '.val{color:#e2e2f0;font-size:13px;font-weight:600;text-align:right;max-width:60%;}' +
    '.doc-id{font-size:9px;color:#555;text-align:center;margin-top:12px;word-break:break-all;}' +
    '.footer{text-align:center;color:#444;font-size:11px;margin-top:24px;padding-bottom:24px;}' +
    '</style></head><body>' +
    '<div class="wrap">' +
    '<div class="header"><div class="logo">DocTransit</div><div class="sub">SIMAT Secure Document Verification</div></div>' +
    '<div class="status-banner"><div class="status-text">' + statusLabel + '</div></div>' +
    '<div class="card"><div class="card-title">Document Details</div>' +
    '<div class="row"><span class="lbl">Document</span><span class="val">' + title + '</span></div>' +
    '<div class="row"><span class="lbl">Category</span><span class="val">' + category + '</span></div>' +
    '<div class="row"><span class="lbl">Date Submitted</span><span class="val">' + dateStr + '</span></div>' +
    '</div>' +
    '<div class="card"><div class="card-title">Student Details</div>' +
    '<div class="row"><span class="lbl">Name</span><span class="val">' + studentName + '</span></div>' +
    '<div class="row"><span class="lbl">Register No.</span><span class="val">' + studentReg + '</span></div>' +
    '<div class="row"><span class="lbl">Department</span><span class="val">' + studentDept + '</span></div>' +
    '</div>' +
    '<div class="card"><div class="card-title">Approval Chain (' + stepsLabel + ')</div>' +
    (chainRows || noApprovals) +
    '</div>' +
    '<div class="footer">Verified by DocTransit &middot; SREEPATHY INSTITUTE OF MANAGEMENT AND TECHNOLOGY</div>' +
    '</div></body></html>';
}

// @route   GET /verify/:id
// @access  Public
router.get('/:id', async function(req, res) {
  try {
    var doc = await Document.findById(req.params.id)
      .populate('studentId', 'name registerNo dept year division');

    if (!doc) {
      return res.status(404).send(
        '<!DOCTYPE html><html><head><title>Not Found</title>' +
        '<meta name="viewport" content="width=device-width,initial-scale=1">' +
        '<style>body{font-family:sans-serif;background:#0f0f1a;color:#fff;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;padding:20px;}' +
        '.card{background:#1a1a2e;border-radius:16px;padding:32px;max-width:480px;width:100%;text-align:center;border:1px solid #333;}' +
        'h2{color:#ef4444;}p{color:#aaa;}</style></head>' +
        '<body><div class="card"><h2>Invalid QR Code</h2><p>This document could not be found or the QR code is invalid.</p></div></body></html>'
      );
    }

    var approvalChain = doc.approvals
      .filter(function(a) { return !((a.comment || '').includes('Duty Leave Marked')); })
      .map(function(a) {
        return {
          name: (a.approverId && typeof a.approverId === 'object') ? (a.approverId['name'] || 'Staff') : 'Staff',
          role: (a.role || '').toUpperCase(),
          action: a.action,
        };
      });

    var isApproved = doc.status === 'final_approved';
    var isRejected = doc.status === 'rejected';
    var studentName = (doc.studentId && typeof doc.studentId === 'object') ? (doc.studentId['name'] || '-') : '-';
    var studentReg  = (doc.studentId && typeof doc.studentId === 'object') ? (doc.studentId['registerNo'] || '-') : '-';
    var studentDept = (doc.studentId && typeof doc.studentId === 'object') ? (doc.studentId['dept'] || '-') : '-';
    var dateStr = doc.createdAt
      ? new Date(doc.createdAt).toLocaleDateString('en-IN', { day: '2-digit', month: 'long', year: 'numeric' })
      : '-';

    var statusColor = isApproved ? '#22c55e' : (isRejected ? '#ef4444' : '#f59e0b');
    var statusLabel = isApproved ? 'VERIFIED & APPROVED' : (isRejected ? 'REJECTED' : 'PENDING');
    var statusBg    = isApproved ? '#14532d22' : (isRejected ? '#7f1d1d22' : '#78350f22');

    res.send(buildHtml({
      verified: isApproved,
      title: doc.title,
      category: doc.flow || doc.category || '-',
      dateStr: dateStr,
      studentName: studentName,
      studentReg: studentReg,
      studentDept: studentDept,
      statusColor: statusColor,
      statusBg: statusBg,
      statusLabel: statusLabel,
      approvalChain: approvalChain,
      docId: doc._id.toString(),
    }));
  } catch (e) {
    console.error('Verify route error:', e);
    res.status(500).send('<h2>Server error during verification</h2>');
  }
});

module.exports = router;
