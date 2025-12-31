
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
    
    // Split by lines and filter
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String text = line.text.trim();
        
        // Filter out obvious noise (prices, phone numbers, short text)
        // This logic needs to be refined heavily based on real receipts
        if (text.length < 2) continue;
        if (RegExp(r'^[0-9¥￥,\.\s]+$').hasMatch(text)) continue; // Only numbers/prices
        if (text.contains('合計') || text.contains('お釣り') || text.contains('レシート')) continue;
        if (text.contains('TEL') || text.contains('電話')) continue;

        candidates.add(text);
      }
    }
    return candidates;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
