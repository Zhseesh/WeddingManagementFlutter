import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';

class FormSheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onSave;
  final String saveLabel;
  final bool saving;
  final VoidCallback? onDelete;

  const FormSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    this.saveLabel = 'Simpan',
    this.saving = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final topSafeArea = mediaQuery.padding.top;

    final rawMaxHeight = (screenHeight - topSafeArea) * 0.92 - keyboardInset;
    final maxSheetHeight = rawMaxHeight < 200.0 ? 200.0 : rawMaxHeight;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: AppTheme.error),
                      tooltip: 'Hapus',
                      onPressed: onDelete,
                    ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    color: palette.ink,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: palette.line),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
            Divider(height: 1, color: palette.line),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: palette.line),
                          foregroundColor: palette.ink,
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: saving ? null : onSave,
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(saveLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}