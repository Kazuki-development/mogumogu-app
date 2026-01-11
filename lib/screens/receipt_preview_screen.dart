
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../utils/food_icon_detector.dart';
import '../viewmodels/food_list_view_model.dart';
// unused import removed

class ReceiptPreviewScreen extends StatefulWidget {
  final List<String> scannedLines;

  const ReceiptPreviewScreen({super.key, required this.scannedLines});

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  late List<FoodItem> _candidates;
  late List<bool> _selected;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _parseCandidates();
  }

  void _parseCandidates() {
    _candidates = widget.scannedLines.map((text) {
      // 1. Guess Icon first (using 'other' as dummy category to trigger name-based matching)
      String icon = FoodIconDetector.getIcon(text, FoodCategory.other);
      
      // 2. Guess Category based on Icon
      FoodCategory category = _guessCategoryFromIcon(icon);
      
      // 3. Determine default expiry based on category
      int days = _getDefaultExpiryDays(category);

      return FoodItem(
        name: text,
        category: category,
        purchaseDate: DateTime.now(),
        expiryDate: DateTime.now().add(Duration(days: days)),
        customIcon: icon,
      );
    }).toList();

    _selected = List.generate(_candidates.length, (index) => true);
  }

  FoodCategory _guessCategoryFromIcon(String icon) {
    for (var entry in FoodIconDetector.categorizedIcons.entries) {
      if (entry.value.contains(icon)) {
        if (entry.key.contains('野菜')) return FoodCategory.vegetable;
        if (entry.key.contains('フルーツ')) return FoodCategory.vegetable; // or other? Model has vegetable/fruit merged? No, model has limited categories.
        if (entry.key.contains('肉')) return FoodCategory.meat;
        if (entry.key.contains('魚')) return FoodCategory.meat; // Fish usually short life
        if (entry.key.contains('パン')) return FoodCategory.pantry; // or other
        if (entry.key.contains('乳製品')) return FoodCategory.dairy;
        if (entry.key.contains('お菓子')) return FoodCategory.pantry;
        if (entry.key.contains('飲み物')) return FoodCategory.other;
      }
    }
    // Fallback logic if icon is generic or not found in picker lists
    if (icon == '🥩' || icon == '🍗' || icon == '🐖') return FoodCategory.meat;
    if (icon == '🐟' || icon == '🍣') return FoodCategory.meat;
    if (icon == '🥛' || icon == '🧀' || icon == '🥚') return FoodCategory.dairy;
    if (icon == '🥦' || icon == '🥬' || icon == '🥕') return FoodCategory.vegetable;
    
    return FoodCategory.other;
  }

  int _getDefaultExpiryDays(FoodCategory category) {
    switch (category) {
      case FoodCategory.meat: return 3;
      case FoodCategory.dairy: return 7;
      case FoodCategory.vegetable: return 5; // A bit shorter than 7
      case FoodCategory.frozen: return 30;
      case FoodCategory.pantry: return 60;
      case FoodCategory.other: return 14;
    }
  }

  Future<void> _saveSelectedItems() async {
    setState(() => _isSaving = true);
    
    final viewModel = Provider.of<FoodListViewModel>(context, listen: false);
    List<FoodItem> itemsToAdd = [];
    
    for (int i = 0; i < _candidates.length; i++) {
      if (_selected[i]) {
        itemsToAdd.add(_candidates[i]);
      }
    }

    if (itemsToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登録する商品が選択されていません')),
      );
      setState(() => _isSaving = false);
      return;
    }

    await viewModel.addItems(itemsToAdd);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${itemsToAdd.length}件の食材を追加しました！')),
      );
      Navigator.pop(context); // Close preview
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('レシート登録確認'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveSelectedItems,
            tooltip: '一括登録',
          ),
        ],
      ),
      body: _candidates.isEmpty
          ? const Center(child: Text('読み取れる商品がありませんでした'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '${_candidates.length}件検出しました。\n不要なものはチェックを外してください。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _candidates.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _candidates[index];
                      return CheckboxListTile(
                        value: _selected[index],
                        secondary: Text(
                          item.customIcon ?? '📦',
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: TextField(
                          controller: TextEditingController(text: item.name),
                          maxLength: 50, // Limit input length
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: "", // Hide counter
                          ),
                          onChanged: (val) {
                            _candidates[index] = item.copyWith(name: val);
                          },
                        ),
                        subtitle: Text(_getCategoryName(item.category)),
                        onChanged: (bool? value) {
                          setState(() {
                            _selected[index] = value ?? false;
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_alt),
                      label: Text(_isSaving ? '保存中...' : 'チェックした商品を登録'),
                      onPressed: _isSaving ? null : _saveSelectedItems,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _getCategoryName(FoodCategory c) {
    switch (c) {
      case FoodCategory.meat: return '肉・魚';
      case FoodCategory.dairy: return '卵・乳製品';
      case FoodCategory.vegetable: return '野菜・果物';
      case FoodCategory.frozen: return '冷凍食品';
      case FoodCategory.pantry: return '常温・調味料';
      case FoodCategory.other: return 'その他';
    }
  }
}
