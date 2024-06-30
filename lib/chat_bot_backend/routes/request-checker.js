const express = require('express');
const { checkRequest } = require('../controllers/request-checker.js');

const router = express.Router();

router.post('/echo/:param', checkRequest);

module.exports= router;