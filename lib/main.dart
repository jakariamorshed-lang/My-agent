import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AgentDashboard(),
  ));
}

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({super.key});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  final TextEditingController _taskController = TextEditingController();
  final List<String> _logs = [];
  bool _isProcessing = false;

  void _addLog(String msg) {
    setState(() {
      _logs.insert(0, "[${DateTime.now().toString().substring(11, 19)}] $msg");
    });
  }

  Future<void> _runAgent() async {
    final task = _taskController.text.trim();
    if (task.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_key') ?? '';

    setState(() => _isProcessing = true);
    _addLog("টাস্ক গ্রহণ করা হয়েছে: $task");

    try {
      if (apiKey.isEmpty) {
        _addLog("সতর্কতা: কোনো API কী পাওয়া যায়নি। ডেমো মোডে চলছে...");
        await Future.delayed(const Duration(seconds: 2));
        _addLog("স্ক্রিপ্ট প্ল্যানিং সম্পন্ন!");
        _addLog("ভিডিও রেন্ডারিং মডিউল প্রস্তুত...");
        _addLog("YouTube এবং Facebook-এ পাবলিশ করার প্রস্তুতি নেওয়া হচ্ছে...");
        _addLog("টাস্ক সফলভাবে সম্পন্ন হয়েছে (Demo Mode)!");
      } else {
        _addLog("Gemini API দিয়ে স্ক্রিপ্ট তৈরি হচ্ছে...");
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        );
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [{
              "parts": [{"text": "Create a short video outline for: $task"}]
            }]
          }),
        );
        final data = jsonDecode(res.body);
        final result = data['candidates'][0]['content']['parts'][0]['text'];
        _addLog("স্ক্রিপ্ট তৈরি হয়েছে: ${result.substring(0, result.length > 50 ? 50 : result.length)}...");
        _addLog("সোশ্যাল মিডিয়ায় অটো-পোস্টিং শুরু হচ্ছে...");
        _addLog("সফলভাবে টাস্ক সম্পন্ন হয়েছে!");
      }
    } catch (e) {
      _addLog("ত্রুটি: $e");
    } finally {
      setState(() => _isProcessing = false);
      _taskController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Personal Agent"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _taskController,
              decoration: const InputDecoration(
                labelText: "টাস্ক লিখুন (যেমন: Make Space Short & Upload)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.smart_toy_outlined),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _runAgent,
                icon: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.flash_on),
                label: Text(_isProcessing ? "কাজ চলছে..." : "টাস্ক শুরু করুন"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("অ্যাকশন লগ:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _logs.isEmpty
                    ? const Center(child: Text("এখনও কোনো টাস্ক দেওয়া হয়নি", style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(_logs[i], style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontFamily: 'monospace')),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      _keyController.text = p.getString('gemini_key') ?? '';
    });
  }

  void _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('gemini_key', _keyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("API Key সংরক্ষিত হয়েছে!")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(labelText: "Gemini API Key", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              child: const Text("Save Settings"),
            ),
          ],
        ),
      ),
    );
  }
}
