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
  String _lastScript = "";

  void _addLog(String msg) {
    setState(() {
      _logs.insert(0, "[${DateTime.now().toString().substring(11, 19)}] $msg");
    });
  }

  Future<void> _runAgent() async {
    final task = _taskController.text.trim();
    if (task.isEmpty) {
      _addLog("অনুগ্রহ করে একটি টাস্ক লিখুন!");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_key') ?? '';

    setState(() {
      _isProcessing = true;
      _lastScript = "";
    });
    _addLog("টাস্ক গ্রহণ করা হয়েছে: $task");

    if (apiKey.isEmpty) {
      _addLog("সতর্কতা: Settings এ কোনো Gemini API Key নেই!");
      _addLog("ওপরে ডান পাশের Settings (⚙️) আইকনে গিয়ে আপনার API Key দিন।");
      setState(() => _isProcessing = false);
      return;
    }

    try {
      _addLog("Gemini AI এর সাথে যোগাযোগ করা হচ্ছে...");
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{"text": "You are a personal automated content agent. The user wants: '$task'. Write a complete creative script with title, voiceover text, and short visual cues in Bengali or English."}]
          }]
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _lastScript = text;
        });
        _addLog("সফলভাবে কনটেন্ট তৈরি হয়েছে!");
        _addLog("ভিডিও প্রসেসিং ও পোস্টিং মডিউলে ডেটা পাঠানো হয়েছে।");
      } else {
        final errorMsg = data['error']?['message'] ?? 'API রিকোয়েস্ট ব্যর্থ হয়েছে (${res.statusCode})';
        _addLog("API এরর: $errorMsg");
        _addLog("পরামর্শ: Settings-এ গিয়ে API Key টি ঠিক আছে কিনা চেক করুন।");
      }
    } catch (e) {
      _addLog("ব্যর্থ হয়েছে: $e");
    } finally {
      setState(() => _isProcessing = false);
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
                labelText: "টাস্ক লিখুন (যেমন: ekta golpo leko choto)",
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
                label: Text(_isProcessing ? "AI কাজ করছে..." : "টাস্ক শুরু করুন"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            if (_lastScript.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("তৈরি হওয়া স্ক্রিপ্ট / কনটেন্ট:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: SingleChildScrollView(
                  child: Text(_lastScript, style: const TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("অ্যাকশন লগ:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _logs.isEmpty
                    ? const Center(child: Text("টাস্ক লিখে বাটনে চাপ দিন", style: TextStyle(color: Colors.white54)))
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
    final key = _keyController.text.trim();
    final p = await SharedPreferences.getInstance();
    await p.setString('gemini_key', key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(key.isEmpty ? "API Key মুছে ফেলা হয়েছে" : "API Key সফলভাবে সংরক্ষিত হয়েছে!")),
      );
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
              decoration: const InputDecoration(
                labelText: "Google Gemini API Key",
                hintText: "AIzaSy...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "ফ্রি API Key পেতে aistudio.google.com-এ যান এবং 'Get API key'-তে ক্লিক করুন।",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              child: const Text("Save Key"),
            ),
          ],
        ),
      ),
    );
  }
}
