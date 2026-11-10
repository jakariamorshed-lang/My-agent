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
      setState(() => _isProcessing = false);
      return;
    }

    try {
      _addLog("Gemini 2.0 AI এর সাথে যোগাযোগ করা হচ্ছে...");
      
      // গুগল এর লেটেস্ট মডেলগুলো ট্রাই করা
      final models = ['gemini-2.0-flash', 'gemini-2.5-flash', 'gemini-1.5-flash-latest'];
      http.Response? res;
      Map<String, dynamic>? data;

      for (final m in models) {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent?key=$apiKey',
        );

        res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [{
              "parts": [{"text": "You are a personal automated content agent. The user wants: '$task'. Write a complete creative script with title, voiceover text, and short visual cues in Bengali or English."}]
            }]
          }),
        );

        data = jsonDecode(res.body);
        if (res.statusCode == 200) {
          _addLog("মডেল সফলভাবে কানেক্ট হয়েছে: $m");
          break;
        }
      }

      if (res != null && res.statusCode == 200 && data != null && data['candidates'] != null) {
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _lastScript = text;
        });
        _addLog("সফলভাবে কনটেন্ট তৈরি হয়েছে!");
        _addLog("টাস্ক এক্সিকিউশন সম্পূর্ণ!");
      } else {
        final errorMsg = data?['error']?['message'] ?? 'API রিকোয়েস্ট ব্যর্থ হয়েছে (${res?.statusCode})';
        _addLog("API এরর: $errorMsg");
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
                child: Text("তৈরি হওয়া স্ক্রিপ্ট / কনটেন্ট:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 16)),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(_lastScript, style: const TextStyle(fontSize: 14, height: 1.4)),
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
        const SnackBar(content: Text("API Key সফলভাবে সংরক্ষিত হয়েছে!")),
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
                border: OutlineInputBorder(),
              ),
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
