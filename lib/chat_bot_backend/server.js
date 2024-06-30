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

const url = "mongodb+srv://samin:sadaf@cluster0.jjvxsrh.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0";
const dbName = 'RAG_application';

let db;
MongoClient.connect(url, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(client => {
    console.log('Connected to Database');
    db = client.db(dbName);
  })
  .catch(error => console.error(error));
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}/`);
});
