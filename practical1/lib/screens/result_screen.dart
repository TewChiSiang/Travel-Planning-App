import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ResultScreen extends StatefulWidget {
  final String destination;
  final int duration;
  final double budget;
  final int participants;
  final String travelType;

  const ResultScreen({
    super.key,
    required this.destination,
    required this.duration,
    required this.budget,
    required this.participants,
    required this.travelType,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Uint8List? _generatedImage;
  Map<String, dynamic>? _travelPlan;
  bool _isLoading = true;
  String _errorMessage = '';

  final String hfApiKey = dotenv.env['HUGGING_FACE_API_KEY'] ?? '';

  late final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash',
    generationConfig: GenerationConfig(responseMimeType: 'application/json'),
  );

  @override
  void initState() {
    super.initState();
    _generateContent();
  }

  Future<void> _generateContent() async {
    try {
      final responses = await Future.wait([
        _fetchImage(),
        _fetchRecommendations(),
      ]);

      if (mounted) {
        setState(() {
          _generatedImage = responses[0] as Uint8List;
          _travelPlan = responses[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Uint8List> _fetchImage() async {
    final prompt =
        'A highly detailed, cinematic travel poster of ${widget.destination}, highlighting a ${widget.travelType} travel experience, bright colors, stunning landscape, no text.';

    final response = await http.post(
      Uri.parse(
        'https://router.huggingface.co/hf-inference/models/stabilityai/stable-diffusion-xl-base-1.0',
      ),
      headers: {
        'Authorization': 'Bearer $hfApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'inputs': prompt}),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to generate image. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> _fetchRecommendations() async {
    final prompt = '''
      You are an expert travel planner. Create a travel itinerary based on these parameters:
      - Destination: ${widget.destination}
      - Duration: ${widget.duration} days
      - Budget: RM ${widget.budget}
      - Participants: ${widget.participants}
      - Travel Type: ${widget.travelType}

      Respond ONLY with a valid JSON object using this exact structure:
      {
        "title": "A catchy title for the trip",
        "summary": "A brief 2 sentence summary",
        "dailyPlan": ["Day 1: activity", "Day 2: activity"],
        "budgetTips": "A brief tip on managing the RM budget"
      }
    ''';

    final response = await model.generateContent([Content.text(prompt)]);
    final jsonString = response.text;

    if (jsonString != null) {
      String cleanJson = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return jsonDecode(cleanJson);
    } else {
      throw Exception('Failed to generate recommendations from AI');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Crafting your perfect trip to ${widget.destination}...',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Oops!')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // Dynamic Header with AI Image
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _generatedImage != null
                  ? Image.memory(
                      _generatedImage!,
                      fit: BoxFit.cover,
                    )
                  : const ColoredBox(color: Colors.grey),
            ),
          ),
          
          // Result Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Summary Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _travelPlan!['title'] ?? 'Your Trip',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _travelPlan!['summary'] ?? '',
                            style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Itinerary Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Daily Itinerary',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_travelPlan!['dailyPlan'] as List<dynamic>).map((day) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          child: Icon(Icons.map, color: Theme.of(context).colorScheme.onSecondaryContainer),
                        ),
                        title: Text(day.toString(), style: const TextStyle(height: 1.4)),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 24),
                  
                  // Budget Tips Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Budget Tips',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.onTertiaryContainer),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _travelPlan!['budgetTips'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Theme.of(context).colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}