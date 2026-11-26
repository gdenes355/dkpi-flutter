import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dkpi/api/api_client.dart';
import 'package:dkpi/models/device.dart';
import 'package:dkpi/models/device_log.dart';
import 'package:dkpi/models/device_type.dart';
import 'package:dkpi/models/tuya_device_type.dart';
import 'package:dkpi/widgets/history_chart.dart';

/// The time window shown, and the bucket size it is aggregated into.
enum HistoryPeriod {
  day('Day', Duration(days: 1), LogGranularity.raw),
  week('Week', Duration(days: 7), LogGranularity.hour),
  month('Month', Duration(days: 30), LogGranularity.day),
  year('Year', Duration(days: 364), LogGranularity.week);

  const HistoryPeriod(this.label, this.span, this.granularity);
  final String label;
  final Duration span;
  final LogGranularity granularity;

  /// Min-max bands only make sense when a bucket holds many readings (not raw or hourly).
  bool get showRange => granularity == LogGranularity.day || granularity == LogGranularity.week;
}

/// Device picker value for the multi-device temperature comparison.
const _compareId = '__compare__';

/// Line colours for the comparison chart, picked by device order.
const _compareColors = [
  Colors.deepOrange,
  Colors.blue,
  Colors.green,
  Colors.purple,
  Colors.brown,
  Colors.pink,
  Colors.cyan,
  Colors.indigo,
];

class HistoryPage extends StatefulWidget {
  /// Device to show first; defaults to the first device with data.
  final String? initialDeviceId;

  const HistoryPage({super.key, this.initialDeviceId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  HistoryPeriod _period = HistoryPeriod.week;

  /// How many periods back from now: 0 is the latest one.
  int _offset = 0;
  String? _deviceId;
  late DateTime _now;
  late DateTime _start;
  late DateTime _end;
  late Future<DeviceLog> _future;

  /// Current device list, only used to tell Tuya subtypes apart in the labels.
  Map<String, Device> _knownDevices = {};

  /// Devices unticked in the comparison chart.
  final Set<String> _hiddenInCompare = {};
  bool _logging = false;

  @override
  void initState() {
    super.initState();
    _deviceId = widget.initialDeviceId;
    _now = DateTime.now();
    _load();
    ApiClient.getDevices().then((devices) {
      if (mounted) setState(() => _knownDevices = {for (final d in devices) d.id: d});
    }).catchError((_) {}); // labels just stay less specific
  }

  Future<void> _logNow() async {
    setState(() => _logging = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await ApiClient.logDevicesNow();
      messenger.showSnackBar(SnackBar(content: Text('Stored $count readings')));
      if (mounted) _refresh();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  String _typeLabel(DeviceLogSeries d) {
    final known = _knownDevices[d.id];
    if (d.deviceType == DeviceType.tuya && known?.additionalData?.tuyaDeviceType == TuyaDeviceType.thermostat) {
      return 'Tuya thermostat';
    }
    return d.deviceType?.label ?? known?.deviceType?.label ?? '';
  }

  void _load() {
    _end = _now.subtract(_period.span * _offset);
    _start = _end.subtract(_period.span);
    _future = ApiClient.getDeviceLog(start: _start, end: _end, granularity: _period.granularity);
  }

  void _update(VoidCallback change) => setState(() {
        change();
        _load();
      });

  void _setPeriod(HistoryPeriod period) => _update(() {
        _period = period;
        _offset = 0;
      });

  void _refresh() => _update(() {
        _now = DateTime.now();
        _offset = 0;
      });

  String _rangeLabel() {
    final sameYear = _start.year == _end.year && _end.year == DateTime.now().year;
    final f = _period == HistoryPeriod.day
        ? DateFormat('MMM d HH:mm')
        : sameYear
            ? DateFormat('MMM d')
            : DateFormat('MMM d, y');
    return '${f.format(_start)} – ${f.format(_end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('History'),
        actions: [
          IconButton(
            icon: _logging
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add_chart),
            tooltip: 'Take a reading now',
            onPressed: _logging ? null : _logNow,
          ),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: _refresh),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SegmentedButton<HistoryPeriod>(
              segments: [
                for (final p in HistoryPeriod.values) ButtonSegment(value: p, label: Text(p.label)),
              ],
              selected: {_period},
              showSelectedIcon: false,
              onSelectionChanged: (s) => _setPeriod(s.first),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous ${_period.label.toLowerCase()}',
                onPressed: () => _update(() => _offset++),
              ),
              Expanded(
                child: Text(
                  _rangeLabel(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next ${_period.label.toLowerCase()}',
                onPressed: _offset == 0 ? null : () => _update(() => _offset--),
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<DeviceLog>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Failed to load history:\n${snapshot.error}', textAlign: TextAlign.center),
                    ),
                  );
                }
                return _buildContent(snapshot.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DeviceLog log) {
    final devices = log.devices.where((d) => d.points.isNotEmpty).toList();
    if (devices.isEmpty) {
      return const Center(child: Text('No readings in this period'));
    }
    final comparable = devices.where((d) => d.points.any((p) => p.temperature != null)).toList();
    final comparing = _deviceId == _compareId && comparable.isNotEmpty;
    final device = devices.firstWhere((d) => d.id == _deviceId, orElse: () => devices.first);
    final charts = comparing ? _compareCharts(comparable) : _chartsFor(device);
    final secondary = Theme.of(context).textTheme.bodySmall?.color;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButtonFormField<String>(
            // initialValue is only read on creation, so rebuild if the fallback device changes
            key: ValueKey(comparing ? _compareId : device.id),
            initialValue: comparing ? _compareId : device.id,
            decoration: const InputDecoration(labelText: 'Device', border: OutlineInputBorder(), isDense: true),
            items: [
              if (comparable.length > 1)
                const DropdownMenuItem(
                  value: _compareId,
                  child: Row(children: [
                    Icon(Icons.stacked_line_chart, size: 18),
                    SizedBox(width: 8),
                    Text('Compare temperatures'),
                  ]),
                ),
              for (final d in devices)
                DropdownMenuItem(
                  value: d.id,
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: d.name),
                    TextSpan(text: '  ${_typeLabel(d)}', style: TextStyle(color: secondary, fontSize: 12)),
                  ])),
                ),
            ],
            // Only changes which series is shown, so no reload needed
            onChanged: (id) => setState(() => _deviceId = id),
          ),
        ),
        if (charts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('This device has no chartable readings in this period')),
          ),
        ...charts,
      ],
    );
  }

  /// One temperature chart with a line per device, plus chips to hide devices.
  List<Widget> _compareCharts(List<DeviceLogSeries> devices) {
    final colors = {for (var i = 0; i < devices.length; i++) devices[i].id: _compareColors[i % _compareColors.length]};
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Wrap(
          spacing: 6,
          children: [
            for (final d in devices)
              FilterChip(
                label: Text(d.name),
                avatar: CircleAvatar(backgroundColor: colors[d.id], radius: 6),
                showCheckmark: false,
                selected: !_hiddenInCompare.contains(d.id),
                onSelected: (on) => setState(() => on ? _hiddenInCompare.remove(d.id) : _hiddenInCompare.add(d.id)),
              ),
          ],
        ),
      ),
      HistoryChart(
        title: _period.showRange ? 'Average temperature' : 'Temperature',
        unit: '°',
        start: _start,
        end: _end,
        bucket: _period.granularity.bucket,
        showLegend: false, // the chips above are the legend
        lines: [
          for (final d in devices)
            if (!_hiddenInCompare.contains(d.id))
              ChartLine(
                label: d.name,
                color: colors[d.id]!,
                values: [for (final p in d.points) ChartValue(p.ts, p.temperature)],
              ),
        ],
      ),
    ];
  }

  List<Widget> _chartsFor(DeviceLogSeries device) {
    final pts = device.points;
    final range = _period.showRange;

    List<ChartValue> values(double? Function(DeviceLogPoint) value,
            [double? Function(DeviceLogPoint)? min, double? Function(DeviceLogPoint)? max]) =>
        [
          for (final p in pts)
            ChartValue(p.ts, value(p), min: min?.call(p), max: max?.call(p)),
        ];
    double? percent(double? ratio) => ratio == null ? null : ratio * 100;

    HistoryChart chart(String title, String unit, List<ChartLine> lines,
            {double? minY, double? maxY, int fractionDigits = 1}) =>
        HistoryChart(
          title: title,
          unit: unit,
          lines: lines,
          start: _start,
          end: _end,
          bucket: _period.granularity.bucket,
          minY: minY,
          maxY: maxY,
          fractionDigits: fractionDigits,
        );

    final temperature = [
      ChartLine(
        label: 'Temperature',
        color: Colors.deepOrange,
        values: values((p) => p.temperature, (p) => p.temperatureMin, (p) => p.temperatureMax),
        showRange: range,
      ),
      ChartLine(
        label: 'Target',
        color: Colors.blueGrey,
        values: values((p) => p.targetTemperature),
        dashed: true,
      ),
      ChartLine(
        label: 'Outdoor',
        color: Colors.teal,
        values: values((p) => p.outdoorTemperature),
      ),
    ];
    final humidity = [
      ChartLine(
        label: 'Humidity',
        color: Colors.blue,
        values: values((p) => p.humidity, (p) => p.humidityMin, (p) => p.humidityMax),
        showRange: range,
      ),
    ];
    // Raw readings are plain on/off states, so draw them as steps
    final raw = _period.granularity == LogGranularity.raw;
    final activity = [
      ChartLine(label: 'On', color: Colors.amber.shade700, values: values((p) => percent(p.onRatio)), step: raw),
      ChartLine(label: 'Heating', color: Colors.red, values: values((p) => percent(p.heatingOnRatio)), step: raw),
    ];

    return [
      if (temperature.any((l) => l.hasData)) chart('Temperature', '°', temperature),
      if (humidity.any((l) => l.hasData)) chart('Humidity', '%', humidity, fractionDigits: 0),
      if (activity.any((l) => l.hasData))
        chart(raw ? 'On / heating' : 'Share of time on', '%', activity, minY: 0, maxY: 100, fractionDigits: 0),
    ];
  }
}
