import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Types de modals disponibles
enum AppModalType {
  INFO,           // Information simple
  CONFIRMATION,   // Demande de confirmation (OK/Annuler)
  WARNING,        // Avertissement (Continuer/Annuler)
  ERROR,          // Erreur (OK uniquement)
  SUCCESS,        // Succès (OK uniquement)
  ACTION_REQUIRED, // Action requise (Effectuer l'action/Plus tard)
}

/// Modal centralisée pour afficher des informations, confirmations et avertissements
/// 
/// Exemples d'utilisation :
/// 
/// ```dart
/// // Information simple
/// AppModal.showInfo(
///   context: context,
///   title: "Information",
///   message: "Votre action a été effectuée avec succès.",
/// );
/// 
/// // Confirmation
/// final confirmed = await AppModal.showConfirmation(
///   context: context,
///   title: "Confirmer l'action",
///   message: "Êtes-vous sûr de vouloir continuer ?",
///   confirmText: "Oui",
///   cancelText: "Non",
/// );
/// 
/// // Avertissement
/// final proceed = await AppModal.showWarning(
///   context: context,
///   title: "Attention",
///   message: "Cette action est irréversible.",
/// );
/// 
/// // Erreur
/// AppModal.showError(
///   context: context,
///   title: "Erreur",
///   message: "Une erreur est survenue.",
/// );
/// 
/// // Succès
/// AppModal.showSuccess(
///   context: context,
///   title: "Succès",
///   message: "L'opération a réussi.",
/// );
/// 
/// // Action requise
/// final actionDone = await AppModal.showActionRequired(
///   context: context,
///   title: "Action requise",
///   message: "Vous devez effectuer cette action avant de continuer.",
/// );
/// ```
class AppModal {
  /// Affiche une modal centralisée selon le type
  static Future<bool?> show({
    required BuildContext context,
    required AppModalType type,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _AppModalDialog(
        type: type,
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  /// Modal d'information
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) async {
    await show(
      context: context,
      type: AppModalType.INFO,
      title: title,
      message: message,
      confirmText: buttonText ?? "OK",
      onConfirm: () => Navigator.of(context).pop(),
    );
  }

  /// Modal de confirmation
  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
  }) async {
    final result = await show(
      context: context,
      type: AppModalType.CONFIRMATION,
      title: title,
      message: message,
      confirmText: confirmText ?? "Confirmer",
      cancelText: cancelText ?? "Annuler",
      onConfirm: onConfirm,
    );
    return result ?? false;
  }

  /// Modal d'avertissement
  static Future<bool> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
  }) async {
    final result = await show(
      context: context,
      type: AppModalType.WARNING,
      title: title,
      message: message,
      confirmText: confirmText ?? "Continuer",
      cancelText: cancelText ?? "Annuler",
      onConfirm: onConfirm,
    );
    return result ?? false;
  }

  /// Modal d'erreur
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) async {
    await show(
      context: context,
      type: AppModalType.ERROR,
      title: title,
      message: message,
      confirmText: buttonText ?? "OK",
      onConfirm: () => Navigator.of(context).pop(),
    );
  }

  /// Modal de succès
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) async {
    await show(
      context: context,
      type: AppModalType.SUCCESS,
      title: title,
      message: message,
      confirmText: buttonText ?? "OK",
      onConfirm: () => Navigator.of(context).pop(),
    );
  }

  /// Modal d'action requise
  static Future<bool> showActionRequired({
    required BuildContext context,
    required String title,
    required String message,
    String? actionText,
    String? cancelText,
    VoidCallback? onAction,
  }) async {
    final result = await show(
      context: context,
      type: AppModalType.ACTION_REQUIRED,
      title: title,
      message: message,
      confirmText: actionText ?? "Effectuer l'action",
      cancelText: cancelText ?? "Plus tard",
      onConfirm: onAction,
    );
    return result ?? false;
  }
}

class _AppModalDialog extends StatelessWidget {
  final AppModalType type;
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _AppModalDialog({
    required this.type,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
  });

  Color _getPrimaryColor() {
    switch (type) {
      case AppModalType.INFO:
        return Colors.blue;
      case AppModalType.CONFIRMATION:
        return AppColors.primary;
      case AppModalType.WARNING:
        return Colors.orange;
      case AppModalType.ERROR:
        return Colors.red;
      case AppModalType.SUCCESS:
        return Colors.green;
      case AppModalType.ACTION_REQUIRED:
        return AppColors.primary;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case AppModalType.INFO:
        return Icons.info_outline;
      case AppModalType.CONFIRMATION:
        return Icons.help_outline;
      case AppModalType.WARNING:
        return Icons.warning_amber_rounded;
      case AppModalType.ERROR:
        return Icons.error_outline;
      case AppModalType.SUCCESS:
        return Icons.check_circle_outline;
      case AppModalType.ACTION_REQUIRED:
        return Icons.notifications_active_outlined;
    }
  }

  bool _hasCancelButton() {
    return type == AppModalType.CONFIRMATION ||
        type == AppModalType.WARNING ||
        type == AppModalType.ACTION_REQUIRED;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor();
    final icon = _getIcon();
    final hasCancel = _hasCancelButton();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 32,
              ),
            ),

            const SizedBox(height: 20),

            // Titre
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                if (hasCancel) ...[
                  Expanded(
                    child: _buildCancelButton(context, primaryColor),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: hasCancel ? 1 : 2,
                  child: _buildConfirmButton(context, primaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, Color primaryColor) {
    return ElevatedButton(
      onPressed: () {
        if (onCancel != null) {
          onCancel!();
        } else {
          Navigator.of(context).pop(false);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor.withOpacity(0.1),
        foregroundColor: primaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        cancelText ?? "Annuler",
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, Color primaryColor) {
    return ElevatedButton(
      onPressed: () {
        if (onConfirm != null) {
          onConfirm!();
        } else {
          Navigator.of(context).pop(true);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        confirmText ?? "OK",
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
