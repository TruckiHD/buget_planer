import 'package:flutter/material.dart';

import '../../utils/currency_utils.dart';

/// Animated counter that smoothly transitions between values.
///
/// Used for balance displays and KPI cards to create a polished feel.
class AnimatedCounter extends StatefulWidget {
  final int targetCents;
  final Duration duration;
  final TextStyle? style;
  final bool formatAsCurrency;

  const AnimatedCounter({
    super.key,
    required this.targetCents,
    this.duration = const Duration(milliseconds: 600),
    this.style,
    this.formatAsCurrency = true,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousCents = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: _previousCents.toDouble(),
      end: widget.targetCents.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetCents != widget.targetCents) {
      _previousCents = _animation.value.toInt();
      _animation = Tween<double>(
        begin: _previousCents.toDouble(),
        end: widget.targetCents.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value.round();
        final text = widget.formatAsCurrency
            ? CurrencyUtils.formatCents(value)
            : value.toString();
        return Text(
          text,
          style: widget.style,
        );
      },
    );
  }
}
