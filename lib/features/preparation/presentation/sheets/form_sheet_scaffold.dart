import 'package:material_ui/material_ui.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';

class FormSheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onSave;
  final String saveLabel;
  final bool saving;
  final VoidCallback? onDelete; // FITUR BARU

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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink))),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                      tooltip: 'Hapus',
                      onPressed: onDelete,
                    ),
                  IconButton(icon: const Icon(Icons.close), color: AppTheme.ink, onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.line),
            Flexible(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
            const Divider(height: 1, color: AppTheme.line),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: AppTheme.line), foregroundColor: AppTheme.ink),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: saving ? null : onSave,
                        child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(saveLabel),
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