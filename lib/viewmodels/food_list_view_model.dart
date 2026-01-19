
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _autoDeleteEnabled = false;

  List<FoodItem> get items => _items;
  bool get isLoading => _isLoading;
  SortType get sortType => _sortType;
  bool get autoDeleteEnabled => _autoDeleteEnabled;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _autoDeleteEnabled = prefs.getBool('auto_delete_expired') ?? false;

      _items = await DatabaseHelper.instance.readAllFoodItems();
      
      if (_autoDeleteEnabled) {
        await _deleteExpiredItemsInternal();
      }

      _applySort();
      // Reschedule all notifications on startup to ensure they are registered with the correct channel
      await NotificationHelper().rescheduleAllNotifications(_items);
    } catch (e) {
      debugPrint('Error loading items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setAutoDeleteEnabled(bool value) async {
    _autoDeleteEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_delete_expired', value);
    notifyListeners();

    if (value) {
      await _deleteExpiredItemsInternal();
      notifyListeners();
    }
  }

  Future<void> _deleteExpiredItemsInternal() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final expiredIds = _items.where((item) {
      final expiryDay = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);
      return expiryDay.isBefore(today); // < today means yesterday or older
    }).map((e) => e.id!).toList();

    if (expiredIds.isNotEmpty) {
      await deleteItems(expiredIds);
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

  Future<void> addItems(List<FoodItem> items) async {
    bool somethingAdded = false;
    try {
      // Calculate start index for manual sort
      int currentMaxOrder = 0;
      if (_sortType == SortType.manual && _items.isNotEmpty) {
        currentMaxOrder = _items.map((e) => e.orderIndex ?? 0).reduce((a, b) => a > b ? a : b);
      }

      for (var item in items) {
        int? newOrderIndex;
        if (_sortType == SortType.manual) {
          currentMaxOrder++;
          newOrderIndex = currentMaxOrder;
        }

        final newItem = await DatabaseHelper.instance.create(
          item.copyWith(orderIndex: newOrderIndex)
        );
        _items.add(newItem);
        await NotificationHelper().scheduleExpiryNotification(newItem);
        somethingAdded = true;
      }
      
      if (somethingAdded) {
        if (_sortType != SortType.manual) {
          _applySort();
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding items batch: $e');
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

  Future<void> deleteItems(List<int> ids) async {
    try {
      for (final id in ids) {
         // Optimization: Could use batch delete in DB logic if needed, but loop is fine for local SQLite
         await DatabaseHelper.instance.delete(id);
         
         // Find item to cancel notification
          try {
            final item = _items.firstWhere((e) => e.id == id);
            await NotificationHelper().cancelConfigurations(id, item.notificationSettings);
          } catch (_) {} // Item might not persist in list if race condition, safe to ignore
      }
      _items.removeWhere((item) => ids.contains(item.id));
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting items batch: $e');
    }
  }
}
