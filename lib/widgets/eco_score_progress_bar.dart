import 'package:flutter/material.dart';

class EcoScoreProgressBar extends StatelessWidget {
  final double ecoScore;

  const EcoScoreProgressBar({super.key, required this.ecoScore});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('🌱 Eco Score'),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: ecoScore / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(
              ecoScore > 70
                  ? Colors.green
                  : ecoScore > 40
                  ? Colors.orange
                  : Colors.red,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(ecoScore.toStringAsFixed(0)),
      ],
    );
  }
}
