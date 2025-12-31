
import 'package:flutter/foundation.dart';
import '../models/food_item.dart';
import '../data/database_helper.dart';
import '../utils/notification_helper.dart';

enum SortType {
  expiryAsc,
  expiryDesc,
  manual,
}

class FoodListViewModel extends ChangeNotifier {
  List<FoodItem> _items = [];
  bool _isLoading = false;
  SortType _sortType = SortType.expiryAsc;

  List<FoodItem> get items => _items;
  bool get isLoading => _isLoading;
  SortType get sortType => _sortType;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await DatabaseHelper.instance.readAllFoodItems();
      _applySort();
    } catch (e) {
      debugPrint('Error loading items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void sortItems(SortType type) {
    _sortType = type;
    _applySort();
    notifyListeners();
  }

  void _applySort() {
    switch (_sortType) {
      case SortType.expiryAsc:
        _items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
      case SortType.expiryDesc:
        _items.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
        break;
      case SortType.manual:
        _items.sort((a, b) {
          if (a.orderIndex == null && b.orderIndex == null) return 0;
          if (a.orderIndex == null) return 1;
          if (b.orderIndex == null) return -1;
          return a.orderIndex!.compareTo(b.orderIndex!);
        });
        break;
    }
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final FoodItem item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);

    // Automatically switch to manual sort
    _sortType = SortType.manual;

    // Update indices in DB
    for (int i = 0; i < _items.length; i++) {
      final updatedItem = _items[i].copyWith(orderIndex: i);
      _items[i] = updatedItem;
      await DatabaseHelper.instance.update(updatedItem);
    }
    notifyListeners();
  }

  Future<void> addItem(FoodItem item) async {
    try {
      // If manual sort, add to end with max index
      int? newOrderIndex;
      if (_sortType == SortType.manual && _items.isNotEmpty) {
        final maxIndex = _items.map((e) => e.orderIndex ?? 0).reduce((a, b) => a > b ? a : b);
        newOrderIndex = maxIndex + 1;
      }

      final newItem = await DatabaseHelper.instance.create(
        item.copyWith(orderIndex: newOrderIndex)
      );
      
      _items.add(newItem);
      if (_sortType != SortType.manual) {
        _applySort();
      }
      
      await NotificationHelper().scheduleExpiryNotification(newItem);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding item: $e');
    }
  }

  Future<void> updateItemIcon(FoodItem item, String newIcon) async {
    try {
      final updatedItem = item.copyWith(customIcon: newIcon);
      await DatabaseHelper.instance.update(updatedItem);
      
      final index = _items.indexWhere((element) => element.id == item.id);
      if (index != -1) {
        _items[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating icon: $e');
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      final itemToDelete = _items.firstWhere((item) => item.id == id);
      
      await DatabaseHelper.instance.delete(id);
      _items.removeWhere((item) => item.id == id);
      
      await NotificationHelper().cancelConfigurations(id, itemToDelete.notificationSettings);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting item: $e');
    }
  }
}
