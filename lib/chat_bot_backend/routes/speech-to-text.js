const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const SpeechToText = require('../controllers/speech-to-text.js'); 

const router = express.Router();

// Define storage settings for multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Specify the destination directory
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    // Specify the file name
    cb(null, Date.now() + path.extname(file.originalname));
  }
});

// Define file filter to accept only .mp3 files
const fileFilter = (req, file, cb) => {
  const allowedTypes = /mp3|mpeg/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  if (extname && mimetype) {
    return cb(null, true);
  } else {
    cb(new Error('Only .mp3 files are allowed'), false);
  }
};

// Initialize multer with storage and file filter settings
const upload = multer({
  storage: storage,
  fileFilter: fileFilter
});

router.post('/transcribe', upload.single('audio'), SpeechToText);

module.exports = router;
