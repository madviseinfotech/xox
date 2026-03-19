import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xox_madvise/theme/app_theme.dart';
import 'package:xox_madvise/view/dashBoardScreen.dart';

Future<void> showLeaveGamePrompt(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _PromptSheet(
        title: 'Leave this game?',
        subtitle:
            'You can stay in this round or jump straight into another game.',
        actions: [
          _PromptAction(
            label: 'Continue Playing',
            onTap: () => Navigator.of(context).pop(),
          ),
          _PromptAction(
            label: 'Try Another Game',
            primary: true,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const DashBoardScreen()),
                (route) => false,
              );
            },
          ),
        ],
      );
    },
  );
}

Future<void> showExitAppPrompt(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _PromptSheet(
        title: 'Before you go',
        subtitle: 'Your arcade is ready whenever you want one more round.',
        actions: [
          _PromptAction(
            label: 'Keep Playing',
            primary: true,
            onTap: () => Navigator.of(context).pop(),
          ),
          _PromptAction(
            label: 'Share App',
            onTap: () {
              Navigator.of(context).pop();
              SharePlus.instance.share(
                ShareParams(
                  text:
                      "Let's have fun with XOX https://play.google.com/store/apps/details?id=com.xox.madvise",
                  subject: "Let's Play!!",
                ),
              );
            },
          ),
          _PromptAction(
            label: 'Exit App',
            onTap: () {
              Navigator.of(context).pop();
              SystemNavigator.pop();
            },
          ),
        ],
      );
    },
  );
}

class _PromptSheet extends StatelessWidget {
  const _PromptSheet({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final List<_PromptAction> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: action.primary
                      ? ElevatedButton(
                          onPressed: action.onTap,
                          child: Text(action.label),
                        )
                      : OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: action.onTap,
                          child: Text(action.label),
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

class _PromptAction {
  const _PromptAction({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
}
