import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A thermostat-style circular slider: a 270° arc with a gap at the bottom,
/// the selected value in the middle and the current temperature below it.
class CircularTemperatureSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final double step;
  final String unit;
  final double? currentTemperature;
  final ValueChanged<double> onChanged;
  final double size;

  const CircularTemperatureSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.unit = '°C',
    this.currentTemperature,
    this.size = 240,
  });

  // Canvas angles: 0 = 3 o'clock, positive = clockwise.
  static const double _startAngle = 3 * math.pi / 4; // bottom-left
  static const double _sweepAngle = 3 * math.pi / 2; // 270°
  static const double _strokeWidth = 14;
  static const double _thumbRadius = 14;

  double get _radius => size / 2 - _thumbRadius - 2;

  double get _fraction => ((value - min) / (max - min)).clamp(0.0, 1.0);

  void _handle(Offset localPosition, {bool requireNearRing = false}) {
    final center = Offset(size / 2, size / 2);
    final d = localPosition - center;
    // Ignore taps in the middle (the text area) so they don't jump the value.
    if (requireNearRing && d.distance < _radius * 0.6) return;

    var relative = (math.atan2(d.dy, d.dx) - _startAngle) % (2 * math.pi);
    double fraction;
    if (relative <= _sweepAngle) {
      fraction = relative / _sweepAngle;
    } else {
      // In the bottom gap: stick to whichever end we're already near,
      // so dragging through the gap doesn't jump from min to max.
      fraction = _fraction >= 0.5 ? 1 : 0;
    }
    var newValue = min + fraction * (max - min);
    newValue = ((newValue - min) / step).round() * step + min;
    newValue = newValue.clamp(min, max);
    if (newValue != value) onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueText = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return Semantics(
      slider: true,
      label: 'Target temperature',
      value: '$valueText$unit',
      increasedValue: '${(value + step).clamp(min, max)}$unit',
      decreasedValue: '${(value - step).clamp(min, max)}$unit',
      onIncrease: () => onChanged((value + step).clamp(min, max)),
      onDecrease: () => onChanged((value - step).clamp(min, max)),
      child: GestureDetector(
        onTapDown: (details) =>
            _handle(details.localPosition, requireNearRing: true),
        onPanStart: (details) =>
            _handle(details.localPosition, requireNearRing: true),
        onPanUpdate: (details) => _handle(details.localPosition),
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ArcPainter(
              fraction: _fraction,
              radius: _radius,
              trackColor: theme.colorScheme.surfaceContainerHighest,
              activeColor: Colors.orange,
              thumbColor: Colors.white,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        valueText,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(unit, style: theme.textTheme.titleMedium),
                      ),
                    ],
                  ),
                  if (currentTemperature != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Current ${(currentTemperature! * 10).round() / 10}$unit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double fraction;
  final double radius;
  final Color trackColor;
  final Color activeColor;
  final Color thumbColor;

  _ArcPainter({
    required this.fraction,
    required this.radius,
    required this.trackColor,
    required this.activeColor,
    required this.thumbColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const start = CircularTemperatureSlider._startAngle;
    const sweep = CircularTemperatureSlider._sweepAngle;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = CircularTemperatureSlider._strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, track);

    final active = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = CircularTemperatureSlider._strokeWidth
      ..strokeCap = StrokeCap.round;
    if (fraction > 0) {
      canvas.drawArc(rect, start, sweep * fraction, false, active);
    }

    final thumbAngle = start + sweep * fraction;
    final thumbCenter =
        center + Offset(math.cos(thumbAngle), math.sin(thumbAngle)) * radius;
    canvas.drawCircle(
      thumbCenter,
      CircularTemperatureSlider._thumbRadius + 1,
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(
        thumbCenter, CircularTemperatureSlider._thumbRadius, Paint()..color = activeColor);
    canvas.drawCircle(
        thumbCenter, CircularTemperatureSlider._thumbRadius - 4, Paint()..color = thumbColor);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.fraction != fraction ||
      old.radius != radius ||
      old.trackColor != trackColor ||
      old.activeColor != activeColor ||
      old.thumbColor != thumbColor;
}
