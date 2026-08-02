import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/app_theme.dart';

/// A polished save button with loading state and success feedback.
///
/// Features:
/// - Gradient background
/// - Loading spinner when saving
/// - Success checkmark animation
/// - Disabled state when form is invalid
class SaveButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isEnabled;

  const SaveButton({
    super.key,
    this.onPressed,
    this.label = 'Speichern',
    this.isEnabled = true,
  });

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isSuccess = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.onPressed == null || _isLoading) return;

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    // Simulate save delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isSuccess = true;
    });

    widget.onPressed?.call();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isSuccess = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.isEnabled && !_isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? LinearGradient(
                        colors: _isSuccess
                            ? [AppColors.green, AppColors.green.withValues(alpha: 0.8)]
                            : [AppColors.primary, const Color(0xFF8290F8)],
                      )
                    : null,
                color: isEnabled ? null : AppColors.darkMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: (_isSuccess ? AppColors.green : AppColors.primary)
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? _handleTap : null,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : _isSuccess
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 24,
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
