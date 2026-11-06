import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import '../reminder/reminder_service.dart';

/// The "Daily reminder" card in Settings. Hidden where reminders aren't supported (Chrome).
class ReminderTile extends StatelessWidget {
  const ReminderTile({super.key});

  Future<void> _toggle(BuildContext context) async {
    final r = ReminderService.instance;
    if (r.enabled) {
      await r.disable();
      return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: r.time,
      helpText: 'REMINDER TIME',
    );
    if (picked == null) return;
    final ok = await r.enable(picked);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Allow notifications for ClearCash in your phone settings to use reminders.',
          ),
        ),
      );
    }
  }

  Future<void> _changeTime(BuildContext context) async {
    final r = ReminderService.instance;
    final picked = await showTimePicker(
      context: context,
      initialTime: r.time,
      helpText: 'REMINDER TIME',
    );
    if (picked != null) await r.changeTime(picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ReminderService.instance,
      builder: (context, _) {
        final r = ReminderService.instance;
        if (!r.supported) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('REMINDER'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _toggle(context),
              child: BrutalCard(
                color: r.enabled ? AppColors.green : AppColors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily reminder', style: uStyle(12)),
                          const SizedBox(height: 4),
                          Text(
                            r.enabled
                                ? 'Every day at ${r.time.format(context)}'
                                : 'Get a nudge to log your spending every day.',
                            style: mStyle(10, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    BrutalTag(
                      r.enabled ? 'ON' : 'OFF',
                      color: r.enabled ? AppColors.lime : AppColors.pink,
                    ),
                  ],
                ),
              ),
            ),
            if (r.enabled) ...[
              const SizedBox(height: 18),
              BrutalButton(
                label: 'Change time',
                color: AppColors.white,
                onPressed: () => _changeTime(context),
              ),
            ],
          ],
        );
      },
    );
  }
}
