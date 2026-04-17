import 'package:flutter/material.dart';

class StatusTimeline extends StatelessWidget {
  final String status;
  const StatusTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'label': 'Requested', 'key': 'pending_faculty'},
      {'label': 'Faculty Approval', 'key': 'pending_warden'},
      {'label': 'Warden Approval', 'key': 'approved'},
      {'label': 'Out of Campus', 'key': 'out'},
      {'label': 'Completed', 'key': 'completed'},
    ];

    int currentStep = 0;
    if (status == 'pending_warden') currentStep = 1;
    if (status == 'approved') currentStep = 2;
    if (status == 'out') currentStep = 3;
    if (status == 'completed') currentStep = 4;
    if (status.contains('denied') || status == 'cancelled' || status == 'expired') currentStep = -1;

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = currentStep >= index;
        final isLast = index == steps.length - 1;
        final color = isCompleted ? Colors.green : Colors.grey;

        return Row(
          children: [
            Column(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: color,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    color: color.withOpacity(0.5),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              step['label']!,
              style: TextStyle(
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        );
      }),
    );
  }
}
