import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/ble_provider.dart';
import 'providers/telemetry_provider.dart';
import 'providers/wifi_setup_provider.dart';
import 'presentation/screens/main_navigation_screen.dart';
import 'presentation/screens/device_discovery_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartIvMonitorApp());
}

class SmartIvMonitorApp extends StatelessWidget {
  const SmartIvMonitorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleProvider()),
        ChangeNotifierProxyProvider<BleProvider, TelemetryProvider>(
          create: (ctx) => TelemetryProvider(Provider.of<BleProvider>(ctx, listen: false).bleService),
          update: (ctx, ble, previous) => previous ?? TelemetryProvider(ble.bleService),
        ),
        ChangeNotifierProxyProvider<BleProvider, WifiSetupProvider>(
          create: (ctx) => WifiSetupProvider(Provider.of<BleProvider>(ctx, listen: false).bleService),
          update: (ctx, ble, previous) => previous ?? WifiSetupProvider(ble.bleService),
        ),
      ],
      child: MaterialApp(
        title: 'Smart IV Monitor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppRootRouter(),
      ),
    );
  }
}

class AppRootRouter extends StatelessWidget {
  const AppRootRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bleProv = Provider.of<BleProvider>(context);

    if (bleProv.isConnected) {
      return const MainNavigationScreen();
    } else {
      return const DeviceDiscoveryScreen();
    }
  }
}
