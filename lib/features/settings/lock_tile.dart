import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import '../lock/lock_service.dart';

/// The "App lock" switch in Settings.
class LockTile extends StatelessWidget {
  const LockTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LockService.instance,
      builder: (context, _) {
        final lock = LockService.instance;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('SECURITY'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: !lock.supported
                  ? null
                  : () async {
                      final ok = await lock.setEnabled(!lock.enabled);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('The app lock was not changed.'),
                          ),
                        );
                      }
                    },
              child: BrutalCard(
                color: lock.enabled ? AppColors.green : AppColors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('App lock', style: uStyle(12)),
                          const SizedBox(height: 4),
                          Text(
                            lock.supported
                                ? 'Ask for your fingerprint, face or PIN when you open ClearCash.'
                                : 'Set a screen lock (fingerprint, PIN or pattern) in your phone settings to use this.',
                            style: mStyle(10, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    if (lock.supported) ...[
                      const SizedBox(width: 10),
                      BrutalTag(
                        lock.enabled ? 'ON' : 'OFF',
                        color: lock.enabled ? AppColors.lime : AppColors.pink,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
