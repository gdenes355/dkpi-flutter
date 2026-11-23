import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dkpi/models/device.dart';
import 'package:dkpi/api/api_client.dart';
import 'package:dkpi/cubits/device_row.dart';
import 'package:dkpi/widgets/device_row.dart';
import 'package:dkpi/location_helper.dart';
import 'package:dkpi/cubits/devices.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dunakeszi Kazinczy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: BlocProvider(create: (context) => DevicesCubit(), child: const MyHomePage(title: 'Dunakeszi Kazinczy')),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool _isAtHome = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocation();
  }

  void _checkLocation() async {
    final atHome = await LocationHelper.isAtHome(canRequestPermission: false);
    if (mounted) {
      setState(() => _isAtHome = atHome);
      context.read<DevicesCubit>().loadDevices();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DevicesCubit>().loadDevices();
      _checkLocation();
    }
  }

  void _rescan() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Scanning for devices, this may take a while…')),
    );
    try {
      await context.read<DevicesCubit>().rescan();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Scan finished')));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Scan failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final devicesState = context.watch<DevicesCubit>().state;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (devicesState.scanning)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rescan') _rescan();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rescan',
                enabled: !devicesState.scanning,
                child: Text(devicesState.scanning ? 'Scanning…' : 'Re-scan'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isAtHome)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.wifi),
                  Text(' home wifi detected ', style: Theme.of(context).textTheme.bodyMedium,),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: devicesState.devices.length,
              itemBuilder: (context, index) {
                final device = devicesState.devices[index];
                // Key by device id so each row keeps its own cubit when the
                // list changes (e.g. after a re-scan adds devices), instead of
                // reusing the cubit of whatever device used to be at this index.
                return BlocProvider(
                  key: ValueKey(device.id),
                  create: (context) => DeviceRowCubit(id: device.id)..loadStatus(),
                  child: DeviceRowWidget(
                    device: device,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<DevicesCubit>().loadDevices(),
        tooltip: 'Refresh devices',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
