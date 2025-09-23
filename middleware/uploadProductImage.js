const fs = require('fs');
const path = require('path');
const multer = require('multer');

const uploadRoot = path.join(__dirname, '..', 'uploads', 'products');

function ensureUploadPath() {
  fs.mkdirSync(uploadRoot, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    try {
      ensureUploadPath();
      cb(null, uploadRoot);
    } catch (e) {
      cb(e);
    }
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${ext}`);
  }
});

const allowedExtensions = new Set(['.jpg', '.jpeg', '.png']);

function fileFilter(_req, file, cb) {
  const ext = path.extname(file.originalname).toLowerCase();
  if (!allowedExtensions.has(ext)) {
    return cb(new Error('Formato de imagen no permitido (solo JPG o PNG)'));
  }
  cb(null, true);
}

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 },
});

function handleSingle(fieldName) {
  return (req, res, next) => {
    const middleware = upload.single(fieldName);
    middleware(req, res, (err) => {
      if (err) {
        const message = err.message || 'Error al subir la imagen';
        return res.status(400).json({ error: message });
      }
      next();
    });
  };
}

module.exports = {
  upload,
  handleSingle,
  uploadRoot,
};
