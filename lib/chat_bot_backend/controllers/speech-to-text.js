const fs = require('fs');
const OpenAI = require('openai');
const dotenv = require('dotenv');

dotenv.config();

const openai = new OpenAI({
  apiKey: process.env.OPEN_AI_KEY // using the API key from .env file
});

const SpeechToText = async (req, res) => {
  try {
    const transcription = await openai.audio.transcriptions.create({
      file: fs.createReadStream(req.file.path), // path to the uploaded audio file
      model: "whisper-1",
      language: "de", 
    });

    res.status(200).json({
      success: true,
      transcription: transcription.data, 
    });
  } catch (error) {
    console.error("Error during transcription:", error);
    res.status(500).json({
      success: false,
      message: "Failed to transcribe audio",
      error: error.message,
    });
  }
};

module.exports = SpeechToText;
