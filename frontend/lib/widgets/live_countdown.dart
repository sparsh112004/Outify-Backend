import 'dart:async';
import 'package:flutter/material.dart';

class LiveCountdown extends StatefulWidget {
  final DateTime targetTime;
  final String label;

  const LiveCountdown({
    super.key,
    required this.targetTime,
    required this.label,
  });

  @override
  State<LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<LiveCountdown> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    setState(() {
      _timeLeft = widget.targetTime.difference(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.isNegative) {
      return Card(
        color: Colors.red.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.red)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'OVERDUE: You were expected back at ${widget.targetTime.hour}:${widget.targetTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hours = _timeLeft.inHours;
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(widget.label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeUnit(hours.toString().padLeft(2, '0'), 'HRS'),
                _buildDivider(),
                _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'MIN'),
                _buildDivider(),
                _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'SEC'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        ':',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
      ),
    );
  }
}
