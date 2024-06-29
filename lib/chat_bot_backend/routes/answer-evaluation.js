const express = require('express');
const { getAnswerResponse} = require('../controllers/answer-evaluation.js');

const router = express.Router();

router.post('/response', getAnswerResponse);