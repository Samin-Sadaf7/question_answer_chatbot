const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const responseRoutes = require('./routes/request-checker.js');
const answerEvaluationRoutes = require('./routes/answer-evaluation.js');

const app = express();
const port = 8000;

app.use(bodyParser.json());
app.use(cors());

app.use('/', responseRoutes, answerEvaluationRoutes);

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}/`);
});
