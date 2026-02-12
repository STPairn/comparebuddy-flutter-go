import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';

class ItemCard extends StatelessWidget {
  final Item item;

  const ItemCard({Key? key, required this.item}) : super(key: key);

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'th_TH',
      symbol: '฿',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.brand,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.name,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '⏱ ${item.duration}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '💰 ${_formatPrice(item.price)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              if (item.field.isNotEmpty) ...[
                const SizedBox(width: 16),
                Text(
                  '📚 ${item.field}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
