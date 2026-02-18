import 'package:flutter/material.dart';
import '../models/car.dart';

class CarBrandCard extends StatelessWidget {
  final CarBrand brand;
  final bool isSelected;
  final VoidCallback onTap;

  const CarBrandCard({
    Key? key,
    required this.brand,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF795548) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF795548) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF795548).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFFFAF6F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.directions_car,
                color: isSelected ? Colors.white : const Color(0xFF795548),
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              brand.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF3E2723),
              ),
            ),
            if (brand.country != null)
              Text(
                brand.country!,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? Colors.white70 : Colors.grey.shade500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
