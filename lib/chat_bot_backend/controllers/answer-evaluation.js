const { GoogleGenerativeAI } = require("@google/generative-ai");
const GEMINI_API_KEY = "AIzaSyD2dx6j8qsU9qEeikO9duNrIU9644dlqBw";
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);


const generateByGemini = async (prompt) => {
  try {
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash-latest" });
    const result = await model.generateContent([prompt]);
    return result.response.text();
}catch (error) {
    console.error('Error generating content:', error);
    throw error;
  }
}

const getAnswerPrompt = (actualAnswer, question, answer) => {
  actualAnswer = actualAnswer.replace(/['"\n]/g, "");
  return `You are assisting a medical student in preparing for an exam. The student has answered a QUESTION and want to check if the ANSWER is correct\
  As an assistant your job is to examine the ANSWER and provide a feedback. You are given the QUESTION and the student's ANSWER to that QUESTION. Also, the Actual Answer of that question is given.\
  Now evaluate the student's answer and compare it with the correct answer given below. Give a detailed feedback in first person under 100 words. BE STRICT about the evaluation and criticise the given answer properly. Generate normal text. No need to make the text bold.If the answer is incorrect\
  also provide the correct answer. \
  QUESTION: '${question}'
  Correct Answer: '${actualAnswer}'
  STUDENT'S ANSWER: '${answer}'
  YOUR FEEDBACK: `;
};

const getAnswerResponse = async (req, res) => {
    const { actual_answer: actualAnswer, student_answer: studentAnswer, question } = req.body;

    if (!actualAnswer || !studentAnswer || !question) {
      return res.status(400).json({ error: 'Missing one or more required fields' });
    }
  
    try {
      const prompt = getAnswerPrompt(actualAnswer, question, studentAnswer);
      const feedback = await generateByGemini(prompt);
      console.log(feedback);
      res.status(200).json({ response: `Received: ${req.body.message || ''}`, feedback: feedback });
    } catch (error) {
      res.status(500).json({ error: 'Internal server error' });
    }
}

module.exports = {getAnswerResponse};

