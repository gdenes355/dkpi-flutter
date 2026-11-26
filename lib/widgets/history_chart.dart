import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// One value per bucket; null where the device reported nothing.
class ChartValue {
  final DateTime ts;
  final double? value;
  final double? min;
  final double? max;

  const ChartValue(this.ts, this.value, {this.min, this.max});
}

class ChartLine {
  final String label;
  final Color color;
  final List<ChartValue> values;

  /// Shade the min..max range around the line.
  final bool showRange;
  final bool dashed;

  /// Hold each value until the next one (for on/off states) instead of interpolating.
  final bool step;

  const ChartLine({
    required this.label,
    required this.color,
    required this.values,
    this.showRange = false,
    this.dashed = false,
    this.step = false,
  });

  bool get hasData => values.any((v) => v.value != null);
}

/// Line chart over a fixed time window, with optional min-max bands.
class HistoryChart extends StatelessWidget {
  final String title;
  final String unit;
  final List<ChartLine> lines;
  final DateTime start;
  final DateTime end;

  /// Bucket size: gaps longer than this break the line instead of joining across them.
  final Duration bucket;

  /// Fix the y axis (e.g. 0..100 for percentages); otherwise it fits the data.
  final double? minY;
  final double? maxY;
  final int fractionDigits;
  final bool showLegend;

  /// Shown on its own landscape page: the chart fills the space and the button closes it.
  final bool fullscreen;

  const HistoryChart({
    super.key,
    required this.title,
    required this.unit,
    required this.lines,
    required this.start,
    required this.end,
    required this.bucket,
    this.minY,
    this.maxY,
    this.fractionDigits = 1,
    this.showLegend = true,
    this.fullscreen = false,
  });

  /// X position: local wall-clock time as if it were UTC, so that axis ticks (which fall on
  /// multiples of the interval) land on local midnights and whole hours.
  static double _x(DateTime t) {
    final local = t.toLocal();
    return (local.millisecondsSinceEpoch + local.timeZoneOffset.inMilliseconds).toDouble();
  }

  /// Inverse of [_x], for labels: a UTC DateTime holding the local wall-clock time.
  static DateTime _wallClock(double x) => DateTime.fromMillisecondsSinceEpoch(x.toInt(), isUtc: true);

  /// Spots for one series, with null spots where a value is missing or buckets are missing.
  List<FlSpot> _spots(
    List<ChartValue> values,
    double? Function(ChartValue) pick,
  ) {
    final spots = <FlSpot>[];
    DateTime? prev;
    for (final v in values) {
      if (prev != null && v.ts.difference(prev) > bucket * 1.5)
        spots.add(FlSpot.nullSpot);
      final y = pick(v);
      spots.add(y == null ? FlSpot.nullSpot : FlSpot(_x(v.ts), y));
      prev = v.ts;
    }
    return spots;
  }

  /// Time axis: tick interval and label format to suit the window length.
  (Duration, DateFormat) _timeAxis() {
    final span = end.difference(start);
    if (span <= const Duration(days: 2))
      return (const Duration(hours: 3), DateFormat('HH:mm'));
    if (span <= const Duration(days: 8))
      return (const Duration(days: 1), DateFormat('E d'));
    if (span <= const Duration(days: 40))
      return (const Duration(days: 7), DateFormat('MMM d'));
    return (const Duration(days: 61), DateFormat('MMM'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = lines.where((l) => l.hasData).toList();

    final bars = <LineChartBarData>[];
    final betweens = <BetweenBarsData>[];
    // Which bars are the main lines (others are invisible range edges), by bar index.
    final lineForBar = <int, ChartLine>{};
    double lo = double.infinity, hi = double.negativeInfinity;

    for (final line in visible) {
      for (final v in line.values) {
        for (final y in [
          v.value,
          if (line.showRange) v.min,
          if (line.showRange) v.max,
        ]) {
          if (y == null) continue;
          lo = math.min(lo, y);
          hi = math.max(hi, y);
        }
      }
      if (line.showRange &&
          line.values.any((v) => v.min != null && v.max != null)) {
        final edge = LineChartBarData(
          spots: const [],
          color: Colors.transparent,
          barWidth: 0,
          dotData: const FlDotData(show: false),
        );
        bars.add(edge.copyWith(spots: _spots(line.values, (v) => v.min)));
        bars.add(edge.copyWith(spots: _spots(line.values, (v) => v.max)));
        betweens.add(
          BetweenBarsData(
            fromIndex: bars.length - 2,
            toIndex: bars.length - 1,
            color: line.color.withValues(alpha: 0.18),
          ),
        );
      }
      lineForBar[bars.length] = line;
      final spots = _spots(line.values, (v) => v.value);
      final single = spots.where((s) => s != FlSpot.nullSpot).length == 1;
      bars.add(
        LineChartBarData(
          spots: spots,
          color: line.color,
          barWidth: 2,
          isCurved: false,
          dashArray: line.dashed ? [6, 4] : null,
          isStepLineChart: line.step,
          // A lone point has no line to draw, so show it as a dot
          dotData: FlDotData(show: single),
        ),
      );
    }

    final minY = this.minY ?? (lo.isFinite ? (lo - 1).floorToDouble() : 0);
    final maxY = this.maxY ?? (hi.isFinite ? (hi + 1).ceilToDouble() : 1);
    final (tick, tickFormat) = _timeAxis();
    final tooltipFormat = bucket >= const Duration(days: 1)
        ? DateFormat('EEE, MMM d')
        : DateFormat('EEE, MMM d HH:mm');

    return Card(
      margin: fullscreen ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
                IconButton(
                  icon: Icon(fullscreen ? Icons.zoom_in_map : Icons.zoom_out_map, size: 20),
                  tooltip: fullscreen ? 'Exit full screen' : 'Full screen',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => fullscreen ? Navigator.of(context).pop() : _openFullscreen(context),
                ),
              ],
            ),
            // Full screen has no chips around it, so always show the legend there
            if (showLegend || fullscreen)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4, bottom: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [for (final l in visible) _LegendEntry(line: l)],
                ),
              )
            else
              const SizedBox(height: 12),
            _ChartBox(
              fill: fullscreen,
              child: LineChart(
                LineChartData(
                  minX: _x(start),
                  maxX: _x(end),
                  minY: minY,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  lineBarsData: bars,
                  betweenBarsData: betweens,
                  gridData: FlGridData(
                    verticalInterval: tick.inMilliseconds.toDouble(),
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: theme.dividerColor, strokeWidth: 0.5),
                    getDrawingVerticalLine: (_) =>
                        FlLine(color: theme.dividerColor, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${meta.formattedValue}$unit',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: tick.inMilliseconds.toDouble(),
                        minIncluded: false,
                        maxIncluded: false,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            tickFormat.format(
                              _wallClock(value),
                            ),
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      maxContentWidth: 220,
                      getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                      getTooltipItems: (touched) {
                        var first = true;
                        return touched.map((s) {
                          final line = lineForBar[s.barIndex];
                          if (line == null) return null; // range edge
                          final point = line.values.firstWhere(
                            (v) => _x(v.ts) == s.x,
                          );
                          var text =
                              '${line.label}: ${point.value!.toStringAsFixed(fractionDigits)}$unit';
                          if (line.showRange &&
                              point.min != null &&
                              point.max != null) {
                            text +=
                                ' (${point.min!.toStringAsFixed(fractionDigits)}–'
                                '${point.max!.toStringAsFixed(fractionDigits)})';
                          }
                          if (first) {
                            text =
                                '${tooltipFormat.format(point.ts.toLocal())}\n$text';
                            first = false;
                          }
                          return LineTooltipItem(
                            text,
                            TextStyle(
                              color: line.color.withValues(alpha: 1),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.left,
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on HistoryChart {
  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullscreenChartPage(
        chart: HistoryChart(
          title: title,
          unit: unit,
          lines: lines,
          start: start,
          end: end,
          bucket: bucket,
          minY: minY,
          maxY: maxY,
          fractionDigits: fractionDigits,
          showLegend: showLegend,
          fullscreen: true,
        ),
      ),
    ));
  }
}

/// Fixed-height chart in the list; fills the remaining space when full screen.
class _ChartBox extends StatelessWidget {
  final bool fill;
  final Widget child;

  const _ChartBox({required this.fill, required this.child});

  @override
  Widget build(BuildContext context) => fill ? Expanded(child: child) : SizedBox(height: 200, child: child);
}

/// Shows one chart alone, in landscape, with the system bars hidden.
class _FullscreenChartPage extends StatefulWidget {
  final HistoryChart chart;

  const _FullscreenChartPage({required this.chart});

  @override
  State<_FullscreenChartPage> createState() => _FullscreenChartPageState();
}

class _FullscreenChartPageState extends State<_FullscreenChartPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // An empty list restores the app's default (all orientations the platform config allows)
    SystemChrome.setPreferredOrientations([]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: widget.chart));
  }
}

class _LegendEntry extends StatelessWidget {
  final ChartLine line;

  const _LegendEntry({required this.line});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: line.showRange ? 8 : 3,
          decoration: BoxDecoration(
            color: line.showRange
                ? line.color.withValues(alpha: 0.35)
                : line.color,
            border: line.showRange
                ? Border.symmetric(
                    horizontal: BorderSide(color: line.color, width: 0),
                  )
                : null,
          ),
          child: line.showRange
              ? Center(child: Container(height: 2, color: line.color))
              : null,
        ),
        const SizedBox(width: 4),
        Text(
          line.showRange ? '${line.label} (min–max)' : line.label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
