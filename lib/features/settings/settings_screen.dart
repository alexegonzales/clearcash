import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import '../../data/tx_store.dart';
import '../auth/auth_service.dart';
import 'sync_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _editName() async {
    final user = FirebaseAuth.instance.currentUser;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.black, width: kBorder),
      ),
      builder: (_) => _NameSheet(current: user?.displayName ?? ''),
    );
    if (changed == true && mounted) {
      setState(() {}); // show the new name
    }
  }

  Future<void> _sendReset() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) {
      _toast('No email found for this account.');
      return;
    }
    try {
      await AuthService().sendReset(email);
      _toast('Reset link sent to $email');
    } catch (e) {
      _toast(AuthService.friendlyError(e));
    }
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: uStyle(11)),
        Text(value, style: mStyle(12, weight: FontWeight.w700)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName ?? '').trim();

    return Column(
      children: [
        const BrutalTopBar(
          title: 'Settings',
          subtitle: 'ACCOUNT & PREFERENCES',
          color: AppColors.sky,
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: TxStore.instance,
            builder: (context, _) {
              final s = TxStore.instance;
              return ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
                children: [
                  BrutalCard(
                    color: AppColors.cyan,
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.black,
                              width: 3,
                            ),
                          ),
                          child: const Text(
                            '😊',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isEmpty ? 'ClearCash user' : name,
                                style: uStyle(14),
                              ),
                              const SizedBox(height: 4),
                              Text(user?.email ?? '', style: mStyle(11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  BrutalButton(
                    label: 'Edit name',
                    color: AppColors.white,
                    onPressed: _editName,
                  ),
                  const SizedBox(height: 26),
                  const SectionHeader('YOUR DATA'),
                  const SizedBox(height: 10),
                  BrutalListCard(
                    children: [
                      _row('Transactions', '${s.items.length}'),
                      _row('Budgets', '${s.budgets.length}'),
                      _row('Goals', '${s.goals.length}'),
                      _row('Currency', '₱ PHP'),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const SyncCard(),
                  const SizedBox(height: 26),
                  BrutalButton(
                    label: 'Send password reset email',
                    color: AppColors.sky,
                    onPressed: _sendReset,
                  ),
                  const SizedBox(height: 22),
                  BrutalButton(
                    label: 'Log Out',
                    color: AppColors.pink,
                    onPressed: () => AuthService().logOut(),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: Text(
                      'ClearCash v1.0',
                      style: mStyle(10, color: AppColors.muted),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NameSheet extends StatefulWidget {
  final String current;
  const _NameSheet({required this.current});

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final TextEditingController _name;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.current);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _name.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Enter your name.');
      return;
    }
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.updateDisplayName(value);
      await user?.reload();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = AuthService.friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('EDIT NAME', style: uStyle(14)),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: const BrutalTag(
                    'CLOSE',
                    color: AppColors.black,
                    textColor: AppColors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            BrutalInput(label: 'Your name', controller: _name),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: mStyle(
                  11,
                  weight: FontWeight.w700,
                  color: AppColors.expense,
                ),
              ),
            ],
            const SizedBox(height: 24),
            BrutalButton(
              label: _saving ? 'Saving...' : 'Save name',
              color: AppColors.green,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
