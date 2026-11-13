import 'package:flutter/material.dart';

import '../models/short_video.dart';

class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({super.key});

  @override
  State<AddVideoScreen> createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  String? _linkError;
  ParsedVideoLink? _parsedLink;

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _handleLinkChanged(String value) {
    final parsed = ParsedVideoLink.parse(value);
    setState(() {
      _parsedLink = parsed;
      _linkError = null;
    });
  }

  void _save() {
    final link = ParsedVideoLink.parse(_linkController.text);
    if (link == null) {
      setState(() {
        _linkError = ParsedVideoLink.validationMessage(_linkController.text);
      });
      return;
    }

    final typedTitle = _titleController.text.trim();
    final title = typedTitle.isEmpty
        ? 'فيديو ${link.platform.label}'
        : typedTitle;
    Navigator.of(context).pop(ShortVideo.fromLink(title: title, link: link));
  }

  @override
  Widget build(BuildContext context) {
    final platform = _parsedLink?.platform;

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة فيديو')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F0EA),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.link_rounded, color: Color(0xFF246A55), size: 28),
                  SizedBox(height: 12),
                  Text(
                    'اختر ما تريد مشاهدته مسبقًا',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF18231F),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'أضف رابط فيديو مباشر. يبدأ احتساب الحد عند فتحه داخل التطبيق.',
                    style: TextStyle(color: Color(0xFF53635A), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'اسم الفيديو (اختياري)',
                hintText: 'مثال: وصفة سريعة',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _linkController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              textDirection: TextDirection.ltr,
              onChanged: _handleLinkChanged,
              decoration: InputDecoration(
                labelText: 'رابط TikTok أو YouTube',
                hintText: 'https://...',
                hintTextDirection: TextDirection.ltr,
                prefixIcon: const Icon(Icons.play_circle_outline_rounded),
                errorText: _linkError,
              ),
            ),
            const SizedBox(height: 12),
            if (platform != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EFEA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF246A55),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تم التعرف على ${platform.label}',
                      style: const TextStyle(
                        color: Color(0xFF246A55),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text(
                'لرابط TikTok، استخدم رابط الفيديو الكامل الذي يحتوي على /video/.',
                style: TextStyle(
                  color: Color(0xFF727D76),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.add_rounded),
              label: const Text('حفظ الفيديو'),
            ),
          ],
        ),
      ),
    );
  }
}
