import 'package:flutter/material.dart';

class Metric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? color;

  const Metric({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.grey)),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        if (unit.isNotEmpty)
          Text(unit, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
