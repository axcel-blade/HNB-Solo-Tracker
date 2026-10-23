import 'package:flutter/material.dart';

import '../services/app_update.dart';
import '../services/release_link.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

Future<void> showUpdateDialog(BuildContext context, UpdateResult result) {
  return showDialog<void>(
    context: context,
    builder: (context) => UpdateDialog(result: result),
  );
}

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.result});

  final UpdateResult result;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  String? _openError;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final notes = result.notes?.trim() ?? '';
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UPDATE',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                updateAvailableTitle,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              Text(
                result.message,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.noticeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      notes,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ),
              ],
              if (_openError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _openError!,
                  style: const TextStyle(
                    color: AppColors.dangerFg,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  AppButton(
                    label: 'Later',
                    kind: AppButtonKind.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  AppButton(
                    label: 'View release',
                    onPressed: () async {
                      final opened = await openReleasePage(result.pageUrl);
                      if (!context.mounted) return;
                      if (opened) {
                        Navigator.of(context).pop();
                        return;
                      }
                      setState(() {
                        _openError = 'Could not open the GitHub release page.';
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
