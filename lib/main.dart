import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CropDoctor());
}

const crops = [
  'Maize',
  'Beans',
  'Tomato',
  'Banana',
  'Coffee',
  'Cassava',
  'Groundnuts',
  'Cabbage',
  'Sweet potato',
  'Rice',
];

const symptoms = [
  'Yellowing',
  'Brown spots',
  'Black spots',
  'Holes',
  'Wilting',
  'Leaf curling',
  'Insects visible',
  'Poor growth',
  'White/powdery coating',
];

class CropDoctor extends StatelessWidget {
  const CropDoctor({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Doctor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2e7d32),
        ),
        scaffoldBackgroundColor: const Color(0xfff5f8f4),
      ),
      home: const Home(),
    );
  }
}

class Store {
  static final history =
      ValueNotifier<List<Map<String, String>>>([]);

  static const endpointKey = 'ai_endpoint';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getStringList('history') ?? [];

    history.value = saved
        .map(
          (item) => Map<String, String>.from(
            jsonDecode(item),
          ),
        )
        .toList();
  }

  static Future<void> save(Map<String, String> item) async {
    final prefs = await SharedPreferences.getInstance();

    final updated = [item, ...history.value];

    history.value = updated;

    await prefs.setStringList(
      'history',
      updated.map(jsonEncode).toList(),
    );
  }

  static Future<String> getEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(endpointKey) ?? '';
  }

  static Future<void> setEndpoint(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(endpointKey, value.trim());
  }
}

class CropAI {
  Future<Map<String, dynamic>> analyze({
    required File image,
    required String crop,
    required List<String> symptoms,
  }) async {
    final endpoint = await Store.getEndpoint();

    if (endpoint.isEmpty) {
      return localDiagnosis(crop, symptoms);
    }

    final bytes = await image.readAsBytes();

    final base64Image = base64Encode(bytes);

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'crop': crop,
            'symptoms': symptoms,
            'image_base64': base64Image,
            'mime_type': 'image/jpeg',
          }),
        )
        .timeout(
          const Duration(seconds: 60),
        );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception('AI server error');
    }

    return jsonDecode(response.body);
  }

  Map<String, dynamic> localDiagnosis(
    String crop,
    List<String> symptoms,
  ) {
    String result = 'Needs Further Assessment';
    String confidence = 'Low';

    if (crop == 'Tomato' &&
        symptoms.contains('Brown spots')) {
      result = 'Possible Tomato Early Blight';
      confidence = '87%';
    } else if (crop == 'Maize' &&
        symptoms.contains('Insects visible')) {
      result = 'Possible Fall Armyworm';
      confidence = '88%';
    } else if (crop == 'Maize' &&
        symptoms.contains('Yellowing')) {
      result = 'Possible Nitrogen Deficiency';
      confidence = '82%';
    } else if (crop == 'Beans' &&
        symptoms.contains('Brown spots')) {
      result = 'Possible Bean Anthracnose';
      confidence = '84%';
    } else if (crop == 'Banana' &&
        symptoms.contains('Black spots')) {
      result = 'Possible Black Sigatoka';
      confidence = '86%';
    }

    return {
      'result': result,
      'confidence': confidence,
      'explanation':
          'The AI server is not configured yet. '
          'This is a preliminary symptom-based assessment.',
      'alternatives': [
        'Other crop disease',
        'Nutrient deficiency',
        'Environmental stress',
      ],
      'management':
          'Inspect several plants, maintain field sanitation, '
          'and seek advice from an agricultural extension officer '
          'before applying treatment.',
    };
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Store.load();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const Dashboard(),
      Diagnose(
        onSaved: () {
          setState(() {
            selectedIndex = 4;
          });
        },
      ),
      const CropLibrary(),
      const DiseaseLibrary(),
      const History(),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Diagnose',
          ),
          NavigationDestination(
            icon: Icon(Icons.eco_outlined),
            selectedIcon: Icon(Icons.eco),
            label: 'Crops',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '🌿 Crop Doctor',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'AI crop health assistant',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.document_scanner,
                    size: 52,
                    color: Color(0xff2e7d32),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AI Photo Diagnosis',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Take a photo of an affected crop '
                    'and analyse it using Crop Doctor AI.',
                  ),
                  const SizedBox(height: 15),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const DiagnosePage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text(
                      'Start Diagnosis',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('AI Server'),
              subtitle: const Text(
                'Configure the AI connection from Diagnose settings.',
              ),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Text(
                '⚠️',
                style: TextStyle(fontSize: 25),
              ),
              title: Text(
                'Decision support',
              ),
              subtitle: Text(
                'Confirm serious crop problems with '
                'an agricultural professional.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Diagnose extends StatelessWidget {
  final VoidCallback onSaved;

  const Diagnose({
    super.key,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return DiagnosePage(onSaved: onSaved);
  }
}

class DiagnosePage extends StatefulWidget {
  final VoidCallback? onSaved;

  const DiagnosePage({
    super.key,
    this.onSaved,
  });

  @override
  State<DiagnosePage> createState() =>
      _DiagnosePageState();
}

class _DiagnosePageState extends State<DiagnosePage> {
  final ImagePicker picker = ImagePicker();
  final CropAI ai = CropAI();

  String? crop;
  File? image;

  final Set<String> selectedSymptoms = {};

  bool analyzing = false;

  Future<void> pickImage(
    ImageSource source,
  ) async {
    final selected = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (selected != null) {
      setState(() {
        image = File(selected.path);
      });
    }
  }

  Future<void> analyze() async {
    if (crop == null) {
      showMessage(
        'Please select a crop first.',
      );
      return;
    }

    if (image == null) {
      showMessage(
        'Please take or select a crop photo.',
      );
      return;
    }

    setState(() {
      analyzing = true;
    });

    try {
      final diagnosis = await ai.analyze(
        image: image!,
        crop: crop!,
        symptoms: selectedSymptoms.toList(),
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            crop: crop!,
            data: diagnosis,
            onSave: () async {
              await Store.save({
                'crop': crop!,
                'result':
                    diagnosis['result'] ??
                        'Needs Further Assessment',
                'confidence':
                    diagnosis['confidence'] ?? 'Low',
                'date': DateTime.now()
                    .toIso8601String()
                    .substring(0, 10),
              });

              widget.onSaved?.call();

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ),
      );
    } catch (e) {
      showMessage(
        'AI service unavailable. Check your connection '
        'and AI server settings.',
      );
    }

    if (mounted) {
      setState(() {
        analyzing = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Crop Diagnosis',
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            '1. Select crop',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: crops.map((item) {
              return ChoiceChip(
                label: Text(item),
                selected: crop == item,
                onSelected: (_) {
                  setState(() {
                    crop = item;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const Text(
            '2. Add crop photo',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            height: 210,
            margin: const EdgeInsets.symmetric(
              vertical: 10,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: image == null
                ? const Center(
                    child: Icon(
                      Icons.photo_camera_back,
                      size: 60,
                      color: Colors.green,
                    ),
                  )
                : Image.file(
                    image!,
                    fit: BoxFit.cover,
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    pickImage(
                      ImageSource.camera,
                    );
                  },
                  icon: const Icon(
                    Icons.camera_alt,
                  ),
                  label: const Text(
                    'Camera',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    pickImage(
                      ImageSource.gallery,
                    );
                  },
                  icon: const Icon(
                    Icons.photo,
                  ),
                  label: const Text(
                    'Gallery',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '3. Observed symptoms',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Optional — select anything you have observed.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 5),
          ...symptoms.map(
            (symptom) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(symptom),
              value:
                  selectedSymptoms.contains(symptom),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    selectedSymptoms.add(symptom);
                  } else {
                    selectedSymptoms.remove(symptom);
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed:
                analyzing ? null : analyze,
            icon: analyzing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.auto_awesome,
                  ),
            label: Padding(
              padding:
                  const EdgeInsets.all(12),
              child: Text(
                analyzing
                    ? 'Analyzing photo...'
                    : 'Analyze with AI',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final String crop;
  final Map<String, dynamic> data;
  final VoidCallback onSave;

  const ResultPage({
    super.key,
    required this.crop,
    required this.data,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final alternatives =
        (data['alternatives'] as List?)
                ?.map(
                  (item) => item.toString(),
                )
                .toList() ??
            [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Diagnosis',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            crop.toUpperCase(),
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            data['result'] ??
                'Needs Further Assessment',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Chip(
            avatar: const Icon(
              Icons.analytics_outlined,
            ),
            label: Text(
              '${data['confidence'] ?? 'Low'} confidence',
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What the AI observed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['explanation'] ??
                        'No explanation available.',
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alternative possibilities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...alternatives.map(
                    (item) => ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: const Icon(
                        Icons.eco,
                      ),
                      title: Text(item),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['management'] ??
                        'Seek agricultural extension advice.',
                  ),
                ],
              ),
            ),
          ),
          const Card(
            color: Color(0xfffff7df),
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                '⚠️ AI diagnosis is decision support '
                'and not laboratory confirmation.',
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: const Text(
              'Save Diagnosis',
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() =>
      _SettingsPageState();
}

class _SettingsPageState
    extends State<SettingsPage> {
  final controller =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    Store.getEndpoint().then(
      (value) {
        controller.text = value;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Server Settings',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'AI server HTTPS endpoint',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Paste the HTTPS address ending in /analyze. '
            'Never put an AI API key inside the app.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: controller,
            keyboardType:
                TextInputType.url,
            decoration:
                const InputDecoration(
              border:
                  OutlineInputBorder(),
              hintText:
                  'https://your-server.com/analyze',
            ),
          ),
          const SizedBox(height: 15),
          FilledButton(
            onPressed: () async {
              await Store.setEndpoint(
                controller.text,
              );

              if (!context.mounted) return;

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'AI server saved ✓',
                  ),
                ),
              );
            },
            child: const Text(
              'Save AI Server',
            ),
          ),
        ],
      ),
    );
  }
}

class CropLibrary extends StatelessWidget {
  const CropLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Crop Library',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...crops.map(
            (crop) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.eco,
                ),
                title: Text(crop),
                subtitle: const Text(
                  'Diseases, pests and nutrient problems.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiseaseLibrary extends StatelessWidget {
  const DiseaseLibrary({super.key});

  final List<String> diseases = const [
    'Maize Streak Disease',
    'Fall Armyworm',
    'Nitrogen Deficiency',
    'Bean Anthracnose',
    'Bean Rust',
    'Angular Leaf Spot',
    'Tomato Early Blight',
    'Tomato Late Blight',
    'Bacterial Wilt',
    'Black Sigatoka',
    'Coffee Leaf Rust',
    'Coffee Berry Disease',
    'Cassava Mosaic Disease',
    'Cassava Brown Streak Disease',
    'Diamondback Moth',
    'Rice Blast',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Disease & Pest Library',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...diseases.map(
            (disease) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.local_florist,
                ),
                title: Text(disease),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class History extends StatelessWidget {
  const History({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<
          List<Map<String, String>>>(
        valueListenable: Store.history,
        builder: (context, list, _) {
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'Diagnosis History',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (list.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No saved diagnoses yet.',
                    ),
                  ),
                ),
              ...list.map(
                (item) => Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.health_and_safety,
                      color: Colors.green,
                    ),
                    title: Text(
                      item['result'] ?? '',
                    ),
                    subtitle: Text(
                      '${item['crop']} • '
                      '${item['date']} • '
                      '${item['confidence']}',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
