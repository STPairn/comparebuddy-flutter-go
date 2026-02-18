import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/car.dart';

class CarVariantCard extends StatelessWidget {
  final CarVariantSummary variant;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const CarVariantCard({
    Key? key,
    required this.variant,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  String _formatPrice(double? price) {
    if (price == null) return 'ไม่ระบุราคา';
    final formatter = NumberFormat.currency(
      locale: 'th_TH',
      symbol: '฿',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF795548).withOpacity(0.08) : const Color(0xFFFAF6F3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF795548) : Colors.grey.shade100,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF795548) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? const Color(0xFF795548) : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatPrice(variant.priceBaht),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF795548),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
