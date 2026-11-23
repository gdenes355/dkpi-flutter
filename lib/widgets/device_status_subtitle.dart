import 'package:dkpi/models/ac_state.dart';
import 'package:dkpi/models/device.dart';
import 'package:dkpi/models/device_status.dart';
import 'package:dkpi/models/device_type.dart';
import 'package:flutter/material.dart';

class DeviceStatusSubtitle extends StatelessWidget {
  final Device device;
  final DeviceStatus? status;
  final bool loading;
  const DeviceStatusSubtitle({
    super.key,
    required this.device,
    required this.status,
    this.loading = false,
  });

  /// Muted style for a target temperature while the device is off.
  static TextStyle _subtle(BuildContext context) => TextStyle(
    color: Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
  );

  /// "→ 22°C" with a vertically centred arrow icon; muted when [on] is false.
  static List<InlineSpan> _targetSpans(
    BuildContext context, {
    required String target,
    required bool on,
    required bool leadingGap,
  }) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final subtle = _subtle(context);
    return [
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: EdgeInsets.only(left: leadingGap ? 4 : 0, right: 4),
          child: Icon(
            Icons.arrow_forward,
            size: (defaultStyle.fontSize ?? 14) * 0.9,
            color: on ? defaultStyle.color : subtle.color,
          ),
        ),
      ),
      TextSpan(text: target, style: on ? null : subtle),
    ];
  }

  /// 18.0 -> "18", 20.54 -> "20.5".
  static String _formatTemp(double t) {
    final rounded = (t * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.round().toString()
        : rounded.toStringAsFixed(1);
  }

  Widget _buildAc(BuildContext context, AcState ac) {
    final indoor = ac.indoorTemperature;
    final outdoor = ac.outdoorTemperature;
    final target = ac.temperature;
    final on = status?.on ?? ac.on ?? false;

    final spans = <InlineSpan>[];
    if (indoor != null) {
      spans.add(TextSpan(text: '$indoor°C'));
      if (outdoor != null) spans.add(TextSpan(text: ' ($outdoor°C)'));
    }
    if (target != null) {
      spans.addAll(
        _targetSpans(
          context,
          target: '$target°C',
          on: on,
          leadingGap: spans.isNotEmpty,
        ),
      );
    }
    // Heat and cool are already obvious from the icon colour (orange / blue).
    if (on &&
        ac.mode != null &&
        ac.mode != AcMode.heat &&
        ac.mode != AcMode.cool) {
      spans.add(TextSpan(text: '  ${ac.mode!.label}'));
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (device.deviceType == DeviceType.toshibaHomeAc) {
      if (loading) return const Text('Loading more data');
      final ac = status?.additionalData?.acState;
      return ac == null ? const SizedBox.shrink() : _buildAc(context, ac);
    }

    final hasAdditionalFields =
        device.additionalData?.fields?.isNotEmpty ?? false;
    if (!hasAdditionalFields) return const SizedBox.shrink();

    if (loading) return const Text('Loading more data');

    if (status?.additionalData == null) return const SizedBox.shrink();

    final data = status!.additionalData!;
    final unit = data.temperatureUnitSymbol;
    final temp = data.temperature;
    final target = data.targetTemperature;
    final humidity = data.humidity;
    final heating = data.heatingOn == true;

    final spans = <InlineSpan>[];
    if (temp != null) spans.add(TextSpan(text: '${_formatTemp(temp)}$unit'));
    if (target != null) {
      spans.addAll(
        _targetSpans(
          context,
          target: '${_formatTemp(target)}$unit',
          on: status!.on,
          leadingGap: spans.isNotEmpty,
        ),
      );
    }
    if (humidity != null) {
      spans.add(
        TextSpan(text: '${spans.isEmpty ? '' : '  '}H${humidity.round()}%'),
      );
    }
    if (heating) {
      spans.add(
        const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.local_fire_department,
              size: 16,
              color: Colors.deepOrange,
              semanticLabel: 'Heating',
            ),
          ),
        ),
      );
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
