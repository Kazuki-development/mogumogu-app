
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../viewmodels/food_list_view_model.dart';
import '../widgets/food_item_tile.dart';
import '../utils/food_icon_detector.dart'; // Import for preset icons
import 'add_item_screen.dart';
import 'scan_receipt_screen.dart';

import '../widgets/ad_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showIconSelectionDialog(BuildContext context, FoodItem item, FoodListViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) {
        final categories = FoodIconDetector.categorizedIcons;
        return AlertDialog(
          title: const Text('アイコンを変更'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, categoryIndex) {
                final categoryName = categories.keys.elementAt(categoryIndex);
                final icons = categories[categoryName]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        categoryName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: icons.length,
                      itemBuilder: (context, iconIndex) {
                        final icon = icons[iconIndex];
                        return InkWell(
                          onTap: () {
                            viewModel.updateItemIcon(item, icon);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                icon,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'もぐもぐ',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text('MoguMogu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        centerTitle: true,
        actions: [
          // Sorting Menu
          Consumer<FoodListViewModel>(
            builder: (context, viewModel, child) => PopupMenuButton<SortType>(
              icon: const Icon(Icons.sort, color: Color(0xFFFF9800)),
              onSelected: (SortType result) {
                viewModel.sortItems(result);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<SortType>>[
                PopupMenuItem<SortType>(
                  value: SortType.expiryAsc,
                  child: Row(
                    children: [
                      if (viewModel.sortType == SortType.expiryAsc) const Icon(Icons.check, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text('期限が近い順'),
                    ],
                  ),
                ),
                PopupMenuItem<SortType>(
                  value: SortType.expiryDesc,
                  child: Row(
                    children: [
                       if (viewModel.sortType == SortType.expiryDesc) const Icon(Icons.check, size: 16, color: Colors.orange),
                       const SizedBox(width: 8),
                       const Text('期限が遠い順'),
                    ],
                  ),
                ),
                PopupMenuItem<SortType>(
                  value: SortType.manual,
                   child: Row(
                    children: [
                       if (viewModel.sortType == SortType.manual) const Icon(Icons.check, size: 16, color: Colors.orange),
                       const SizedBox(width: 8),
                       const Text('カスタム順'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF9800)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddItemScreen()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Consumer<FoodListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                     padding: const EdgeInsets.all(32),
                     decoration: BoxDecoration(
                       color: Colors.orange[50],
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(
                       Icons.kitchen,
                       size: 80,
                       color: Color(0xFFFF9800),
                     ),
                   ),
                  const SizedBox(height: 24),
                  Text(
                    '冷蔵庫は空っぽです',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'レシートを撮影して\n食材を追加しましょう！',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 80),
            onReorder: (int oldIndex, int newIndex) {
              viewModel.reorderItems(oldIndex, newIndex);
            },
            buildDefaultDragHandles: false, // We provide custom drag handles
            itemCount: viewModel.items.length,
            itemBuilder: (context, index) {
              final item = viewModel.items[index];
              return FoodItemTile(
                key: ValueKey(item.id),
                item: item,
                index: index,
                showDragHandle: viewModel.sortType == SortType.manual,
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('削除の確認'),
                        content: Text('「${item.name}」を削除してもよろしいですか？'),
                        actions: [
                          TextButton(
                            child: const Text('キャンセル'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: const Text('削除', style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              viewModel.deleteItem(item.id!);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                onIconTap: () => _showIconSelectionDialog(context, item, viewModel),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const SafeArea(
        child: AdBanner(),
      ),
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          heroTag: 'scan',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScanReceiptScreen()),
            );
          },
          backgroundColor: const Color(0xFFFF9800),
          child: const Icon(Icons.camera_alt, size: 32, color: Colors.white),
        ),
      ),
    );
  }
}
