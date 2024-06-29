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
      title: 'ChatBot',
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
  bool _answered = false; // Track if the current question is answered
  bool _loading = false; // Track global loading state
  TextEditingController _answerController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  List<dynamic> _questions = [];
  List<Map<String, String>> _chatMessages = [];
  bool _showNextButton = false;
  int? _loadingMessageIndex; // Track specific message index being loaded
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
    print("Fetching questions...");
    final response =
        await http.get(Uri.parse('http://192.168.20.183:5500/lib/data.json'));
    print(response);
    if (response.statusCode == 200) {
      setState(() {
        _questions = json.decode(response.body)['Questions'];
        _chatMessages.add({
          'no': '${_currentQuestionIndex + 1}',
          'type': 'question',
          'sender': 'bot',
          'message': _questions[_currentQuestionIndex]['Question']
        });
      });
      _scrollToBottom();
    } else {
      throw Exception('Failed to load questions');
    }
  }

  Future<void> _checkAnswer(String userAnswer, String correctAnswer) async {
    setState(() {
      _loading = true; // Show global loading indicator
      _loadingMessageIndex = _chatMessages.length;
      _chatMessages
          .add({'type': 'loading', 'sender': 'bot', 'message': 'loading'});
    });

    bool isCorrect = await _sendAnswerToBackend(userAnswer, correctAnswer);

    setState(() {
      _answered = true; // Mark the question as answered
      _showHint = false;
      _showNextButton = true; // Show next button after feedback
      _loading = false; // Hide global loading indicator
      _loadingMessageIndex = null; // Reset loading message index
    });
    _scrollToBottom();
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
          _chatMessages[_loadingMessageIndex!] = {
            'type': 'feedback',
            'sender': 'bot',
            'message': feedback
          };
        });
        return true;
      } else {
        print('Failed to get response from server: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Exception while sending answer to backend: $e');
      return false;
    }
  }

  void _showNextQuestion() {
    setState(() {
      _currentQuestionIndex = (_currentQuestionIndex + 1) % _questions.length;
      _chatMessages.add({
        'no': '${_currentQuestionIndex + 1}',
        'type': 'question',
        'sender': 'bot',
        'message': _questions[_currentQuestionIndex]['Question']
      });
      _answered = false; // Reset the answered state for the new question
      _showNextButton = false; // Hide next button for the new question
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      // listenFor: Duration(seconds: 10),
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
      _answerController.text =
          _lastWords; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ChatBot'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(8.0),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                final isUser = message['sender'] == 'user';
                final isLoading = _loading && index == _loadingMessageIndex;

                return Column(
                  children: [
                    Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5.0),
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(),
                              )
                            : message['type'] != 'question'
                                ? Text(
                                    message['message']!,
                                    style: const TextStyle(fontSize: 16.0),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Question ${message['no']}:\n',
                                          style: const TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                        message['message']!,
                                        style: const TextStyle(fontSize: 16.0),
                                      )
                                    ],
                                  ),
                      ),
                    ),
                    // if (index < _chatMessages.length - 1)
                    //   Divider(color: Colors.grey),
                  ],
                );
              },
            ),
          ),
          if (_showNextButton)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _showNextQuestion,
                child: Text('Next'),
              ),
            ),
          if (_showHint)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _questions[_currentQuestionIndex]['Hint'],
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      TextField(
                        controller: _answerController,
                        decoration: InputDecoration(
                          hintText: 'Type your answer here...',
                          border: OutlineInputBorder(),
                        ),
                        enabled: !_answered && !_speechToText.isListening,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: _speechToText.isNotListening
                              ? Icon(Icons.mic_off)
                              : Icon(Icons.mic),
                          onPressed: () {
                            print("aaaaaaaaaaaaaaa");
                            if (_speechToText.isListening) {
                              _stopListening();
                            } else {
                              _startListening();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.help_outline),
                  onPressed: () {
                    setState(() {
                      _showHint = !_showHint;
                    });
                    _scrollToBottom();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _answered
                      ? null
                      : () {
                          setState(() {
                            _chatMessages.add({
                              'type': 'answer',
                              'sender': 'user',
                              'message': _answerController.text,
                            });
                            _answerController.clear();
                          });
                          _checkAnswer(
                            _chatMessages.last['message']!,
                            _questions[_currentQuestionIndex]['Answer'],
                          );
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
