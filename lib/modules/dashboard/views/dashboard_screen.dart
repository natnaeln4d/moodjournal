import 'dart:io';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:job5/data/models/mood_model.dart';
import 'package:job5/modules/journal/views/journal_list_screen.dart';
import '../../../constants.dart';
import '../../../core/bindings/theme_controller.dart';
import '../../../data/models/dashboard/controllers/mood_controller.dart';
import 'package:job5/core/services/auth_service.dart';
import 'package:job5/data/models/chat_message.dart';
import 'package:job5/data/models/journal/controllers/journal_controller.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late MoodController _moodController;
  late JournalController _journalController;
  late ThemeController _themeController;
  late ConfettiController _confettiController;
  TextEditingController? _moodNoteController;
  final AuthService _authService = Get.find<AuthService>();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _chatScrollController = ScrollController();
  final AppConstants _appConstants = AppConstants();
  CameraController? _cameraController;
  bool _isCameraActive = false;
  bool _isDetectingEmotion = false;
  String _detectedEmotion = '';
  bool _isGeneratingResponse = false;
  bool _showMoodSelector = false;

  late GenerativeModel _model;

  final RxList<ChatMessage> _chatMessages = <ChatMessage>[].obs;

  @override
  void initState() {
    super.initState();
    _moodController = Get.find<MoodController>();
    _journalController = Get.find<JournalController>();
    _themeController = Get.find<ThemeController>();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _moodNoteController = TextEditingController();

    _initializeGemini();

    _chatMessages.add(ChatMessage(
      text: "Hi! I'm Gemini, your mental health assistant. How are you feeling today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));

    _initializeCamera();
  }

  void _initializeGemini() {
    var apiKey = AppConstants.geminiApiKey;
    if (apiKey.isEmpty) {
      print('Warning: Gemini API key not found. Please set GEMINI_API_KEY environment variable.');
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.9,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    }
  }

  Future<void> _detectEmotion() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isDetectingEmotion = true;
    });

    try {

      await Future.delayed(const Duration(seconds: 2));


      final emotions = ['Happy', 'Sad', 'Neutral', 'Anxious', 'Excited'];
      final randomEmotion = emotions[DateTime.now().millisecond % emotions.length];

      setState(() {
        _detectedEmotion = randomEmotion;
        _isDetectingEmotion = false;
      });

      // Add emotion detection result to chat
      _addAssistantMessage("I detected that you're feeling $randomEmotion. Would you like to talk about it?");

    } catch (e) {
      setState(() {
        _isDetectingEmotion = false;
      });
    }
  }

  Future<void> _generateGeminiResponse(String userMessage) async {
    setState(() {
      _isGeneratingResponse = true;
    });

    try {
      final prompt = "You are a compassionate mental health assistant for a mood journaling app. "
          "The user is tracking their emotions and journaling their thoughts. "
          "Respond supportively, ask thoughtful questions to encourage reflection, "
          "but avoid giving medical advice. Be concise but empathetic.\n\n"
          "User: $userMessage\n\nAssistant:";
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        _addAssistantMessage(response.text!);
        if (_shouldSuggestJournalSave(response.text!)) {
          _suggestJournalEntryFromChat(response.text!, userMessage);
        }
      } else {
        _addAssistantMessage("I'm sorry, I couldn't generate a response. Please try again.");
      }
    } catch (e) {
      print('Error generating Gemini response: $e');
      _addAssistantMessage("I'm having trouble connecting right now. Please check your internet connection and try again.");
    } finally {
      setState(() {
        _isGeneratingResponse = false;
      });
    }
  }
  bool _shouldSuggestJournalSave(String response) {

    final triggers = [
      'write about', 'reflect on', 'consider', 'think about',
      'journal about', 'explore', 'describe', 'remember'
    ];
    return triggers.any((trigger) => response.toLowerCase().contains(trigger));
  }

  void _suggestJournalEntryFromChat(String assistantResponse, String userMessage) {
    Future.delayed(const Duration(seconds: 2), () {
      _addAssistantMessage("📝 Would you like to save this as a journal entry? "
          "You can use the 'Add Journal' button below to preserve these reflections. "
          "I can help you expand on these thoughts too!");
    });
  }

  void _createJournalFromChat(String title, String content) {
    _journalController.addJournal(title, content);
    _journalController.reloadJournals();

    Get.snackbar(
      'Journal Created',
      'Your reflections have been saved successfully!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
  void _addAssistantMessage(String text) {
    _chatMessages.add(ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    _scrollChatToBottom();
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
  void _showJournalDialogWithChatContext() {
    TextEditingController titleController = TextEditingController();
    TextEditingController contentController = TextEditingController();

    // Get the last assistant message to pre-fill the journal content
    final lastAssistantMessage = _chatMessages.isNotEmpty
        ? _chatMessages.lastWhere(
            (msg) => !msg.isUser,
        orElse: () => ChatMessage(text: "", isUser: false, timestamp: DateTime.now())
    )
        : ChatMessage(text: "", isUser: false, timestamp: DateTime.now());

    // Pre-fill with the last assistant message if it exists
    if (lastAssistantMessage.text.isNotEmpty) {
      contentController.text = "Reflecting on our conversation:\n\n";
      contentController.text += "Assistant: ${lastAssistantMessage.text}\n\n";
      contentController.text += "My thoughts: ";

      // Also suggest a title based on the assistant's message
      titleController.text = _generateTitleFromMessage(lastAssistantMessage.text);
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Create Journal Entry',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: 'Title',
                      labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: 'Content',
                      labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple, width: 2),
                      ),
                    ),
                    maxLines: 8,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isEmpty || contentController.text.isEmpty) {
                            Get.snackbar(
                              'Error',
                              'Please fill all fields',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          _journalController.addJournal(
                            titleController.text,
                            contentController.text,
                          );
                          _journalController.reloadJournals();

                          Get.back();
                          Get.snackbar(
                            'Success',
                            'Journal entry created!',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                        child: const Text('Create', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  String _generateTitleFromMessage(String message) {

    if (message.toLowerCase().contains('gratitude')) {
      return "Gratitude Reflection";
    } else if (message.toLowerCase().contains('mood') || message.toLowerCase().contains('feeling')) {
      return "Mood Exploration";
    } else if (message.toLowerCase().contains('prompt') || message.toLowerCase().contains('write about')) {
      final promptMatch = RegExp(r'write about (.*?)(\.|\?|$)').firstMatch(message.toLowerCase());
      if (promptMatch != null && promptMatch.group(1) != null) {
        final topic = promptMatch.group(1)!;
        return "${topic[0].toUpperCase()}${topic.substring(1)} Reflection";
      }
      return "Writing Reflection";
    } else if (message.toLowerCase().contains('reflect') || message.toLowerCase().contains('think about')) {
      return "Personal Reflection";
    } else if (message.toLowerCase().contains('exercise') || message.toLowerCase().contains('breathing')) {
      return "Wellness Exercise";
    }

    // Default title based on first few words
    final words = message.split(' ');
    if (words.length > 3) {
      return "${words[0]} ${words[1]} ${words[2]}...";
    }

    return "Journal Entry";
  }
  void _showAddJournalDialog() {
    TextEditingController titleController = TextEditingController();
    TextEditingController contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add Journal Entry',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: 'Title',
                      labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: 'Content',
                      labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple, width: 2),
                      ),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isEmpty || contentController.text.isEmpty) {
                            Get.snackbar(
                              'Error',
                              'Please fill all fields',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          _journalController.addJournal(
                            titleController.text,
                            contentController.text,
                          );
                          _journalController.reloadJournals();

                          Get.back();
                          Get.snackbar(
                            'Success',
                            'Journal entry added',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                        child: const Text('Add', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddMoodDialog() {
    TextEditingController noteController = TextEditingController();
    String selectedMood = 'neutral';
    bool _isDetectingInDialog = false;
    String _detectedEmotionInDialog = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'How are you feeling?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Camera detection section
                      if (_isDetectingInDialog)
                        Column(
                          children: [
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.purple),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _cameraController != null && _cameraController!.value.isInitialized
                                    ? CameraPreview(_cameraController!)
                                    : Center(child: Text('Camera not available', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color))),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_isDetectingEmotion)
                              const CircularProgressIndicator()
                            else if (_detectedEmotionInDialog.isNotEmpty)
                              Text(
                                'Detected emotion: $_detectedEmotionInDialog',
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Mood selection - Expanded to include more options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMoodOption('Happy', Icons.sentiment_very_satisfied, Colors.green, selectedMood, (value) {
                            setState(() {
                              selectedMood = value;
                            });
                          }),
                          _buildMoodOption('Neutral', Icons.sentiment_neutral, Colors.amber, selectedMood, (value) {
                            setState(() {
                              selectedMood = value;
                            });
                          }),
                          _buildMoodOption('Sad', Icons.sentiment_very_dissatisfied, Colors.blue, selectedMood, (value) {
                            setState(() {
                              selectedMood = value;
                            });
                          }),
                          _buildMoodOption('Anxious', Icons.sentiment_very_dissatisfied, Colors.orange, selectedMood, (value) {
                            setState(() {
                              selectedMood = value;
                            });
                          }),
                          _buildMoodOption('Excited', Icons.sentiment_very_satisfied, Colors.purple, selectedMood, (value) {
                            setState(() {
                              selectedMood = value;
                            });
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Camera detection button
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (_cameraController == null || !_cameraController!.value.isInitialized) {
                            Get.snackbar('Error', 'Camera not available');
                            return;
                          }

                          setState(() {
                            _isDetectingInDialog = true;
                            _isDetectingEmotion = true;
                          });

                          // Simulate emotion detection (replace with actual ML model)
                          await Future.delayed(const Duration(seconds: 2));

                          // Map detected emotions to mood options
                          final emotionToMood = {
                            'Happy': 'happy',
                            'Sad': 'sad',
                            'Neutral': 'neutral',
                            'Anxious': 'anxious',
                            'Excited': 'excited',
                          };

                          final emotions = ['Happy', 'Sad', 'Neutral', 'Anxious', 'Excited'];
                          final randomEmotion = emotions[DateTime.now().millisecond % emotions.length];

                          setState(() {
                            _detectedEmotionInDialog = randomEmotion;
                            _isDetectingEmotion = false;
                            selectedMood = emotionToMood[randomEmotion] ?? 'neutral';
                          });
                        },
                        icon: Icon(Icons.camera_alt, color: Colors.white),
                        label: Text('Detect Emotion from Camera', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: noteController,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelText: 'Optional note',
                          labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _moodController.addMoodEntry(selectedMood.toLowerCase(), note: noteController.text.isNotEmpty ? noteController.text : null);
                              Get.back();
                              _moodController.reloadMoods();
                              Get.snackbar(
                                'Success',
                                'Mood logged successfully!',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                            ),
                            child: const Text('Add Mood', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMoodOption(String label, IconData icon, Color color, String selectedMood, Function(String) onSelect) {
    final isSelected = selectedMood == label.toLowerCase();
    return GestureDetector(
      onTap: () => onSelect(label.toLowerCase()),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12, // Smaller font to fit more options
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _moodNoteController?.dispose();
    _scrollController.dispose();
    _chatScrollController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.book, color: Colors.purple),
            onPressed: () => Get.to(() => JournalListScreen()),
          ),
          IconButton(
            icon: Obx(() => Icon(
              _themeController.themeMode.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.purple,
            )),
            onPressed: () => _themeController.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.purple),
            onPressed: () {
              _authService.signOut();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [const Color(0xFF1E1E2C), const Color(0xFF2D2E40)]
                    : [Colors.white, Colors.grey.shade200],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildUserStats(),
                    _buildMoodEntryButton(),
                    _buildAssistantSection(),
                    _buildTodaysMoodChart(),
                    _buildRecentJournals(),
                    _buildRecentMoods(),

                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodEntryButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: _showAddMoodDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_emotions, color: Colors.white),
            const SizedBox(width: 8),
            Text('Log Your Mood', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 30,
            child: Scrollbar(
              controller: _scrollController,
              child: ListView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                children: [
                  Text(
                    'Hi there! ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Obx(() => Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '${_moodController.streakCount.value}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text('Day Streak'),
            ],
          ),
          Column(
            children: [
              Text(
                '${_moodController.totalEntries.value}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text('Total Entries'),
            ],
          ),
          const Column(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber,size: 34,),
              Text('Achievements'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0));
  }

  Widget _buildAssistantSection() {
    return _buildGlassContainer(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_alt, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    'Gemini Assistant',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isCameraActive ? Icons.camera_alt_outlined : Icons.camera_alt,
                      color: Colors.purple,
                    ),
                    onPressed: () {
                      setState(() {
                        _isCameraActive = !_isCameraActive;
                        if (_isCameraActive) {
                          _detectEmotion();
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),


              if (_isCameraActive && _cameraController != null && _cameraController!.value.isInitialized)
                Column(
                  children: [
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isDetectingEmotion)
                      const CircularProgressIndicator()
                    else if (_detectedEmotion.isNotEmpty)
                      Text(
                        'Detected emotion: $_detectedEmotion',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Chat conversation
              Expanded(
                child: Obx(() => ListView.builder(
                  controller: _chatScrollController,
                  shrinkWrap: true,
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = _chatMessages[index];
                    return _buildChatBubble(message);
                  },
                )),
              ),

              if (_isGeneratingResponse)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      SizedBox(width: 32),
                      Text('Gemini is thinking...', style: TextStyle(color: Colors.purple)),
                      SizedBox(width: 8),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              // Replace your current Row with the text field and button with this:
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _moodNoteController,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: 'Chat about your journal...',
                        labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send, color: Colors.purple),
                          onPressed: () {
                            if (_moodNoteController!.text.isNotEmpty && !_isGeneratingResponse) {
                              final userMessage = _moodNoteController!.text;
                              _chatMessages.add(ChatMessage(
                                text: userMessage,
                                isUser: true,
                                timestamp: DateTime.now(),
                              ));
                              _moodNoteController!.clear();
                              _scrollChatToBottom();
                              _generateGeminiResponse(userMessage);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _showJournalDialogWithChatContext();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Add Journal', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickResponseChip('Give me a journal prompt'),
                    _buildQuickResponseChip('Help me reflect on my day'),
                    _buildQuickResponseChip('I want to practice gratitude'),
                    _buildQuickResponseChip('Help me understand my emotions'),
                    _buildQuickResponseChip('Suggest a writing exercise'),
                    _buildQuickResponseChip('How can I improve my mood?'),
                    _buildQuickResponseChip('Suggest a breathing exercise'),
                    _buildQuickResponseChip('I\'m feeling anxious'),
                    _buildQuickResponseChip('Tell me a positive quote'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            const Icon(Icons.psychology_alt, color: Colors.purple, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Colors.purple.withOpacity(0.2)
                    : Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickResponseChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          _moodNoteController!.text = text;
          // Also simulate sending the message
          if (_moodNoteController!.text.isNotEmpty && !_isGeneratingResponse) {
            final userMessage = _moodNoteController!.text;
            _chatMessages.add(ChatMessage(
              text: userMessage,
              isUser: true,
              timestamp: DateTime.now(),
            ));
            _moodNoteController!.clear();
            _scrollChatToBottom();

            _generateGeminiResponse(userMessage);
          }
        },
        backgroundColor: Colors.purple.withOpacity(0.2),
      ),
    );
  }

  Widget _buildTodaysMoodChart() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Today\'s Mood Overview', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.purple),
                onPressed: () {
                  _moodController.reloadMoods();
                },
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  child: Obx(() {
                    // Get today's moods
                    final todayMoods = _moodController.moods.where((mood) {
                      return isSameDay(mood.timestamp, DateTime.now());
                    }).toList();

                    if (todayMoods.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_emotions_outlined,
                                size: 40,
                                color: Theme.of(context).textTheme.bodyMedium?.color),
                            const SizedBox(height: 8),
                            Text(
                              'No mood entries today',
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _showAddMoodDialog,
                              child: const Text('Add your first mood',
                                  style: TextStyle(color: Colors.purple)),
                            ),
                          ],
                        ),
                      );
                    }

                    // Count mood occurrences
                    final moodCounts = <String, int>{};
                    for (var mood in todayMoods) {
                      moodCounts[mood.moodType] = (moodCounts[mood.moodType] ?? 0) + 1;
                    }

                    // Get mood labels and colors
                    final moodLabels = {
                      'happy': 'Happy',
                      'sad': 'Sad',
                      'neutral': 'Neutral',
                      'anxious': 'Anxious',
                      'excited': 'Excited',
                    };

                    final moodColors = {
                      'happy': Colors.green,
                      'sad': Colors.blue,
                      'neutral': Colors.amber,
                      'anxious': Colors.orange,
                      'excited': Colors.purple,
                    };

                    final pieSections = moodCounts.entries.map((entry) {
                      return PieChartSectionData(
                        value: entry.value.toDouble(),
                        color: moodColors[entry.key] ?? Colors.grey,
                        title: '${entry.value}',
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList();

                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: PieChart(
                            PieChartData(
                              sections: pieSections,
                              centerSpaceRadius: 30,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: moodCounts.entries.map<Widget>((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      color: moodColors[entry.key] ?? Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${moodLabels[entry.key] ?? entry.key}: ${entry.value}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildRecentMoods() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Mood Entries', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: Icon(Icons.add, color: Colors.purple),
                onPressed: _showAddMoodDialog,
              ),
            ],
          ),
        ),
        Obx(() {
          if (_moodController.moods.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.emoji_emotions_outlined,
                      size: 48,
                      color: Theme.of(context).textTheme.bodyMedium?.color),
                  const SizedBox(height: 16),
                  Text(
                    'No mood entries yet',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first mood entry',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showAddMoodDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text('Add Mood Entry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          final recentMoods = _moodController.moods.take(5).toList();

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentMoods.length,
            itemBuilder: (context, index) {
              final mood = recentMoods[index];
              return _buildMoodItem(mood, index);
            },
          );
        }),
      ],
    );
  }
  Widget _buildRecentJournals() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Journals', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.purple),
                onPressed: () {
                  _journalController.reloadJournals();
                },
              ),
            ],
          ),
        ),
        Obx(() {
          if (_journalController.journals.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No journal entries yet',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          final recentJournals = _journalController.journals.take(3).toList();

          return Column(
            children: recentJournals.map<Widget>((journal) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.book, color: Colors.purple, size: 24),
                  ),
                  title: Text(
                    journal.title,
                    style: Theme.of(context).textTheme.bodyLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    journal.content.length > 100
                        ? '${journal.content.substring(0, 100)}...'
                        : journal.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  trailing: Text(
                    DateFormat('MMM dd').format(journal.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  onTap: () {
                    Get.to(() => JournalListScreen());
                  },
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildMoodItem(Mood mood, int index) {
    Color moodColor;
    IconData moodIcon;

    switch (mood.moodType) {
      case 'happy':
        moodColor = Colors.green;
        moodIcon = Icons.sentiment_very_satisfied;
        break;
      case 'sad':
        moodColor = Colors.blue;
        moodIcon = Icons.sentiment_very_dissatisfied;
        break;
      case 'anxious':
        moodColor = Colors.orange;
        moodIcon = Icons.sentiment_very_dissatisfied;
        break;
      case 'excited':
        moodColor = Colors.purple;
        moodIcon = Icons.sentiment_very_satisfied;
        break;
      default:
        moodColor = Colors.amber;
        moodIcon = Icons.sentiment_neutral;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: moodColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(moodIcon, color: moodColor, size: 24),
        ),
        title: Text(
          '${mood.moodType[0].toUpperCase()}${mood.moodType.substring(1)}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Text(
          '${DateFormat('MMM dd, yyyy - HH:mm').format(mood.timestamp)}${mood.note != null ? '\nNote: ${mood.note}' : ''}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
          onPressed: () {
            _moodController.deleteMoodEntry(mood.id);
            _moodController.reloadMoods();
          },
        ),
      ),
    );
  }
}