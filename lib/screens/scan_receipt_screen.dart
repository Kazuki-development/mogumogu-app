
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/ocr_service.dart';
import 'add_item_screen.dart'; // We might want a bulk add screen later, but for now reuse or simpler logic

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final _ocrService = OCRService();
  final _picker = ImagePicker();
  bool _isScanning = false;
  List<String> _detectedItems = [];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _isScanning = true);
        final items = await _ocrService.scanReceipt(pickedFile.path);
        setState(() {
          _detectedItems = items;
          _isScanning = false;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      setState(() => _isScanning = false);
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('カメラで撮影'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('画像を選択'),
                ),
              ],
            ),
          ),
          if (_isScanning)
            const LinearProgressIndicator()
          else if (_detectedItems.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _detectedItems.length,
                itemBuilder: (context, index) {
                  final text = _detectedItems[index];
                  return ListTile(
                    title: Text(text),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                      onPressed: () {
                        // Navigate to Add Item Screen with pre-filled name
                        // Here we could pass the name to the AddItemScreen
                        // For simplicity, let's assume AddItemScreen can accept arguments (need to update it)
                        // Or just show a dialog to quick add.
                        _showQuickAddDialog(text);
                      },
                    ),
                  );
                },
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text('レシートを撮影して商品を追加しましょう'),
              ),
            ),
        ],
      ),
    );
  }

  void _showQuickAddDialog(String name) {
    // This is a simplified flow. Ideally we go to the full edit screen.
    // But for "Magic", let's try to guess category?
    // Doing a simple dialog for now.
    TextEditingController nameCtrl = TextEditingController(text: name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('商品を追加'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: '商品名'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
               // Logic to add item (default category: other)
               // This is incomplete as we need category logic.
               // Better to navigate to AddItemScreen.
               Navigator.pop(context);
               Navigator.push(
                 context, 
                 MaterialPageRoute(
                   builder: (context) => AddItemScreen(initialName: nameCtrl.text) // Need to update AddItemScreen
                 )
               );
            },
            child: const Text('詳細設定へ'),
          ),
        ],
      ),
    );
  }
}
