import 'dart:typed_data';
import 'package:flutter/material.dart';

class FilterPreview extends StatelessWidget {
  final Map<String, dynamic> filter;
  final bool isSelected;
  final VoidCallback onTap;
  final Future<Uint8List> thumbnailFuture;

  const FilterPreview({
    super.key,
    required this.filter,
    required this.isSelected,
    required this.onTap,
    required this.thumbnailFuture,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Hero(
            tag: 'filter_${filter['key']}',
            child: Container(
              width: 65,
              height: 85,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: FutureBuilder<Uint8List>(
                      future: thumbnailFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            child: Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          );
                        }
                        return const Icon(Icons.image, color: Colors.white70, size: 20);
                      },
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black26 : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                    ),
                    child: Text(
                      filter['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
