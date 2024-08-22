const express = require('express');
const multer = require('multer');
const SpeechToText = require('../controllers/speechToText'); 

const router = express.Router();


const upload = multer({ dest: 'uploads/' }); 

router.post('/transcribe', upload.single('audio'), SpeechToText);

module.exports = router;
