import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../utils/food_icon_detector.dart';

class FoodItemTile extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onDelete;
  final VoidCallback onIconTap;
  final int index;
  final bool showDragHandle;

  const FoodItemTile({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onIconTap,
    required this.index,
    this.showDragHandle = false,
  });

  Color _getStatusColor(DateTime expiry) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    final diff = expiryDay.difference(today).inDays;

    if (diff < 0) return Colors.red; // Expired
    if (diff == 0) return Colors.redAccent; // Today
    if (diff <= 2) return Colors.orange; // Soon
    return Colors.green; // Safe
  }

  String _getDaysLeftText(DateTime expiry) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    final diff = expiryDay.difference(today).inDays;

    if (diff < 0) return '期限切れ';
    if (diff == 0) return '今日まで';
    return 'あと $diff 日';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final statusColor = _getStatusColor(item.expiryDate);
    final displayIcon = FoodIconDetector.getIcon(item.name, item.category, customIcon: item.customIcon);

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Drag handle (only shown in manual mode)
            if (showDragHandle)
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.drag_handle, color: Colors.grey[400]),
                ),
              ),
            InkWell(
              onTap: onIconTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    displayIcon,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '期限: ${dateFormat.format(item.expiryDate)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getDaysLeftText(item.expiryDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
