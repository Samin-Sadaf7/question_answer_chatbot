const express = require('express');
const { echoParam } = require('../controllers/request-checker.js');

const router = express.Router();

router.post('/echo/:param', echoParam);