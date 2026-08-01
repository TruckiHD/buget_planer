import 'package:flutter/material.dart';

import 'squircle_container.dart';

/// An [InputBorder] that draws a squircle (superellipse) outline.
///
/// Drop-in replacement for [OutlineInputBorder] that produces squircle
/// corners instead of circular arcs.
///
/// ```dart
/// TextField(
///   decoration: InputDecoration(
///     border: SquircleInputBorder(
///       borderRadius: BorderRadius.circular(16),
///     ),
///     enabledBorder: SquircleInputBorder(
///       borderRadius: BorderRadius.circular(16),
///       borderSide: BorderSide(color: Colors.grey),
///     ),
///     focusedBorder: SquircleInputBorder(
///       borderRadius: BorderRadius.circular(16),
///       borderSide: BorderSide(color: Colors.blue, width: 2),
///     ),
///   ),
/// )
/// ```
class SquircleInputBorder extends InputBorder {
  /// The border radius of the squircle shape.
  final BorderRadius borderRadius;

  /// Controls the superellipse smoothing factor.
  ///
  /// Higher values produce rounder, more pillowy corners.
  /// Defaults to 0.65 which matches [SquircleContainer].
  final double smoothing;

  /// The gap between the label and the border when [gapPadding] > 0.
  ///
  /// Passed through to [gapStart] / [gapExtent] in [paint] to create
  /// the same label gap behavior as [OutlineInputBorder].
  final double gapPadding;

  const SquircleInputBorder({
    this.borderRadius = BorderRadius.zero,
    this.smoothing = 0.65,
    this.gapPadding = 4.0,
    super.borderSide = const BorderSide(),
  });

  @override
  bool get isOutline => true;

  @override
  SquircleInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? smoothing,
    double? gapPadding,
  }) {
    return SquircleInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
      smoothing: smoothing ?? this.smoothing,
      gapPadding: gapPadding ?? this.gapPadding,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.all(borderSide.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return buildSquirclePath(rect, borderRadius: borderRadius, smoothing: smoothing);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return buildSquirclePath(rect, borderRadius: borderRadius, smoothing: smoothing);
  }

  @override
  ShapeBorder scale(double t) {
    return SquircleInputBorder(
      borderRadius: borderRadius,
      smoothing: smoothing,
      gapPadding: gapPadding,
      borderSide: borderSide.scale(t),
    );
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width <= 0) {
      return;
    }

    final path = _buildPaintPath(rect, gapStart ?? 0.0, gapExtent, gapPercentage, textDirection);

    final paint = Paint()
      ..color = borderSide.color
      ..strokeWidth = borderSide.width
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  Path _buildPaintPath(
    Rect rect,
    double gapStart,
    double gapExtent,
    double gapPercentage,
    TextDirection? textDirection,
  ) {
    if (gapPercentage <= 0.0 || gapExtent <= 0.0) {
      return buildSquirclePath(
        rect,
        borderRadius: borderRadius,
        smoothing: smoothing,
      );
    }

    final path = buildSquirclePath(
      rect,
      borderRadius: borderRadius,
      smoothing: smoothing,
    );

    final gapWidth = gapExtent * (1.0 - gapPercentage);

    if (gapWidth <= 0.0) {
      return path;
    }

    final gapStartOffset = gapStart.clamp(
      rect.left,
      rect.right - gapWidth,
    );

    final gapPath = Path()
      ..moveTo(gapStartOffset, rect.top - borderSide.width)
      ..lineTo(gapStartOffset + gapWidth, rect.top - borderSide.width);

    return Path.combine(PathOperation.difference, path, gapPath);
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is SquircleInputBorder) {
      return SquircleInputBorder(
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
        smoothing: a.smoothing + (smoothing - a.smoothing) * t,
        gapPadding: a.gapPadding + (gapPadding - a.gapPadding) * t,
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is SquircleInputBorder) {
      return SquircleInputBorder(
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
        smoothing: smoothing + (b.smoothing - smoothing) * t,
        gapPadding: gapPadding + (b.gapPadding - gapPadding) * t,
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
      );
    }
    return super.lerpTo(b, t);
  }

}
