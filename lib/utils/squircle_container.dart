import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gradient_border.dart';

Path buildSquirclePath(
  Rect rect, {
  required BorderRadius borderRadius,
  double smoothing = 0.65,
}) {
  final clampedSmoothing = smoothing.clamp(0.0, 1.0);

    // Adaptive radius compensation: superellipse corners visually appear
    // "tighter" than circular RRect corners for the same numeric radius.
    // Scale the requested radii up so the same BorderRadius value reads
    // closer to a normal rounded rect. Reduce the compensation a bit for
    // very large radii so the shape still stays balanced.
  final avgRequestedRadius = (borderRadius.topLeft.x +
          borderRadius.topRight.x +
          borderRadius.bottomRight.x +
          borderRadius.bottomLeft.x) /
      4.0;
  final maxPossible = math.min(rect.width, rect.height) / 2.0;
    final radiusRatio = maxPossible > 0
      ? (avgRequestedRadius / maxPossible).clamp(0.0, 1.0)
      : 0.0;
    const baseFactor = 1.35;
    final adaptiveFactor = baseFactor * (1.0 - 0.1 * radiusRatio);
    final radiusScale = 1.0 + (clampedSmoothing * adaptiveFactor);
  final left = rect.left;
  final top = rect.top;
  final right = rect.right;
  final bottom = rect.bottom;

  final topLeft = _clampRadius(borderRadius.topLeft * radiusScale, rect);
  final topRight = _clampRadius(borderRadius.topRight * radiusScale, rect);
  final bottomRight = _clampRadius(borderRadius.bottomRight * radiusScale, rect);
  final bottomLeft = _clampRadius(borderRadius.bottomLeft * radiusScale, rect);

  final path = Path();
  path.moveTo(left + topLeft.x, top);
  path.lineTo(right - topRight.x, top);
  _addCorner(
    path,
    cornerRect: Rect.fromLTWH(
      right - topRight.x * 2,
      top,
      topRight.x * 2,
      topRight.y * 2,
    ),
    startAngle: -math.pi / 2,
    sweepAngle: math.pi / 2,
    smoothing: clampedSmoothing,
  );
  path.lineTo(right, bottom - bottomRight.y);
  _addCorner(
    path,
    cornerRect: Rect.fromLTWH(
      right - bottomRight.x * 2,
      bottom - bottomRight.y * 2,
      bottomRight.x * 2,
      bottomRight.y * 2,
    ),
    startAngle: 0,
    sweepAngle: math.pi / 2,
    smoothing: clampedSmoothing,
  );
  path.lineTo(left + bottomLeft.x, bottom);
  _addCorner(
    path,
    cornerRect: Rect.fromLTWH(
      left,
      bottom - bottomLeft.y * 2,
      bottomLeft.x * 2,
      bottomLeft.y * 2,
    ),
    startAngle: math.pi / 2,
    sweepAngle: math.pi / 2,
    smoothing: clampedSmoothing,
  );
  path.lineTo(left, top + topLeft.y);
  _addCorner(
    path,
    cornerRect: Rect.fromLTWH(
      left,
      top,
      topLeft.x * 2,
      topLeft.y * 2,
    ),
    startAngle: math.pi,
    sweepAngle: math.pi / 2,
    smoothing: clampedSmoothing,
  );

  path.close();
  return path;
}

Radius _clampRadius(Radius radius, Rect rect) {
  final maxX = rect.width / 2;
  final maxY = rect.height / 2;
  return Radius.elliptical(
    math.min(radius.x, maxX),
    math.min(radius.y, maxY),
  );
}

void _addCorner(
  Path path, {
  required Rect cornerRect,
  required double startAngle,
  required double sweepAngle,
  required double smoothing,
  int segments = 16,
}) {
  if (cornerRect.width <= 0 || cornerRect.height <= 0) {
    return;
  }

  final center = cornerRect.center;
  final radiusX = cornerRect.width / 2;
  final radiusY = cornerRect.height / 2;
  final exponent = 2.0 + (smoothing * 2.5);

  for (var step = 1; step <= segments; step++) {
    final t = startAngle + (sweepAngle * step / segments);
    final cosT = math.cos(t);
    final sinT = math.sin(t);
    final x = center.dx + radiusX * _signedSuperellipseCoordinate(cosT, exponent);
    final y = center.dy + radiusY * _signedSuperellipseCoordinate(sinT, exponent);
    path.lineTo(x, y);
  }
}

double _signedSuperellipseCoordinate(double value, double exponent) {
  final sign = value < 0 ? -1.0 : 1.0;
  return sign * math.pow(value.abs(), 2 / exponent).toDouble();
}

class SquircleClipper extends CustomClipper<Path> {
  final BorderRadius borderRadius;
  final double smoothing;

  const SquircleClipper({
    required this.borderRadius,
    this.smoothing = 0.65,
  });

  @override
  Path getClip(Size size) {
    return buildSquirclePath(
      Offset.zero & size,
      borderRadius: borderRadius,
      smoothing: smoothing,
    );
  }

  @override
  bool shouldReclip(covariant SquircleClipper oldClipper) {
    return oldClipper.borderRadius != borderRadius ||
        oldClipper.smoothing != smoothing;
  }
}

class SquircleContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;
  final BoxConstraints? constraints;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final BorderRadius borderRadius;
  final double smoothing;
  final Clip clipBehavior;

  const SquircleContainer({
    super.key,
    required this.child,
    required this.borderRadius,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.center,
    this.constraints,
    this.width,
    this.height,
    this.backgroundColor,
    this.backgroundGradient,
    this.border,
    this.boxShadow,
    this.smoothing = 0.65,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: CustomPaint(
        painter: _SquircleSurfacePainter(
          backgroundColor: backgroundColor,
          backgroundGradient: backgroundGradient,
          boxShadow: boxShadow,
          borderRadius: borderRadius,
          smoothing: smoothing,
        ),
        foregroundPainter: _SquircleBorderPainter(
          border: border,
          borderRadius: borderRadius,
          smoothing: smoothing,
        ),
        child: ClipPath(
          clipper: SquircleClipper(
            borderRadius: borderRadius,
            smoothing: smoothing,
          ),
          clipBehavior: clipBehavior,
          child: ConstrainedBox(
            constraints: constraints ?? const BoxConstraints(),
            child: SizedBox(
              width: width,
              height: height,
              child: Padding(
                padding: padding,
                child: Align(
                  alignment: alignment,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SquircleSurfacePainter extends CustomPainter {
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final List<BoxShadow>? boxShadow;
  final BorderRadius borderRadius;
  final double smoothing;

  _SquircleSurfacePainter({
    required this.backgroundColor,
    required this.backgroundGradient,
    required this.boxShadow,
    required this.borderRadius,
    required this.smoothing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final rect = Offset.zero & size;
    final path = buildSquirclePath(
      rect,
      borderRadius: borderRadius,
      smoothing: smoothing,
    );

    // Only apply the complex clipping if there are shadows to draw
    if (boxShadow != null && boxShadow!.isNotEmpty) {
      // 1. Create a massive outer boundary to ensure we don't clip the outer shadow spread
      // 2. Add the exact squircle path to the center
      // 3. Use evenOdd fill type to create a perfect mask with a hole in the middle
      final inverseClipPath = Path()
        ..addRect(rect.inflate(10000)) 
        ..addPath(path, Offset.zero)
        ..fillType = PathFillType.evenOdd;

      canvas.save();
      // Apply the mask so nothing can be drawn inside the squircle boundaries
      canvas.clipPath(inverseClipPath);

      for (final shadow in boxShadow!) {
        if (shadow.blurRadius <= 0 &&
            shadow.spreadRadius <= 0 &&
            shadow.offset == Offset.zero) {
          continue;
        }

        final shadowRect = rect.inflate(shadow.spreadRadius).shift(shadow.offset);
        final shadowPath = buildSquirclePath(
          shadowRect,
          borderRadius: borderRadius,
          smoothing: smoothing,
        );
        
        final shadowPaint = Paint()
          ..color = shadow.color
          ..style = PaintingStyle.fill;

        if (shadow.blurRadius > 0) {
          shadowPaint.maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            shadow.blurRadius,
          );
        }

        canvas.drawPath(shadowPath, shadowPaint);
      }
      
      // Remove the clipping mask before drawing the actual background
      canvas.restore();
    }

    final fillPaint = Paint()..style = PaintingStyle.fill;
    if (backgroundGradient != null) {
      fillPaint.shader = backgroundGradient!.createShader(rect);
    } else {
      fillPaint.color = backgroundColor ?? Colors.transparent;
    }
    
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SquircleSurfacePainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.backgroundGradient != backgroundGradient ||
        oldDelegate.boxShadow != boxShadow ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.smoothing != smoothing;
  }
}

class _SquircleBorderPainter extends CustomPainter {
  final BoxBorder? border;
  final BorderRadius borderRadius;
  final double smoothing;

  _SquircleBorderPainter({
    required this.border,
    required this.borderRadius,
    required this.smoothing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (border == null || size.isEmpty) {
      return;
    }

    final rect = Offset.zero & size;
    final path = buildSquirclePath(
      rect,
      borderRadius: borderRadius,
      smoothing: smoothing,
    );

    if (border is GradientBoxBorder) {
      (border as GradientBoxBorder).paintPath(canvas, rect, path);
      return;
    }

    if (border is Border && (border as Border).isUniform) {
      final side = (border as Border).top;
      if (side.style != BorderStyle.none && side.width > 0) {
        final paint = Paint()
          ..color = side.color
          ..strokeWidth = side.width
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, paint);
        return;
      }
    }

    if (border is Border) {
      final borderObj = border as Border;

      void drawSide(BorderSide side) {
        if (side.style == BorderStyle.none || side.width <= 0) return;
        final paint = Paint()
          ..color = side.color
          ..strokeWidth = side.width
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, paint);
      }

      drawSide(borderObj.top);
      drawSide(borderObj.bottom);
      drawSide(borderObj.left);
      drawSide(borderObj.right);
      return;
    }

    border!.paint(
      canvas,
      rect,
      shape: BoxShape.rectangle,
      borderRadius: borderRadius,
    );
  }

  @override
  bool shouldRepaint(covariant _SquircleBorderPainter oldDelegate) {
    return oldDelegate.border != border ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.smoothing != smoothing;
  }
}

/// A simple ClipPath wrapper for squircle shapes.
/// Perfect for use with BackdropFilter, GlassContainer, or any effect that needs clipping.
class ClipSquircle extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double smoothing;
  final Clip clipBehavior;

  const ClipSquircle({
    super.key,
    required this.child,
    required this.borderRadius,
    this.smoothing = 0.65,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: SquircleClipper(
        borderRadius: borderRadius,
        smoothing: smoothing,
      ),
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}