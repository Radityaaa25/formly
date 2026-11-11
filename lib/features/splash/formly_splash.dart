// lib/features/splash/formly_splash.dart
//
// Animasi logo Formly (motion graphic) tanpa paket tambahan.
// Hanya memakai Flutter bawaan: AnimationController + CustomPainter.
//
// Urutan animasi (~3,4 detik):
//  1. Lencana kaca muncul, lalu "sudut sendi" (3 titik + garis + busur) tergambar.
//  2. Huruf f-o-r-m-l-y naik satu per satu (blur -> tajam, sedikit overshoot).
//  3. Titik biru jatuh memantul, memicu riak cahaya dan getaran halus.
//  4. Kilau melintas di atas tulisan, tagline muncul.
//  5. onFinished dipanggil (atau ketuk layar untuk lewati).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _navy = Color(0xFF0B1B3A);
const _blue = Color(0xFF2563EB);
const _sky = Color(0xFF38BDF8);
const _paper = Color(0xFFF4F7FC);

double _seg(double t, double a, double b, [Curve c = Curves.linear]) =>
    c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

class FormlySplash extends StatefulWidget {
  const FormlySplash({
    super.key,
    required this.onFinished,
    this.dark = false,
    this.fontFamily,
  });

  /// Dipanggil sekali setelah animasi selesai (atau saat layar diketuk).
  final VoidCallback onFinished;

  /// true = latar navy gelap, false = latar putih kebiruan (sesuai tema app).
  final bool dark;

  /// Isi dengan 'PlusJakartaSans' bila font sudah didaftarkan di pubspec,
  /// atau biarkan null untuk font bawaan.
  final String? fontFamily;

  @override
  State<FormlySplash> createState() => _FormlySplashState();
}

class _FormlySplashState extends State<FormlySplash>
    with SingleTickerProviderStateMixin {
  static const _letters = ['f', 'o', 'r', 'm', 'l', 'y'];
  static const double _fs = 60; // ukuran font wordmark

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );

  bool _finished = false;
  bool _dotLanded = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      // getaran halus saat titik mendarat
      if (!_dotLanded && _c.value >= 0.66) {
        _dotLanded = true;
        HapticFeedback.lightImpact();
      }
    });
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish(delay: 250);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Hormati pengaturan "kurangi animasi" dari sistem.
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1;
        _finish(delay: 500);
      } else {
        _c.forward();
      }
    });
  }

  Future<void> _finish({int delay = 0}) async {
    if (_finished) return;
    _finished = true;
    if (delay > 0) await Future.delayed(Duration(milliseconds: delay));
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final bg = dark ? _navy : _paper;
    final ink = dark ? Colors.white : _navy;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _finish(),
      child: Scaffold(
        backgroundColor: bg,
        body: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                _blobs(t, dark),
                Center(
                  child: Transform.translate(
                    offset: const Offset(0, -16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _mark(t),
                        const SizedBox(height: 30),
                        _wordmark(t, ink),
                        const SizedBox(height: 16),
                        _tagline(t, dark),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------- latar: gumpalan warna bergerak pelan ----------
  Widget _blobs(double t, bool dark) {
    final a = math.sin(t * math.pi * 2) * 14;
    final b = math.cos(t * math.pi * 2) * 14;
    final fade = _seg(t, 0, 0.2, Curves.easeOut);
    Widget blob(Color color, double size, Alignment al, Offset shift) => Align(
      alignment: al,
      child: Transform.translate(
        offset: shift,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withAlpha((fade * (dark ? 90 : 70)).round()),
                color.withAlpha(0),
              ],
            ),
          ),
        ),
      ),
    );
    return Stack(
      children: [
        blob(_sky, 380, const Alignment(1.1, -0.9), Offset(a, b)),
        blob(_blue, 420, const Alignment(-1.2, 0.95), Offset(b, a)),
      ],
    );
  }

  // ---------- lencana: sudut sendi digambar ----------
  Widget _mark(double t) {
    final badge = _seg(t, 0.0, 0.14, Curves.easeOutBack);
    final l1 = _seg(t, 0.07, 0.17, Curves.easeInOut);
    final l2 = _seg(t, 0.16, 0.26, Curves.easeInOut);
    final arc = _seg(t, 0.24, 0.36, Curves.easeOutCubic);
    final pops = [
      _seg(t, 0.05, 0.13, Curves.easeOutBack),
      _seg(t, 0.15, 0.23, Curves.easeOutBack),
      _seg(t, 0.24, 0.32, Curves.easeOutBack),
    ];
    // napas halus setelah selesai
    final breathe = 1 + math.sin(t * math.pi * 6) * 0.012 * _seg(t, 0.4, 0.5);

    return Opacity(
      opacity: badge.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: (0.6 + 0.4 * badge) * breathe,
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_sky, _blue],
            ),
            border: Border.all(color: Colors.white.withAlpha(110), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _blue.withAlpha(90),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              // kilap kaca di sisi atas
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: const Alignment(0, 0.1),
                      colors: [
                        Colors.white.withAlpha(95),
                        Colors.white.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _MarkPainter(l1: l1, l2: l2, arc: arc, pops: pops),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- wordmark: huruf naik + titik jatuh ----------
  Widget _wordmark(double t, Color ink) {
    final base = TextStyle(
      fontFamily: widget.fontFamily,
      fontSize: _fs,
      fontWeight: FontWeight.w800,
      letterSpacing: -2.5,
      height: 1.0,
      color: ink,
    );

    final children = <Widget>[];
    for (var i = 0; i < _letters.length; i++) {
      final s = 0.26 + i * 0.04;
      final p = _seg(t, s, s + 0.17, Curves.easeOutCubic);
      final back = _seg(t, s, s + 0.17, Curves.easeOutBack);
      final blur = (1 - p) * 10;
      Widget letter = Text(_letters[i], style: base);
      if (blur > 0.05) {
        letter = ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: letter,
        );
      }
      children.add(
        Opacity(
          opacity: p.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - back) * 36),
            child: letter,
          ),
        ),
      );
    }

    // titik biru: jatuh dari atas dan memantul
    final drop = _seg(t, 0.58, 0.74, Curves.bounceOut);
    final dropOp = _seg(t, 0.58, 0.62);
    final dotSize = _fs * 0.17;
    final ripple1 = _seg(t, 0.68, 0.92, Curves.easeOutCubic);
    final ripple2 = _seg(t, 0.72, 0.96, Curves.easeOutCubic);
    children.add(
      Padding(
        padding: EdgeInsets.only(
          left: 3,
          bottom: _fs * 0.2,
        ), // ~garis dasar huruf
        child: Opacity(
          opacity: dropOp,
          child: Transform.translate(
            offset: Offset(0, -(1 - drop) * 120),
            child: SizedBox(
              width: dotSize,
              height: dotSize,
              child: CustomPaint(
                painter: _DotPainter(
                  r1: ripple1,
                  r2: ripple2,
                  maxRadius: _fs * 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: children,
    );

    // kilau yang melintas di atas tulisan
    final shine = _seg(t, 0.76, 0.92, Curves.easeInOut);
    if (shine > 0 && shine < 1) {
      row = ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) {
          final x = -0.4 + shine * 1.8;
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              _sky.withAlpha(150),
              Colors.transparent,
            ],
            stops: [
              (x - 0.18).clamp(0.0, 1.0),
              x.clamp(0.0, 1.0),
              (x + 0.18).clamp(0.0, 1.0),
            ],
          ).createShader(rect);
        },
        child: row,
      );
    }
    return row;
  }

  // ---------- tagline ----------
  Widget _tagline(double t, bool dark) {
    final p = _seg(t, 0.80, 0.94, Curves.easeOutCubic);
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(0, (1 - p) * 10),
        child: Text(
          'Gerak benar, hasil lebih aman.',
          style: TextStyle(
            fontFamily: widget.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            color: dark ? const Color(0xFFB9D5FB) : const Color(0xFF5B6B8A),
          ),
        ),
      ),
    );
  }
}

// ======================= painter =======================

/// Tiga titik sendi + dua garis + busur sudut (motif "analisis gerakan").
class _MarkPainter extends CustomPainter {
  _MarkPainter({
    required this.l1,
    required this.l2,
    required this.arc,
    required this.pops,
  });

  final double l1, l2, arc;
  final List<double> pops;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final a = Offset(0.30 * s, 0.25 * s);
    final b = Offset(0.64 * s, 0.50 * s);
    final c = Offset(0.38 * s, 0.80 * s);

    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.07
      ..strokeCap = StrokeCap.round;

    if (l1 > 0) canvas.drawLine(a, Offset.lerp(a, b, l1)!, line);
    if (l2 > 0) canvas.drawLine(b, Offset.lerp(b, c, l2)!, line);

    // busur sudut di titik b
    if (arc > 0) {
      final a1 = (a - b).direction;
      final a2 = (c - b).direction;
      var sweep = a2 - a1;
      while (sweep > math.pi) {
        sweep -= 2 * math.pi;
      }
      while (sweep < -math.pi) {
        sweep += 2 * math.pi;
      }
      final arcPaint = Paint()
        ..color = Colors.white.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: b, radius: s * 0.2),
        a1,
        sweep * arc,
        false,
        arcPaint,
      );
    }

    // titik-titik sendi
    final pts = [a, b, c];
    for (var i = 0; i < 3; i++) {
      final p = pops[i];
      if (p <= 0) continue;
      final r = s * 0.085 * p;
      canvas.drawCircle(pts[i], r, Paint()..color = Colors.white);
      canvas.drawCircle(pts[i], r * 0.45, Paint()..color = _blue);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.l1 != l1 || old.l2 != l2 || old.arc != arc || old.pops != pops;
}

/// Titik biru di akhir wordmark + riak cahaya yang meluas.
class _DotPainter extends CustomPainter {
  _DotPainter({required this.r1, required this.r2, required this.maxRadius});

  final double r1, r2, maxRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    void ring(double p) {
      if (p <= 0 || p >= 1) return;
      final paint = Paint()
        ..color = _sky.withAlpha(((1 - p) * 140).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * (1 - p) + 0.5;
      canvas.drawCircle(center, size.width / 2 + p * maxRadius, paint);
    }

    ring(r1);
    ring(r2);

    // cahaya lembut di sekitar titik
    canvas.drawCircle(
      center,
      size.width * 1.1,
      Paint()
        ..color = _sky.withAlpha(60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(center, size.width / 2, Paint()..color = _sky);
  }

  @override
  bool shouldRepaint(_DotPainter old) => old.r1 != r1 || old.r2 != r2;
}

// ======================= helper navigasi =======================

/// Transisi keluar yang halus ke layar berikutnya (fade + sedikit zoom).
Route<T> formlyFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 650),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
