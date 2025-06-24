import 'package:flutter/material.dart';

/// Mixin to provide safe state management with mounted checks and error handling
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  
  /// Safe setState that only calls setState if the widget is still mounted
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  /// Execute an async operation with loading state management
  Future<R?> executeWithLoading<R>(
    Future<R> Function() operation, {
    VoidCallback? onStart,
    Function(R)? onSuccess,
    Function(dynamic)? onError,
    VoidCallback? onComplete,
  }) async {
    try {
      if (onStart != null) {
        safeSetState(onStart);
      }

      final result = await operation();
      
      if (onSuccess != null) {
        onSuccess(result);
      }
      
      return result;
      
    } catch (error) {
      debugPrint('Operation failed: $error');
      
      if (onError != null) {
        onError(error);
      }
      
      return null;
    } finally {
      if (onComplete != null) {
        safeSetState(onComplete);
      }
    }
  }

  /// Show error message safely
  void showErrorMessage(String message, {Duration? duration}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: duration ?? const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show success message safely
  void showSuccessMessage(String message, {Duration? duration}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: duration ?? const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show loading dialog safely
  void showLoadingDialog({String message = 'Loading...'}) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        ),
      );
    }
  }

  /// Hide loading dialog safely
  void hideLoadingDialog() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Execute operation with loading dialog
  Future<R?> executeWithLoadingDialog<R>(
    Future<R> Function() operation, {
    String loadingMessage = 'Loading...',
    String? successMessage,
    String? errorMessage,
  }) async {
    showLoadingDialog(message: loadingMessage);
    
    try {
      final result = await operation();
      
      if (successMessage != null) {
        showSuccessMessage(successMessage);
      }
      
      return result;
      
    } catch (error) {
      debugPrint('Operation with loading dialog failed: $error');
      
      showErrorMessage(
        errorMessage ?? 'Operation failed: ${error.toString()}',
      );
      
      return null;
    } finally {
      hideLoadingDialog();
    }
  }

  /// Debounced setState to prevent rapid state changes
  void debouncedSetState(VoidCallback fn, {Duration delay = const Duration(milliseconds: 300)}) {
    Future.delayed(delay, () {
      safeSetState(fn);
    });
  }
} 