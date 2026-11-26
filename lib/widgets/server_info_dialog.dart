import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dkpi/api/api_client.dart';

Future<void> showServerInfoDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const ServerInfoDialog(),
  );
}

class ServerInfoDialog extends StatefulWidget {
  const ServerInfoDialog({super.key});

  @override
  State<ServerInfoDialog> createState() => _ServerInfoDialogState();
}

class _ServerInfoDialogState extends State<ServerInfoDialog> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient.getServerInfo();
  }

  void _reload() {
    // Block body: an arrow closure would return the assigned Future, which setState rejects
    setState(() {
      _future = ApiClient.getServerInfo();
    });
  }

  /// Uptime may come back as seconds (number) or an already formatted string.
  static String _formatUptime(dynamic value) {
    if (value is num) {
      final d = Duration(seconds: value.round());
      final days = d.inDays;
      final hours = d.inHours.remainder(24);
      final minutes = d.inMinutes.remainder(60);
      return [
        if (days > 0) '${days}d',
        if (days > 0 || hours > 0) '${hours}h',
        '${minutes}m',
      ].join(' ');
    }
    return value?.toString() ?? '—';
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: SelectableText(value),
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 18),
        tooltip: 'Copy',
        onPressed: () => Clipboard.setData(ClipboardData(text: value)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Server info'),
      content: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Text('Failed to load server info:\n${snapshot.error}');
          }
          final info = snapshot.data!;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _row(context, Icons.timer_outlined, 'System uptime', _formatUptime(info['uptime'])),
              _row(context, Icons.dns_outlined, 'Server process uptime', _formatUptime(info['process_uptime'])),
              _row(context, Icons.lan_outlined, 'Private IP', info['private_ip']?.toString() ?? '—'),
              _row(context, Icons.public, 'Public IP', info['public_ip']?.toString() ?? '—'),
            ],
          );
        },
      ),
      actions: [
        TextButton(onPressed: _reload, child: const Text('Refresh')),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}
