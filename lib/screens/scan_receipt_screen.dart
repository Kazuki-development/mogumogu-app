
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/ocr_service.dart';
import 'receipt_preview_screen.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final _ocrService = OCRService();
  final _picker = ImagePicker();
  bool _isScanning = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _isScanning = true);
        final items = await _ocrService.scanReceipt(pickedFile.path);
        
        if (!mounted) return;

        setState(() => _isScanning = false);

        if (items.isNotEmpty) {
           Navigator.pushReplacement(
             context,
             MaterialPageRoute(
               builder: (context) => ReceiptPreviewScreen(scannedLines: items),
             ),
           );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('読み取れる文字が見つかりませんでした')),
           );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('画像の読み込みに失敗しました')),
        );
      }
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('レシートの読み取り')),
      body: _isScanning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text('レシートを解析中...'),
                ],
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long, size: 80, color: Colors.orange),
                const SizedBox(height: 24),
                const Text(
                  'レシートを撮影または選択してください',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('カメラで撮影'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('画像を選択'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
