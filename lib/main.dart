import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

void main() {
  runApp(ChatBotApp());
}

class ChatBotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viva ChatBot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatBotScreen(),
    );
  }
}

class ChatBotScreen extends StatefulWidget {
  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  int _currentQuestionIndex = 0;
  bool _showHint = false;
  bool _answered = false;
  bool _loading = false;
  TextEditingController _answerController = TextEditingController();
  List<dynamic> _questions = [];
  String _feedback = '';
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    _initSpeech();
  }

  Future<void> _fetchQuestions() async {
    final response =
        await http.get(Uri.parse('http://192.168.20.183:5500/lib/data.json'));
    if (response.statusCode == 200) {
      setState(() {
        _questions = json.decode(response.body)['Questions'];
      });
    } else {
      throw Exception('Failed to load questions');
    }
  }

  Future<void> _checkAnswer(String userAnswer, String correctAnswer) async {
    setState(() {
      _loading = true;
    });

    bool isCorrect = await _sendAnswerToBackend(userAnswer, correctAnswer);

    setState(() {
      _answered = true;
      _showHint = false;
      _loading = false;
    });
  }

  Future<bool> _sendAnswerToBackend(
      String userAnswer, String correctAnswer) async {
    Map<String, String> data = {
      'student_answer': userAnswer,
      'actual_answer': correctAnswer,
      'question': _questions[_currentQuestionIndex]['Question']
    };

    try {
      final response = await http.post(
        Uri.parse('http://192.168.20.183:8000/response/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        String feedback = responseData['feedback'] ?? "No feedback received";
        setState(() {
          _feedback = feedback;
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  void _showNextQuestion() {
    FocusScope.of(context).unfocus();
    setState(() {
      _currentQuestionIndex = (_currentQuestionIndex + 1) % _questions.length;
      _answered = false;
      _feedback = '';
      _answerController.clear();
    });
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: _onSpeechStatus,
    );
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      // onStatus: _onSpeechStatus,
    );
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _answerController.text = _lastWords;
    });
  }

  void _onSpeechStatus(String status) {
    if (status == 'notListening') {
      print("aaaaaaaaaaaa");
      setState(() {
        _answered = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 100,
              ),
              Column(
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1}',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Text(
                    _questions.isNotEmpty
                        ? _questions[_currentQuestionIndex]['Question']
                        : 'Loading question...',
                    style: TextStyle(fontSize: 18.0),
                    textAlign: TextAlign.center,
                  ),
                  if (!_answered)
                    Column(
                      children: [
                        const SizedBox(
                          height: 200,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Column(
                            children: [
                              if (_speechToText.isListening)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    _lastWords,
                                    style: TextStyle(fontSize: 16.0),
                                  ),
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 50,
                                  ),
                                  Container(
                                    width: 120.0,
                                    height: 120.0,
                                    decoration: BoxDecoration(
                                      color: Colors.amberAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      iconSize: 50.0,
                                      icon: Icon(
                                          _speechToText.isListening
                                              ? Icons.mic
                                              : Icons.mic_none_sharp,
                                          color: Colors.grey[700]),
                                      onPressed: () {
                                        if (_speechToText.isListening) {
                                          _stopListening();
                                        } else {
                                          _startListening();
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 20.0),
                                  Transform.translate(
                                    offset: Offset(0, -50),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.amberAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                            _showHint
                                                ? Icons.lightbulb
                                                : Icons.lightbulb_outline,
                                            color: Colors.grey[700]),
                                        onPressed: () {
                                          setState(() {
                                            _showHint = !_showHint;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (_answered && _feedback.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                _answerController.text,
                                style: TextStyle(
                                    fontSize: 16.0, color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 236, 194, 208),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Text(
                                _feedback,
                                style: TextStyle(
                                    fontSize: 16.0, color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                ],
              ),
              if (_answered && _feedback == '')
                Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 236, 181, 200),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin:
                            const EdgeInsets.only(right: 5, left: 5, top: 18),
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: TextField(
                          controller: _answerController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                          ),
                          enabled: _answered,
                        ),
                      ),
                      SizedBox(height: 15.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                          ),
                          Container(
                            width: 50.0,
                            height: 50.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              iconSize: 30.0,
                              icon: Icon(
                                  _speechToText.isListening
                                      ? Icons.mic
                                      : Icons.mic_none_sharp,
                                  color: Colors.grey[700]),
                              onPressed: () {
                                if (_speechToText.isListening) {
                                  _stopListening();
                                } else {
                                  _startListening();
                                }
                              },
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.send),
                            onPressed: !_answered
                                ? null
                                : () {
                                    setState(() {
                                      _answered = true;
                                    });
                                    _checkAnswer(
                                      _answerController.text,
                                      _questions[_currentQuestionIndex]
                                          ['Answer'],
                                    );
                                  },
                          ),
                        ],
                      ),
                      SizedBox(height: 15.0),
                    ],
                  ),
                ),
              if (_feedback != '')
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: ElevatedButton(
                    onPressed: _showNextQuestion,
                    child: Text('Next'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
