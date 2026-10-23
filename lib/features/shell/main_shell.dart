import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import '../../data/sync_service.dart';
import '../../data/tx_store.dart';
import '../goals/goals_screen.dart';
import '../home/home_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transactions_screen.dart';

/// Holds the bottom navigation and the five main tabs.
/// It also starts a cloud sync when the app opens, a few seconds after every
/// change, and whenever the app comes back to the foreground.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TxStore.instance.clear();
    TxStore.instance.addListener(_onStoreChanged);
    TxStore.instance.load(); // this first load also triggers the first sync
  }

  @override
  void dispose() {
    _debounce?.cancel();
    TxStore.instance.removeListener(_onStoreChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onStoreChanged() {
    // Changes made by the sync itself must not start another sync.
    if (SyncService.instance.syncing) return;
    _scheduleSync();
  }

  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), () {
      SyncService.instance.sync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleSync();
  }

  void _addTransaction() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onSeeAll: () => setState(() => _index = 1)),
          const TransactionsScreen(),
          const ReportsScreen(),
          const GoalsScreen(),
          const SettingsScreen(),
        ],
      ),
      floatingActionButton: (_index == 0 || _index == 1)
          ? BrutalFab(onPressed: _addTransaction)
          : null,
      bottomNavigationBar: AppBottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
