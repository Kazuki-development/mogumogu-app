
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/material.dart';

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);

  Future<List<String>> scanReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return _parseReceiptText(recognizedText);
    } catch (e) {
      debugPrint('OCR Error: $e');
      return [];
    }
  }

  // Very basic heuristic parser
  List<String> _parseReceiptText(RecognizedText recognizedText) {
    List<String> candidates = [];
    
    // Sort blocks by vertical position to somewhat respect reading order
    List<TextBlock> sortedBlocks = List.from(recognizedText.blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    for (TextBlock block in sortedBlocks) {
      for (TextLine line in block.lines) {
        String text = line.text.trim();
        
        if (_isIgnoredLine(text)) continue;

        // Basic normalization
        text = text.replaceAll(RegExp(r'[\d,¥￥\.]+'), '').trim(); // Remove prices embedded in line
        // Remove leading/trailing symbols
        text = text.replaceAll(RegExp(r'^[\(\)\[\]\-\.\s\*]+'), '').replaceAll(RegExp(r'[\(\)\[\]\-\.\s\*]+$'), '');
        
        if (text.length < 2) continue; // Too short after cleaning

        candidates.add(text);
      }
    }
    return candidates;
  }

  bool _isIgnoredLine(String text) {
    // 1. Phone / Address / Header
    if (RegExp(r'(TEL|FAX|電話|住所|〒|No\.|店|レジ|担当|様|領収|明細|クレジット|カード)').hasMatch(text)) return true;
    
    // 2. Date / Time
    if (RegExp(r'(20\d{2}年|\d{1,2}月\d{1,2}日|\d{1,2}:\d{1,2})').hasMatch(text)) return true;
    
    // 3. Totals / Accounting
    if (RegExp(r'(合計|小計|釣|預|現計|税|対象|値引|割引|内消|商品)').hasMatch(text)) return true; // Added '内消', '商品' (often part of header)

    // 4. Price only lines (heuristic)
    if (RegExp(r'^[\d,¥￥\.\s]+$').hasMatch(text)) return true;
    if (RegExp(r'^[¥￥]?\s*[\d,]+\s*$').hasMatch(text)) return true;

    // 5. Short/Symbol only
    if (RegExp(r'^[\(\)\[\]\-\.\s\*]+$').hasMatch(text)) return true;
    
    return false;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
