
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../viewmodels/food_list_view_model.dart';

class AddItemScreen extends StatefulWidget {
  final String? initialName;

  const AddItemScreen({super.key, this.initialName});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  DateTime _purchaseDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 3)); 
  FoodCategory _selectedCategory = FoodCategory.other;

  // Notification State
  final List<int> _selectedNotificationDays = [1];
  final Map<int, String> _notificationPresets = {
    7: '1週間前',
    3: '3日前',
    1: '前日',
    0: '当日',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleNotificationDay(int days) {
    setState(() {
      if (_selectedNotificationDays.contains(days)) {
        if (_selectedNotificationDays.length > 1) { 
          _selectedNotificationDays.remove(days);
        }
      } else {
        _selectedNotificationDays.add(days);
      }
      _selectedNotificationDays.sort((a, b) => b.compareTo(a)); 
    });
  }

  Future<void> _showCustomNotificationDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カスタム通知'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '何日前に通知しますか？', suffixText: '日前'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              final days = int.tryParse(controller.text);
              if (days != null && days >= 0) {
                _toggleNotificationDay(days);
                Navigator.pop(context);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isPurchaseDate) async {
    final initialDate = isPurchaseDate ? _purchaseDate : _expiryDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isPurchaseDate) {
          _purchaseDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  void _onCategoryChanged(FoodCategory newCategory) {
    setState(() {
      _selectedCategory = newCategory;
      int daysToAdd = 0;
      switch (newCategory) {
        case FoodCategory.meat: daysToAdd = 3; break;
        case FoodCategory.dairy: daysToAdd = 7; break;
        case FoodCategory.vegetable: daysToAdd = 7; break;
        case FoodCategory.frozen: daysToAdd = 30; break;
        case FoodCategory.pantry: daysToAdd = 60; break;
        case FoodCategory.other: daysToAdd = 7; break;
      }
      _expiryDate = _purchaseDate.add(Duration(days: daysToAdd));
    });
  }

  String _categoryEmoji(FoodCategory category) {
    switch (category) {
      case FoodCategory.meat: return '🥩';
      case FoodCategory.dairy: return '🥛';
      case FoodCategory.vegetable: return '🥦';
      case FoodCategory.frozen: return '🧊';
      case FoodCategory.pantry: return '🥫';
      case FoodCategory.other: return '📦';
    }
  }

  String _categoryToString(FoodCategory category) {
    switch (category) {
      case FoodCategory.meat: return '肉・魚';
      case FoodCategory.dairy: return '乳製品';
      case FoodCategory.vegetable: return '野菜';
      case FoodCategory.frozen: return '冷凍';
      case FoodCategory.pantry: return '調味料';
      case FoodCategory.other: return 'その他';
    }
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final newItem = FoodItem(
        name: _nameController.text,
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate,
        category: _selectedCategory,
        notificationSettings: _selectedNotificationDays,
      );
      
      context.read<FoodListViewModel>().addItem(newItem);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Scaffold(
      appBar: AppBar(title: const Text('食材を追加')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('商品名', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  hintText: '例: 牛乳',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              const Text('カテゴリ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: FoodCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text('${_categoryEmoji(category)} ${_categoryToString(category)}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) _onCategoryChanged(category);
                    },
                    selectedColor: const Color(0xFFFF9800),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : Colors.grey[300]!,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              const Text('日付設定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('購入日', style: TextStyle(color: Colors.grey)),
                          Text(dateFormat.format(_purchaseDate), style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('消費期限', style: TextStyle(color: Colors.grey)),
                          Text(
                            dateFormat.format(_expiryDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF9800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('通知タイミング', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton.icon(
                    onPressed: _showCustomNotificationDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('カスタム'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                   ..._notificationPresets.entries.map((entry) {
                     final isSelected = _selectedNotificationDays.contains(entry.key);
                     return FilterChip(
                       label: Text(entry.value),
                       selected: isSelected,
                       onSelected: (_) => _toggleNotificationDay(entry.key),
                       selectedColor: Colors.orange[100],
                       checkmarkColor: Colors.orange,
                     );
                   }),
                   ..._selectedNotificationDays.where((d) => !_notificationPresets.containsKey(d)).map((d) {
                     return FilterChip(
                       label: Text('$d日前'),
                       selected: true,
                       onSelected: (_) => _toggleNotificationDay(d),
                       selectedColor: Colors.orange[100],
                       checkmarkColor: Colors.orange,
                     );
                   }),
                ],
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('保存する', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
