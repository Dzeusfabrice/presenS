import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../theme/app_colors.dart';

class AppUtils {
  static void showToast(
    String message, {
    Color? backgroundColor,
    Color? textColor,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor:
          backgroundColor ?? AppColors.backgroundGrey.withOpacity(0.8),
      textColor: textColor ?? Colors.white,
      fontSize: 14.0,
    );
  }

  static void showSuccessToast(String message) {
    showToast(message, backgroundColor: AppColors.success);
  }

  static void showErrorToast(String message) {
    showToast(message, backgroundColor: AppColors.error);
  }

  static void showWarningToast(String message) {
    showToast(message, backgroundColor: AppColors.warning);
  }

  /// Vérifie si l'erreur est liée à la connexion internet
  static bool isConnectionError(dynamic error) {
    // Les erreurs HTTP (4xx, 5xx) ne sont PAS des erreurs de connexion
    // Ce sont des erreurs de l'API elle-même
    
    if (error is SocketException) {
      return true;
    }
    
    // HttpException peut être une vraie erreur de connexion ou une erreur HTTP
    // On vérifie le message pour être plus précis
    if (error is HttpException) {
      final message = error.message.toLowerCase();
      // Si c'est une erreur HTTP avec un code, ce n'est pas une erreur de connexion
      if (message.contains('http') && 
          (message.contains('400') || message.contains('401') || 
           message.contains('403') || message.contains('404') || 
           message.contains('500') || message.contains('502') || 
           message.contains('503'))) {
        return false;
      }
      // Sinon, c'est probablement une vraie erreur de connexion
      return true;
    }
    
    final errorString = error.toString().toLowerCase();
    
    // Ignorer les erreurs HTTP explicites
    if (errorString.contains('http') && 
        (errorString.contains('400') || errorString.contains('401') || 
         errorString.contains('403') || errorString.contains('404') || 
         errorString.contains('500') || errorString.contains('502') || 
         errorString.contains('503'))) {
      return false;
    }
    
    // Vraies erreurs de connexion réseau
    return errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection timed out') ||
        errorString.contains('no internet connection') ||
        errorString.contains('networkerror') ||
        errorString.contains('connection error') ||
        errorString.contains('handshake exception') ||
        errorString.contains('certificate') ||
        errorString.contains('tls') ||
        errorString.contains('ssl');
  }

  /// Affiche un message d'erreur de connexion
  static void showConnectionErrorToast() {
    showErrorToast(
      "Connexion internet requise. Veuillez vérifier votre connexion et réessayer.",
    );
  }

  /// Gère les erreurs et affiche le message approprié
  static void handleError(dynamic error, {String? customMessage}) {
    if (isConnectionError(error)) {
      showConnectionErrorToast();
    } else {
      showErrorToast(
        customMessage ?? "Une erreur est survenue. Veuillez réessayer.",
      );
    }
  }
}
