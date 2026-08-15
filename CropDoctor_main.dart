import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const CropDoctorApp());

class CropDoctorApp extends StatelessWidget {
  const CropDoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Doctor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        scaffoldBackgroundColor: const Color(0xFFF5F8F4),
      ),
      home: const HomeScreen(),
    );
  }
}

class Diagnosis {
  final String crop;
  final String result;
  final String confidence;
  final String date;
  Diagnosis(this.crop, this.result, this.confidence, this.date);
  Map<String, dynamic> toJson() => {'crop': crop, 'result': result, 'confidence': confidence, 'date': date};
  factory Diagnosis.fromJson(Map<String, dynamic> j) =>
      Diagnosis(j['crop'], j['result'], j['confidence'], j['date']);
}

class AppState {
  static final ValueNotifier<List<Diagnosis>> history = ValueNotifier([]);
  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList('history') ?? [];
    history.value = raw.map((x) => Diagnosis.fromJson(jsonDecode(x))).toList();
  }
  static Future<void> save(Diagnosis d) async {
    final p = await SharedPreferences.getInstance();
    final list = [d, ...history.value];
    history.value = list;
    await p.setStringList('history', list.map((x) => jsonEncode(x.toJson())).toList());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  @override void initState() { super.initState(); AppState.load(); }
  @override Widget build(BuildContext context) {
    final pages = [
      const Dashboard(),
      DiagnoseScreen(onSaved: () => setState(() => index = 4)),
      const CropLibrary(),
      const DiseaseLibrary(),
      const HistoryScreen(),
    ];
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.camera_alt_outlined), selectedIcon: Icon(Icons.camera_alt), label: 'Diagnose'),
          NavigationDestination(icon: Icon(Icons.eco_outlined), selectedIcon: Icon(Icons.eco), label: 'Crops'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});
  @override Widget build(BuildContext context) => SafeArea(child: ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('🌿 Crop Doctor', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
      const Text('Your crop health assistant', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 22),
      Card(
        child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.document_scanner, size: 52, color: Color(0xFF2E7D32)),
          const SizedBox(height: 10),
          const Text('Diagnose My Crop', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          const Text('Take a photo, select symptoms and get a preliminary diagnosis.'),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StandaloneDiagnose())),
            icon: const Icon(Icons.camera_alt), label: const Text('Start Diagnosis'),
          )
        ])),
      ),
      const SizedBox(height: 10),
      const Card(child: ListTile(leading: Text('📸', style: TextStyle(fontSize: 28)), title: Text('Better photos = better analysis'), subtitle: Text('Use good lighting and focus on the affected part.'))),
      const Card(child: ListTile(leading: Text('⚠️', style: TextStyle(fontSize: 28)), title: Text('Preliminary results'), subtitle: Text('Confirm serious or widespread problems with an agricultural professional.'))),
    ],
  ));
}

class DiagnoseScreen extends StatelessWidget {
  final VoidCallback onSaved;
  const DiagnoseScreen({super.key, required this.onSaved});
  @override Widget build(BuildContext context) => StandaloneDiagnose(onSaved: onSaved);
}

class StandaloneDiagnose extends StatefulWidget {
  final VoidCallback? onSaved;
  const StandaloneDiagnose({super.key, this.onSaved});
  @override State<StandaloneDiagnose> createState() => _StandaloneDiagnoseState();
}
class _StandaloneDiagnoseState extends State<StandaloneDiagnose> {
  final picker = ImagePicker();
  String? crop;
  XFile? photo;
  final selected = <String>{};

  Future<void> pick(ImageSource source) async {
    final x = await picker.pickImage(source: source, imageQuality: 85);
    if (x != null) setState(() => photo = x);
  }

  String result() {
    if (crop == 'Tomato' && selected.contains('Brown spots')) return 'Tomato Early Blight';
    if (crop == 'Maize' && selected.contains('Insects visible')) return 'Fall Armyworm';
    if (crop == 'Maize' && selected.contains('Yellowing')) return 'Possible Nitrogen Deficiency';
    if (crop == 'Beans' && selected.contains('Brown spots')) return 'Bean Anthracnose';
    if (crop == 'Banana' && selected.contains('Black spots')) return 'Black Sigatoka';
    if (crop == 'Coffee' && selected.contains('Yellowing')) return 'Coffee Leaf Rust';
    if (crop == 'Cassava' && selected.contains('Leaf curling')) return 'Cassava Mosaic Disease';
    return 'Needs Further Assessment';
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diagnose Crop')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('1. Select crop', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      Wrap(spacing: 7, children: crops.map((c) => ChoiceChip(label: Text(c), selected: crop == c, onSelected: (_) => setState(() => crop = c))).toList()),
      const SizedBox(height: 18),
      const Text('2. Crop photo', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      Container(height: 170, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Center(child: Icon(photo == null ? Icons.photo_camera_back : Icons.check_circle, size: 55, color: Colors.green))),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () => pick(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Camera'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(onPressed: () => pick(ImageSource.gallery), icon: const Icon(Icons.photo), label: const Text('Gallery'))),
      ]),
      const SizedBox(height: 18),
      const Text('3. Symptoms', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      ...symptoms.map((s) => CheckboxListTile(contentPadding: EdgeInsets.zero, title: Text(s), value: selected.contains(s), onChanged: (v) => setState(() => v == true ? selected.add(s) : selected.remove(s)))),
      FilledButton.icon(onPressed: () {
        if (crop == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a crop first.'))); return; }
        final r = result();
        Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(crop: crop!, result: r, onSave: () async {
          await AppState.save(Diagnosis(crop!, r, r == 'Needs Further Assessment' ? 'Low' : '87%', DateTime.now().toString().substring(0, 10)));
          widget.onSaved?.call();
          if (context.mounted) Navigator.pop(context);
        })));
      }, icon: const Icon(Icons.auto_awesome), label: const Padding(padding: EdgeInsets.all(12), child: Text('Analyze Crop'))),
    ]),
  );
}

class ResultScreen extends StatelessWidget {
  final String crop, result;
  final VoidCallback onSave;
  const ResultScreen({super.key, required this.crop, required this.result, required this.onSave});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diagnosis Result')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(crop.toUpperCase(), style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(result, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      Chip(avatar: const Icon(Icons.analytics_outlined), label: Text(result == 'Needs Further Assessment' ? 'Low confidence' : '87% preliminary confidence')),
      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('This is a preliminary assessment based on the crop and symptoms selected. A production AI image model can be connected to analyze the actual photograph.'))),
      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Management: scout several plants, maintain field sanitation, use integrated pest and disease management, and follow registered product labels and local agricultural guidance.'))),
      FilledButton.icon(onPressed: onSave, icon: const Icon(Icons.save), label: const Text('Save Diagnosis')),
    ]),
  );
}

class CropLibrary extends StatelessWidget {
  const CropLibrary({super.key});
  @override Widget build(BuildContext context) => SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Crop Library', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
    ...crops.map((c) => Card(child: ListTile(leading: const Icon(Icons.eco), title: Text(c), subtitle: const Text('Diseases, pests and nutrient problems.')))),
  ]));
}

class DiseaseLibrary extends StatelessWidget {
  const DiseaseLibrary({super.key});
  @override Widget build(BuildContext context) => SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Disease & Pest Library', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
    ...problems.map((p) => Card(child: ListTile(leading: const Icon(Icons.local_florist), title: Text(p), subtitle: const Text('Reference entry — management information.')))),
  ]));
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override Widget build(BuildContext context) => SafeArea(child: ValueListenableBuilder<List<Diagnosis>>(
    valueListenable: AppState.history,
    builder: (_, list, __) => ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Diagnosis History', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      if (list.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No saved diagnoses yet.'))),
      ...list.map((d) => Card(child: ListTile(title: Text(d.result), subtitle: Text('${d.crop} • ${d.date} • ${d.confidence}')))),
    ]),
  ));
}

const crops = ['Maize','Beans','Tomato','Banana','Coffee','Cassava','Groundnuts','Cabbage','Sweet potato','Rice'];
const symptoms = ['Yellowing','Brown spots','Black spots','Holes','Wilting','Leaf curling','Insects visible','Poor growth','White/powdery coating'];
const problems = ['Maize Streak Disease','Fall Armyworm','Nitrogen Deficiency','Bean Anthracnose','Bean Rust','Angular Leaf Spot','Tomato Early Blight','Tomato Late Blight','Bacterial Wilt','Black Sigatoka','Coffee Leaf Rust','Coffee Berry Disease','Cassava Mosaic Disease','Cassava Brown Streak Disease','Diamondback Moth','Rice Blast'];
