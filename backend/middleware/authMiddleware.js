const User = require('../models/User');
const { decodeSessionToken } = require('../config/driveDb');

const protect = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = decodeSessionToken(token);

      if (!decoded) {
        return res.status(401).json({ message: 'Not authorized, token failed' });
      }

      const decodedUser = decoded.user && typeof decoded.user === 'object' ? decoded.user : decoded;
      const userId = decodedUser._id || decodedUser.id || decodedUser.userId;
      const email = decodedUser.email;

      let user = null;
      if (userId) user = await User.findById(userId);
      if (!user && email) user = await User.findOne({ email: String(email).toLowerCase().trim() });

      if (!user) {
        return res.status(401).json({ message: 'Not authorized, user not found' });
      }

      user.id = user._id;
      req.user = user;
      next();
      return;
    } catch (error) {
      console.error('Auth error:', error);
      return res.status(401).json({ message: 'Not authorized, token failed' });
    }
  }

  if (!token) {
    return res.status(401).json({ message: 'Not authorized, no token' });
  }
};

const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ message: `Role ${req.user ? req.user.role : 'none'} is not allowed to access this resource` });
    }
    next();
  };
};

module.exports = { protect, authorizeRoles };
