
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  late List<TextEditingController> _nameControllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _parseCandidates();
  }

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
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
    _nameControllers = _candidates.map((item) => TextEditingController(text: item.name)).toList();
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
      backgroundColor: Colors.grey[100],
      body: _candidates.isEmpty
          ? const Center(child: Text('読み取れる商品がありませんでした'))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white,
                  width: double.infinity,
                  child: Text(
                    '${_candidates.length}件を自動抽出しました。\n登録する食材を確認・編集してください。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _candidates.length,
                    itemBuilder: (context, index) {
                      return _buildEditTile(index);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSaving 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_alt),
                        label: Text(_isSaving ? '保存中...' : 'チェックした商品を登録'),
                        onPressed: _isSaving ? null : _saveSelectedItems,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEditTile(int index) {
    final item = _candidates[index];
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _selected[index] ? Colors.orange.withValues(alpha: 0.3) : Colors.transparent),
      ),
      color: Colors.white,
      child: Column(
        children: [
          CheckboxListTile(
            value: _selected[index],
            activeColor: const Color(0xFFFF9800),
            secondary: GestureDetector(
              onTap: () => _showIconPicker(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.customIcon ?? '📦',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            title: TextField(
              controller: _nameControllers[index],
              maxLength: 50,
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: "",
                hintText: "商品名を入力",
              ),
              onChanged: (val) {
                _candidates[index] = item.copyWith(name: val);
              },
            ),
            onChanged: (bool? value) {
              setState(() {
                _selected[index] = value ?? false;
              });
            },
          ),
          if (_selected[index]) Padding(
            padding: const EdgeInsets.only(left: 72, right: 16, bottom: 12),
            child: Column(
              children: [
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<FoodCategory>(
                          value: item.category,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          onChanged: (FoodCategory? newCategory) {
                            if (newCategory != null) {
                              setState(() {
                                int days = _getDefaultExpiryDays(newCategory);
                                _candidates[index] = item.copyWith(
                                  category: newCategory,
                                  expiryDate: DateTime.now().add(Duration(days: days)),
                                );
                              });
                            }
                          },
                          items: FoodCategory.values.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(_getCategoryName(c), style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month, size: 16, color: Colors.orange),
                        label: Text(
                          dateFormat.format(item.expiryDate),
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: item.expiryDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 1000)),
                          );
                          if (picked != null) {
                            setState(() {
                              _candidates[index] = item.copyWith(expiryDate: picked);
                            });
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickDateChip(index, "3日", 3),
                      _buildQuickDateChip(index, "1週間", 7),
                      _buildQuickDateChip(index, "2週間", 14),
                      _buildQuickDateChip(index, "1ヶ月", 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateChip(int index, String label, int days) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: false,
        onSelected: (_) {
          setState(() {
            _candidates[index] = _candidates[index].copyWith(
              expiryDate: DateTime.now().add(Duration(days: days)),
            );
          });
        },
        visualDensity: VisualDensity.compact,
        backgroundColor: Colors.grey[100],
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

  void _showIconPicker(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'アイコンを選択',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: FoodIconDetector.categorizedIcons.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: entry.value.map((icon) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _candidates[index] = _candidates[index].copyWith(customIcon: icon);
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _candidates[index].customIcon == icon
                                          ? Colors.orange.withValues(alpha: 0.2)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: _candidates[index].customIcon == icon
                                          ? Border.all(color: Colors.orange, width: 2)
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
