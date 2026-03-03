import 'package:flutter/material.dart';

class StatusIconWidget extends StatelessWidget {
  final bool on;
  final bool loading;
  const StatusIconWidget({
    super.key,
    required this.on,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 36, child: Center(child: 
    loading ?
      CircularProgressIndicator(strokeWidth: 2) :
     Icon(
      Icons.lightbulb,
      size: 28,
      color: on ? Colors.amber : Colors.black,
    )));
  }
}