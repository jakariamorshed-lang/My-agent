import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const BartaAIWhatsAppApp());
}

class BartaAIWhatsAppApp extends StatelessWidget {
  const BartaAIWhatsAppApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BartaAI WhatsApp Bot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF047857),
          primary: const Color(0xFF047857),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),
      home: const BartaHomeScreen(),
    );
  }
}

class MessageItem {
  final String senderName;
  final String phone;
  final String text;
  final String time;
  final String language;
  final String category; // IMPORTANT, QUESTION, UNIMPORTANT
  final String actionSummary;
  final String? autoReply;

  MessageItem({
    required this.senderName,
    required this.phone,
    required this.text,
    required this.time,
    required this.language,
    required this.category,
    required this.actionSummary,
    this.autoReply,
  });
}

class BartaHomeScreen extends StatefulWidget {
  const BartaHomeScreen({super.key});

  @override
  State<BartaHomeScreen> createState() => _BartaHomeScreenState();
}

class _BartaHomeScreenState extends State<BartaHomeScreen> {
  int _selectedIndex = 0;
  bool _isProcessing = false;

  // আগে থেকেই ব্যবসা সম্পর্কে সব তথ্য (Business Knowledge Base)
  final TextEditingController _businessNameCtrl = TextEditingController(
    text: 'Dhaka Craft & Gadget Hub',
  );
  final TextEditingController _productsCtrl = TextEditingController(
    text:
        '1. ANC Pro Wireless Earbuds - 1,850 BDT (In Stock, 6m Warranty)\n'
        '2. RGB Mechanical Keyboard K68 - 3,200 BDT (In Stock, 1yr Warranty)\n'
        '3. 65W GaN Fast Charger - 1,450 BDT (Limited Stock)\n'
        '4. Handcrafted Leather Wallet - 950 BDT (In Stock)',
  );
  final TextEditingController _deliveryPolicyCtrl = TextEditingController(
    text:
        'ঢাকার ভেতরে ডেলিভারি চার্জ ৬০ টাকা (২৪ ঘণ্টায় ডেলিভারি)। ঢাকার বাইরে সারা বাংলাদেশে ১২০ টাকা (২-৩ দিন)। সম্পূর্ণ ক্যাশ অন ডেলিভারি (COD) সুবিধা আছে—প্রোডাক্ট দেখে টাকা দিতে পারবেন।',
  );
  final TextEditingController _paymentInfoCtrl = TextEditingController(
    text:
        'Cash on Delivery (COD), bKash Merchant: 01711-889900, Nagad: 01711-889900.',
  );
  final TextEditingController _addressCtrl = TextEditingController(
    text: 'House 14, Road 7, Dhanmondi, Dhaka-1205 (10 AM - 10 PM).',
  );
  final TextEditingController _importantRulesCtrl = TextEditingController(
    text:
        'বড় বা পাইকারি অর্ডার (৫+ পিস), বিকাশ/নগদ TrxID পেমেন্ট কনফার্মেশন, জরুরি কমপ্লেইন বা রিফান্ড, অথবা ওনারের সাথে সরাসরি কথা বলতে চাইলে।',
  );
  final TextEditingController _geminiApiKeyCtrl = TextEditingController(
    text: '',
  );

  final TextEditingController _simNameCtrl = TextEditingController(
    text: 'Tanvir Ahmed',
  );
  final TextEditingController _simPhoneCtrl = TextEditingController(
    text: '+880 1712-458921',
  );
  final TextEditingController _simMsgCtrl = TextEditingController();

  final List<MessageItem> _messages = [
    MessageItem(
      senderName: 'Tanvir Ahmed',
      phone: '+880 1712-458921',
      text:
          'Bhaiya, amader office er jonno 15 piece ANC Pro Earbuds lagbe ajkei. Dhanmondi te urgent delivery dewa jabe? bKash patacchi.',
      time: '10:42 AM',
      language: 'Banglish',
      category: 'IMPORTANT',
      actionSummary:
          'জরুরি অর্ডার -> আপনাকে নোটিফিকেশন পাঠানো হয়েছে + অটো-রিপ্লাই দেওয়া হয়েছে',
      autoReply:
          'আসসালামু আলাইকুম ভাইয়া! ANC Pro Wireless Earbuds (1,850 BDT) আমাদের স্টকে আছে এবং আজকেই ধানমন্ডিতে ডেলিভারি দেওয়া যাবে। আপনার ১৫ পিসের জরুরি অর্ডারের বিষয়ে আমি এক্ষুনি আমাদের ওনারকে নোটিফিকেশন পাঠিয়েছি—উনি এখনই আপনার সাথে যোগাযোগ করছেন!',
    ),
    MessageItem(
      senderName: 'Nusrat Jahan',
      phone: '+880 1819-332104',
      text:
          'ভাইয়া, মেকানিক্যাল কীবোর্ডটার দাম কত? আর ঢাকার বাইরে চট্টগ্রামে ডেলিভারি চার্জ কত পড়বে?',
      time: '10:28 AM',
      language: 'Bangla (বাংলা)',
      category: 'QUESTION',
      actionSummary: 'ব্যবসার প্রশ্ন -> বট আপনার তথ্য থেকে নিজেই উত্তর দিয়েছে',
      autoReply:
          'আপু/ভাইয়া, আমাদের RGB Mechanical Keyboard K68-এর দাম ৩,২০০ টাকা (১ বছরের ওয়ারেন্টি সহ)। ঢাকার বাইরে চট্টগ্রামে ডেলিভারি চার্জ ১২০ টাকা। ক্যাশ অন ডেলিভারিতে প্রোডাক্ট চেক করে পেমেন্ট করতে পারবেন!',
    ),
    MessageItem(
      senderName: 'Rafiqul Islam',
      phone: '+880 1914-778290',
      text: 'Ok bhaiya dhonnobad 👍',
      time: '10:15 AM',
      language: 'Banglish',
      category: 'UNIMPORTANT',
      actionSummary:
          'অপ্রয়োজনীয় মেসেজ -> শুধুই Seen (✓✓) করা হয়েছে (কোনো রিপ্লাই বা নোটিফিকেশন দেওয়া হয়নি)',
      autoReply: null,
    ),
  ];

  String _formatNow() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final min = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  Future<void> _processIncomingMessage(
    String sender,
    String phone,
    String text,
  ) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _isProcessing = true;
    });

    final cleanText = text.trim();
    final lower = cleanText.toLowerCase();

    final hasBanglaUnicode = RegExp(r'[\u0980-\u09FF]').hasMatch(cleanText);
    final banglishWords = [
      'bhai', 'bhaiya', 'apu', 'koto', 'dam', 'lagbe', 'nibo',
      'ache', 'ki', 'kivabe', 'ajke', 'taka', 'dhonnobad', 'achha', 'thik'
    ];
    final isBanglish =
        !hasBanglaUnicode && banglishWords.any((w) => lower.contains(w));
    final detectedLanguage = hasBanglaUnicode
        ? 'Bangla (বাংলা)'
        : (isBanglish ? 'Banglish' : 'English');

    String category = 'QUESTION';
    String actionSummary = '';
    String? autoReply;

    if (_geminiApiKeyCtrl.text.trim().isNotEmpty) {
      try {
        final aiResult = await _callGeminiDirect(cleanText, detectedLanguage);
        category = aiResult['category'] ?? 'QUESTION';
        actionSummary = aiResult['actionSummary'] ?? '';
        autoReply = aiResult['autoReply'];
      } catch (_) {
        final fallback = _smartLocalTriage(cleanText, lower, detectedLanguage);
        category = fallback['category']!;
        actionSummary = fallback['actionSummary']!;
        autoReply = fallback['autoReply'];
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
      final result = _smartLocalTriage(cleanText, lower, detectedLanguage);
      category = result['category']!;
      actionSummary = result['actionSummary']!;
      autoReply = result['autoReply'];
    }

    final newItem = MessageItem(
      senderName: sender,
      phone: phone,
      text: cleanText,
      time: _formatNow(),
      language: detectedLanguage,
      category: category,
      actionSummary: actionSummary,
      autoReply: autoReply,
    );

    setState(() {
      _messages.insert(0, newItem);
      _isProcessing = false;
    });

    if (category == 'IMPORTANT') {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFB45309),
            duration: const Duration(seconds: 4),
            content: Text(
              '🔔 জরুরি মেসেজ অ্যালার্ট ($sender): $cleanText',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
    } else if (category == 'UNIMPORTANT') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0369A1),
            duration: Duration(seconds: 2),
            content: Text(
              '✓✓ Unimportant মেসেজ: শুধুই Seen করে রাখা হয়েছে।',
            ),
          ),
        );
      }
    }
  }

  Map<String, String?> _smartLocalTriage(
    String text,
    String lower,
    String detectedLanguage,
  ) {
    final unimportantPatterns = [
      'hi', 'hello', 'hlw', 'good morning', 'good night', 'ok', 'okay',
      'thanks', 'thank you', 'dhonnobad', 'ধন্যবাদ', 'আচ্ছা', 'ঠিক আছে',
      'achha', 'thik ache', 'hmm', '👍', 'হ্যালো', 'হাই', 'শুভ সকাল'
    ];
    final isShortGreetingOrAck = text.length <= 28 &&
        unimportantPatterns.any(
          (p) => lower == p || lower.startsWith('$p ') || lower.endsWith(' $p'),
        );

    if (isShortGreetingOrAck) {
      return {
        'category': 'UNIMPORTANT',
        'actionSummary':
            'অপ্রয়োজনীয় মেসেজ -> শুধুই Seen (✓✓) করা হয়েছে (কোনো রিপ্লাই বা নোটিফিকেশন দেওয়া হয়নি)',
        'autoReply': null,
      };
    }

    final importantKeywords = [
      'trxid', 'bkash', 'nagad', 'বিকাশ', 'নগদ', 'urgent', 'আর্জেন্ট',
      'জরুরি', 'পাইকারি', 'piece', 'পিস', 'order confirm', 'অর্ডার কনফার্ম',
      'পাঠিয়েছি', 'পেমেন্ট করেছি', 'সমস্যা', 'নষ্ট', 'complaint', 'call me',
      'কল দেন', 'মালিক', 'owner'
    ];
    final isImportant = importantKeywords.any((k) => lower.contains(k));

    if (isImportant) {
      final reply = detectedLanguage == 'English'
          ? 'Thank you for your urgent message to ${_businessNameCtrl.text}! I have sent an immediate notification alert to our owner. They will contact you shortly.'
          : 'আসসালামু আলাইকুম! ${_businessNameCtrl.text}-এ আপনার জরুরি মেসেজটি পেয়েছি। আমি এক্ষুনি আমাদের ওনারকে নোটিফিকেশন পাঠিয়েছি—উনি দ্রুত আপনার সাথে যোগাযোগ করছেন!';
      return {
        'category': 'IMPORTANT',
        'actionSummary':
            'জরুরি (Important) মেসেজ -> আপনাকে নোটিফিকেশন পাঠানো হয়েছে + অটো-রিপ্লাই দেওয়া হয়েছে',
        'autoReply': reply,
      };
    }

    final reply = detectedLanguage == 'English'
        ? 'Welcome to ${_businessNameCtrl.text}!\n\n• Products & Prices:\n${_productsCtrl.text}\n\n• Delivery Policy: ${_deliveryPolicyCtrl.text}\n• Payment: ${_paymentInfoCtrl.text}\n• Address: ${_addressCtrl.text}'
        : 'আসসালামু আলাইকুম! ${_businessNameCtrl.text}-এ আপনাকে স্বাগতম। আপনার প্রশ্নের উত্তর নিচে দেওয়া হলো:\n\n🛍️ প্রোডাক্ট ও দাম:\n${_productsCtrl.text}\n\n🚚 ডেলিভারি নিয়ম: ${_deliveryPolicyCtrl.text}\n💳 পেমেন্ট: ${_paymentInfoCtrl.text}\n📍 ঠিকানা: ${_addressCtrl.text}';

    return {
      'category': 'QUESTION',
      'actionSummary':
          'ব্যবসা সংক্রান্ত প্রশ্ন -> আপনার দেওয়া তথ্য থেকে স্বয়ংক্রিয়ভাবে উত্তর দেওয়া হয়েছে',
      'autoReply': reply,
    };
  }

  Future<Map<String, String?>> _callGeminiDirect(
    String messageText,
    String detectedLanguage,
  ) async {
    final apiKey = _geminiApiKeyCtrl.text.trim();
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final systemPrompt = '''
You are the WhatsApp Business AI Bot for "${_businessNameCtrl.text}".
Understand Bangla, Banglish, and English.
Products: ${_productsCtrl.text}
Delivery: ${_deliveryPolicyCtrl.text}
Payment: ${_paymentInfoCtrl.text}
Address: ${_addressCtrl.text}
Important Triggers: ${_importantRulesCtrl.text}
Classify into IMPORTANT, QUESTION, or UNIMPORTANT.
Respond strictly in JSON: {"category": "IMPORTANT|QUESTION|UNIMPORTANT", "actionSummary": "...", "autoReply": "..."}
''';

    final client = HttpClient();
    final request = await client.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.add(
      utf8.encode(
        jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': '$systemPrompt\n\nCustomer Message: "$messageText"'}
              ]
            }
          ],
          'generationConfig': {'responseMimeType': 'application/json'},
        }),
      ),
    );

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);
    final rawText = decoded['candidates'][0]['content']['parts'][0]['text'];
    final parsed = jsonDecode(rawText);

    final cat = parsed['category']?.toString() ?? 'QUESTION';
    final rep = parsed['autoReply']?.toString() ?? '';
    return {
      'category': cat,
      'actionSummary': parsed['actionSummary']?.toString() ?? 'Processed by AI',
      'autoReply': (cat == 'UNIMPORTANT' || rep.trim().isEmpty) ? null : rep,
    };
  }

  @override
  Widget build(BuildContext context) {
    final importantAlerts =
        _messages.where((m) => m.category == 'IMPORTANT').toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BartaAI — WhatsApp Bot',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              'বাংলা • Banglish • English Business Assistant',
              style: TextStyle(fontSize: 11, color: Color(0xFFD1FAE5)),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildInboxAndSimulatorTab(),
          _buildKnowledgeBaseTab(),
          _buildImportantAlertsTab(importantAlerts),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Inbox & Test',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'ব্যবসার তথ্য (Train)',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('${importantAlerts.length}'),
              child: const Icon(Icons.notifications_active_outlined),
            ),
            selectedIcon: Badge(
              label: Text('${importantAlerts.length}'),
              child: const Icon(Icons.notifications_active),
            ),
            label: 'জরুরি Alerts',
          ),
        ],
      ),
    );
  }

  Widget _buildInboxAndSimulatorTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'হোয়াটসঅ্যাপ মেসেজ টেস্ট করুন (বাংলা / Banglish / English)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _simMsgCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText:
                      'যেমন: ভাইয়া ইয়ারবাডসের দাম কত? / Urgent 20 piece lagbe / Ok thanks',
                  hintStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          final txt = _simMsgCtrl.text;
                          _simMsgCtrl.clear();
                          _processIncomingMessage(
                            _simNameCtrl.text,
                            _simPhoneCtrl.text,
                            txt,
                          );
                        },
                  icon: const Icon(Icons.send, size: 16),
                  label: Text(
                    _isProcessing ? 'বট মেসেজ পড়ছে...' : 'মেসেজ পাঠান',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text(
                      '🔔 জরুরি অর্ডার (Banglish)',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () => _processIncomingMessage(
                      'Mahmudul Hasan',
                      '+880 1715-882310',
                      'Bhaiya amader dokaner jonno 20 piece Earbuds lagbe ajkei urgent. bKash patacchi, call me!',
                    ),
                  ),
                  ActionChip(
                    label: const Text(
                      '💬 দাম ও ডেলিভারি প্রশ্ন (বাংলা)',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () => _processIncomingMessage(
                      'Farhana Yeasmin',
                      '+880 1812-664902',
                      'ভাইয়া আপনার দোকানের প্রোডাক্টগুলোর দাম কত? আর ঢাকার বাইরে ডেলিভারি চার্জ কত?',
                    ),
                  ),
                  ActionChip(
                    label: const Text(
                      '✓✓ Unimportant (Seen Only)',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () => _processIncomingMessage(
                      'Sabbir Hossain',
                      '+880 1552-309182',
                      'Ok bhaiya dhonnobad 👍',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'হোয়াটসঅ্যাপ ইনবক্স ও বটের সিদ্ধান্ত (Live Log)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ..._messages.map((m) => _buildMessageCard(m)),
      ],
    );
  }

  Widget _buildMessageCard(MessageItem m) {
    final isImportant = m.category == 'IMPORTANT';
    final isUnimportant = m.category == 'UNIMPORTANT';
    final statusColor = isImportant
        ? const Color(0xFFB45309)
        : isUnimportant
            ? const Color(0xFF0369A1)
            : const Color(0xFF047857);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isImportant
              ? const Color(0xFFFCD34D)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${m.senderName} • ${m.phone}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '${m.time} ✓✓',
                style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(m.text, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 8),
          Text(
            'ভাষা: ${m.language} • ${m.actionSummary}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          if (m.autoReply != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                m.autoReply!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF064E3B)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKnowledgeBaseTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'আগে থেকেই আপনার ব্যবসা সম্পর্কে সব তথ্য লিখে রাখুন',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              _buildField('ব্যবসা বা দোকানের নাম', _businessNameCtrl, 1),
              _buildField('প্রোডাক্টের তালিকা ও দাম', _productsCtrl, 4),
              _buildField('ডেলিভারি চার্জ ও নিয়মাবলী', _deliveryPolicyCtrl, 3),
              _buildField('বিকাশ / নগদ ও পেমেন্ট তথ্য', _paymentInfoCtrl, 2),
              _buildField('ঠিকানা ও সময়সূচী', _addressCtrl, 2),
              _buildField('কোন মেসেজগুলো Important?', _importantRulesCtrl, 2),
              _buildField('Gemini API Key (ঐচ্ছিক)', _geminiApiKeyCtrl, 1),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('আপনার ব্যবসার তথ্য সেভ হয়েছে!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Save Business Info'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    int maxLines,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantAlertsTab(List<MessageItem> importantAlerts) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'শুধুমাত্র জরুরি (Important) মেসেজের নোটিফিকেশন তালিকা',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (importantAlerts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('কোনো জরুরি নোটিফিকেশন নেই।')),
          )
        else
          ...importantAlerts.map((m) => _buildMessageCard(m)),
      ],
    );
  }
}
