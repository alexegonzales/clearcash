import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import '../../data/sync_service.dart';

/// Shows the last sync time and a "Sync now" button.
class SyncCard extends StatelessWidget {
  const SyncCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SyncService.instance,
      builder: (context, _) {
        final s = SyncService.instance;
        final String status;
        Color statusColor = AppColors.black;

        if (s.syncing) {
          status = 'Syncing...';
        } else if (s.lastError != null) {
          status = s.lastError!;
          statusColor = AppColors.expense;
        } else if (s.lastSync != null) {
          status =
              'Last synced at ${TimeOfDay.fromDateTime(s.lastSync!).format(context)}';
        } else {
          status = 'Not synced yet in this session.';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('BACKUP'),
            const SizedBox(height: 10),
            BrutalCard(
              color: AppColors.mint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cloud backup', style: uStyle(12)),
                  const SizedBox(height: 6),
                  Text(
                    status,
                    style: mStyle(
                      11,
                      weight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            BrutalButton(
              label: s.syncing ? 'Syncing...' : 'Sync now',
              color: AppColors.green,
              onPressed: s.syncing
                  ? null
                  : () async {
                      final ok = await SyncService.instance.sync();
                      if (context.mounted && ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Everything is backed up.'),
                          ),
                        );
                      }
                    },
            ),
          ],
        );
      },
    );
  }
}
