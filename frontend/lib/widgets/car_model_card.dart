import 'package:flutter/material.dart';
import '../models/car.dart';

class CarModelCard extends StatelessWidget {
  final CarModel model;
  final VoidCallback onTap;

  const CarModelCard({
    Key? key,
    required this.model,
    required this.onTap,
  }) : super(key: key);

  Color _powertrainColor(String type) {
    switch (type.toLowerCase()) {
      case 'bev':
        return const Color(0xFF4CAF50);
      case 'phev':
        return const Color(0xFF2196F3);
      case 'hev':
        return const Color(0xFF009688);
      case 'ice':
        return const Color(0xFF795548);
      default:
        return Colors.grey;
    }
  }

  String _powertrainLabel(String type) {
    switch (type.toLowerCase()) {
      case 'bev':
        return 'BEV';
      case 'phev':
        return 'PHEV';
      case 'hev':
        return 'HEV';
      case 'ice':
        return 'ICE';
      default:
        return type.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _powertrainColor(model.powertrainType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6F3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_car, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildBadge(_powertrainLabel(model.powertrainType), color),
                      _buildBadge(model.bodyType, const Color(0xFF8D6E63)),
                      if (model.yearLaunched != null)
                        _buildBadge('${model.yearLaunched}', const Color(0xFFA1887F)),
                    ],
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

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
