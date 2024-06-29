const express = require('express');
const { getAnswerResponse} = require('../controllers/responseController');

const router = express.Router();

router.post('/response', getAnswerResponse);