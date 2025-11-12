import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(AnimeStudyTimerApp());

class AnimeStudyTimerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sakura Study Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AnimeStudyTimerHome(),
    );
  }
}

class Petal {
  double x;
  double y;
  double speed;
  double size;
  double rot;
  double rotSpeed;
  Petal(this.x, this.y, this.speed, this.size, this.rot, this.rotSpeed);
}

class AnimeStudyTimerHome extends StatefulWidget {
  @override
  _AnimeStudyTimerHomeState createState() => _AnimeStudyTimerHomeState();
}

class _AnimeStudyTimerHomeState extends State<AnimeStudyTimerHome> {
  Duration sessionDuration = Duration(minutes: 25);
  Duration remaining = Duration(minutes: 25);
  Timer? countdown;
  bool isRunning = false;
  bool isCompleted = false;

  final List<Badge> allBadges = [
    Badge('Beginner', Icons.star, Color(0xFFFFD1DC)),
    Badge('Focused', Icons.center_focus_strong, Color(0xFFB39DDB)),
    Badge('Marathoner', Icons.local_fire_department, Color(0xFFFFAB91)),
    Badge('Night Owl', Icons.nights_stay, Color(0xFF90CAF9)),
    Badge('Consistency', Icons.auto_graph, Color(0xFFA5D6A7)),
  ];
  final List<Badge> earned = [];
  bool quizUnlocked = false;
  int customMinutes = 25;

  final Random _rng = Random();
  final List<Petal> _petals = [];
  Timer? _petalTimer;
  bool _petalsStarted = false;

  late String _currentTip;
  Timer? _tipTimer;
  final List<String> _tips = [
    "Short focused sessions beat distracted long hours.",
    "Micro-breaks (5 min) help you retain more.",
    "Remove phone notifications to lock focus.",
    "Set a single goal for each session.",
    "Celebrate each session — you're building consistency."
  ];

  @override
  void initState() {
    super.initState();
    remaining = sessionDuration;
    for (int i = 0; i < 22; i++) {
      _petals.add(Petal(
        _rng.nextDouble(),
        _rng.nextDouble(),
        0.002 + _rng.nextDouble() * 0.006,
        8 + _rng.nextDouble() * 16,
        _rng.nextDouble() * pi * 2,
        (0.01 + _rng.nextDouble() * 0.04) * (_rng.nextBool() ? 1 : -1),
      ));
    }

    _currentTip = _tips[_rng.nextInt(_tips.length)];
    _tipTimer = Timer.periodic(Duration(seconds: 8), (_) {
      setState(() {
        _currentTip = _tips[_rng.nextInt(_tips.length)];
      });
    });
  }

  @override
  void dispose() {
    countdown?.cancel();
    _petalTimer?.cancel();
    _tipTimer?.cancel();
    super.dispose();
  }

  void _startPetals(Size size) {
    if (_petalsStarted) return;
    _petalsStarted = true;
    _petalTimer = Timer.periodic(Duration(milliseconds: 40), (_) {
      setState(() {
        for (var p in _petals) {
          p.y += p.speed * (0.9 + _rng.nextDouble() * 0.6);
          p.x += sin(p.rot) * 0.0008 * (_rng.nextDouble() * 3);
          p.rot += p.rotSpeed;
          if (p.y > 1.15 || p.x < -0.2 || p.x > 1.2) {
            p.y = -0.1 - _rng.nextDouble() * 0.2;
            p.x = _rng.nextDouble();
            p.size = 6 + _rng.nextDouble() * 16;
            p.speed = 0.002 + _rng.nextDouble() * 0.006;
            p.rot = _rng.nextDouble() * pi * 2;
            p.rotSpeed = (0.01 + _rng.nextDouble() * 0.04) * (_rng.nextBool() ? 1 : -1);
          }
        }
      });
    });
  }

  void startTimer() {
    if (isCompleted) resetSession();
    if (isRunning) return;
    setState(() {
      isRunning = true;
      isCompleted = false;
    });

    final endTime = DateTime.now().add(remaining);

    countdown = Timer.periodic(Duration(seconds: 1), (_) {
      final left = endTime.difference(DateTime.now());
      if (left <= Duration.zero) {
        countdown?.cancel();
        setState(() {
          remaining = Duration.zero;
          isRunning = false;
          isCompleted = true;
        });
        onCompleteSession();
      } else {
        setState(() {
          remaining = left;
        });
      }
    });
  }

  void pauseTimer() {
    if (!isRunning) return;
    countdown?.cancel();
    setState(() {
      isRunning = false;
    });
  }

  void resetSession() {
    countdown?.cancel();
    setState(() {
      isRunning = false;
      isCompleted = false;
      remaining = sessionDuration;
    });
  }

  void setMinutes(int minutes) {
    countdown?.cancel();
    setState(() {
      customMinutes = minutes;
      sessionDuration = Duration(minutes: minutes);
      remaining = sessionDuration;
      isRunning = false;
      isCompleted = false;
    });
  }

  void onCompleteSession() {
    final available = allBadges.where((b) => !earned.contains(b)).toList();
    Badge awarded;
    if (available.isEmpty) {
      awarded = allBadges[_rng.nextInt(allBadges.length)];
    } else {
      awarded = available[_rng.nextInt(available.length)];
      earned.add(awarded);
      quizUnlocked = true;
    }

    Future.delayed(Duration(milliseconds: 250), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AwardDialog(
            badge: awarded,
            onClose: () => Navigator.of(context).pop(),
            onOpenQuiz: () {
              Navigator.of(context).pop();
              openQuiz();
            },
          );
        },
      );
    });
  }

  void openQuiz() {
    showDialog(
      context: context,
      builder: (context) {
        return QuizDialog(onAnswered: (correct) {
          setState(() {
            quizUnlocked = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(correct ? 'Correct! Extra morale boost!' : 'Nice attempt — try again next time.')));
        });
      },
    );
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final progress = (sessionDuration.inSeconds == 0)
        ? 0.0
        : 1.0 - (remaining.inSeconds / sessionDuration.inSeconds);

    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startPetals(size));

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(child: AnimatedGradient()),

            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: PetalPainter(petals: _petals),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sakura Study', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(height: 2),
                            Text('Focus • Reward • Grow', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.emoji_events, color: Colors.amberAccent),
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (c) => BadgeGalleryDialog(earned: earned, all: allBadges));
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 14),

                    Card(
                      color: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: 0, end: progress),
                                        duration: Duration(milliseconds: 350),
                                        builder: (context, value, _) {
                                          return CustomPaint(
                                            size: Size(140, 140),
                                            painter: RingPainter(
                                              progress: value,
                                              color: Color.lerp(Color(0xFFFFC1E3), Color(0xFFB39DDB), value) ?? Colors.pinkAccent,
                                            ),
                                          );
                                        },
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            formatDuration(remaining),
                                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            isRunning ? 'Studying' : (isCompleted ? 'Completed' : 'Ready'),
                                            style: TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          _presetChoice(25),
                                          _presetChoice(50),
                                          _presetChoice(15),
                                          Chip(label: Text('Custom: $customMinutes min'), backgroundColor: Colors.white12),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Slider(
                                              min: 5,
                                              max: 90,
                                              divisions: 17,
                                              value: customMinutes.toDouble(),
                                              activeColor: Color(0xFFFFC1E3),
                                              onChanged: (v) => setState(() => customMinutes = v.round()),
                                              onChangeEnd: (v) => setMinutes(customMinutes),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: isRunning ? pauseTimer : startTimer,
                                            icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                                            label: Text(isRunning ? 'Pause' : 'Start'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFFFFC1E3),
                                              foregroundColor: Colors.black,
                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            onPressed: resetSession,
                                            icon: Icon(Icons.replay, color: Colors.white70),
                                            label: Text('Reset'),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: Colors.white12),
                                              padding: EdgeInsets.all(12),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          if (quizUnlocked)
                                            ElevatedButton.icon(
                                              onPressed: openQuiz,
                                              icon: Icon(Icons.quiz),
                                              label: Text('Quiz'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFFB39DDB),
                                                foregroundColor: Colors.black
                                              ),
                                            )
                                        ],
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                            SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation(Color(0xFFFFC1E3)),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.yellow.shade600, size: 18),
                                SizedBox(width: 8),
                                Expanded(child: Text(_currentTip, style: TextStyle(color: Colors.white70, fontSize: 13))),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    Row(
                      children: [
                        Text('Badges', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        if (earned.isEmpty) Text('No badges yet — finish a session!', style: TextStyle(color: Colors.white38)),
                        Spacer(),
                        Text('Total: ${earned.length}', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      height: 86,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: max(earned.length, 3),
                        itemBuilder: (context, i) {
                          if (i >= earned.length) {
                            return Container(
                              width: 86,
                              margin: EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Icon(Icons.lock, color: Colors.white24, size: 30)),
                            );
                          }
                          final b = earned[i];
                          return Container(
                            width: 86,
                            margin: EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [b.color.withOpacity(.14), Colors.white10]),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(b.icon, color: b.color, size: 36),
                                SizedBox(height: 6),
                                Text(b.name, style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 12),

                    Expanded(
                      child: Card(
                        color: Colors.white10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Session History', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Expanded(child: SessionHistoryList(earned: earned)),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Tip: Use presets or slide to a custom duration. Earn badges by completing sessions — open the quiz to test focus.',
                                      style: TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      onCompleteSession();
                                    },
                                    icon: Icon(Icons.flash_on),
                                    label: Text('Demo Reward'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFFAB91)),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _presetChoice(int minutes) {
    final selected = sessionDuration.inMinutes == minutes;
    return ChoiceChip(
      label: Text('$minutes min'),
      selected: selected,
      onSelected: (_) => setMinutes(minutes),
      selectedColor: Color(0xFFFFC1E3),
      backgroundColor: Colors.white10,
      labelStyle: TextStyle(color: selected ? Colors.black : Colors.white),
    );
  }
}

class AnimatedGradient extends StatefulWidget {
  @override
  _AnimatedGradientState createState() => _AnimatedGradientState();
}

class _AnimatedGradientState extends State<AnimatedGradient> {
  double t = 0.0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(milliseconds: 80), (_) {
      setState(() {
        t += 0.01;
        if (t > 1.0) t = 0.0;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c1 = Color.lerp(Color(0xFF0F1020), Color(0xFF070014), sin(t * 2 * pi) * 0.5 + 0.5)!;
    final c2 = Color.lerp(Color(0xFF1B0E2B), Color(0xFF2B0036), cos(t * 2 * pi) * 0.5 + 0.5)!;
    final c3 = Color.lerp(Color(0xFF3A1143), Color(0xFF8E3F9B), sin((t + 0.5) * 2 * pi) * 0.5 + 0.5)!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c1, c2, c3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.6, 1.0],
        ),
      ),
    );
  }
}

class PetalPainter extends CustomPainter {
  final List<Petal> petals;
  PetalPainter({required this.petals});
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in petals) {
      final dx = p.x * size.width;
      final dy = p.y * size.height;
      final rect = Rect.fromCenter(center: Offset(dx, dy), width: p.size, height: p.size * 0.7);
      final grad = RadialGradient(colors: [Color(0xFFFFEFFF), Color(0xFFFFC1E3)]);
      _paint.shader = grad.createShader(rect);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rot);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, 0), width: p.size, height: p.size * 0.6), _paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PetalPainter oldDelegate) => true;
}

class Badge {
  final String name;
  final IconData icon;
  final Color color;
  Badge(this.name, this.icon, this.color);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Badge && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    final bg = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + 2 * pi,
        colors: [color.withOpacity(0.95), color.withOpacity(0.35)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, bg);

    final sweep = 2 * pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, sweep, false, fg);

    if (progress > 0.05) {
      final glow = Paint()..color = color.withOpacity(0.08);
      canvas.drawCircle(center, radius + 6 * progress, glow);
    }
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) => oldDelegate.progress != progress;
}

class AwardDialog extends StatelessWidget {
  final Badge badge;
  final VoidCallback onClose;
  final VoidCallback onOpenQuiz;

  AwardDialog({required this.badge, required this.onClose, required this.onOpenQuiz});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF071018),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [badge.color.withOpacity(.9), Colors.white12]),
              boxShadow: [BoxShadow(color: badge.color.withOpacity(.25), blurRadius: 10, spreadRadius: 1)],
            ),
            child: Center(child: Icon(badge.icon, size: 44, color: Colors.white)),
          ),
          SizedBox(height: 12),
          Text('Badge Unlocked!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text(badge.name, style: TextStyle(fontSize: 16, color: Colors.white70)),
          SizedBox(height: 12),
          Text('Great job! You completed your session and earned this badge.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onClose, child: Text('Close'))),
              SizedBox(width: 8),
              Expanded(child: ElevatedButton(onPressed: onOpenQuiz, child: Text('Take Quiz'))),
            ],
          )
        ]),
      ),
    );
  }
}

class BadgeGalleryDialog extends StatelessWidget {
  final List<Badge> earned;
  final List<Badge> all;

  BadgeGalleryDialog({required this.earned, required this.all});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF071018),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(18.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(
            children: [
              Text('Badge Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Spacer(),
              Text('Earned: ${earned.length}/${all.length}', style: TextStyle(color: Colors.white54)),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: all.map<Widget>((b) {
              final got = earned.contains(b);
              return Opacity(
                opacity: got ? 1.0 : 0.35,
                child: Container(
                  width: 120,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: got ? Colors.white10 : Colors.white12, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      Icon(b.icon, size: 36, color: b.color),
                      SizedBox(height: 8),
                      Text(b.name, style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 6),
                      Text(got ? 'Unlocked' : 'Locked', style: TextStyle(color: Colors.white38, fontSize: 12))
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Close')))
        ]),
      ),
    );
  }
}

class SessionHistoryList extends StatelessWidget {
  final List<Badge> earned;
  SessionHistoryList({required this.earned});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final entries = List.generate(6, (i) {
      final time = now.subtract(Duration(days: i));
      final badge = i < earned.length ? earned[i] : null;
      return {'time': time, 'badge': badge};
    });
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => Divider(color: Colors.white10),
      itemBuilder: (context, i) {
        final item = entries[i];
        final t = item['time'] as DateTime;
        final b = item['badge'] as Badge?;
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: Colors.white10,
            child: b != null ? Icon(b.icon, color: b.color) : Icon(Icons.timer, color: Colors.white24),
          ),
          title: Text(b?.name ?? 'Study session', style: TextStyle(color: Colors.white)),
          subtitle: Text('${t.day}-${t.month}-${t.year}  • ${t.hour}:${t.minute.toString().padLeft(2, '0')}', style: TextStyle(color: Colors.white38)),
          trailing: b != null ? Text('Badge', style: TextStyle(color: Colors.amberAccent)) : null,
        );
      },
    );
  }
}

class QuizDialog extends StatefulWidget {
  final Function(bool) onAnswered;
  QuizDialog({required this.onAnswered});

  @override
  _QuizDialogState createState() => _QuizDialogState();
}

class _QuizDialogState extends State<QuizDialog> {
  final question = "What is the most effective study technique?";
  final options = [
    "Multitasking across subjects",
    "Short focused sessions with breaks (Pomodoro)",
    "Cramming the night before",
    "Never reviewing notes"
  ];
  int? selected;
  bool submitted = false;

  void submit() {
    if (selected == null) return;
    setState(() {
      submitted = true;
    });
    final correct = selected == 1;
    Future.delayed(Duration(milliseconds: 350), () {
      widget.onAnswered(correct);
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF071018),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Focus Quiz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text(question, style: TextStyle(color: Colors.white70)),
          SizedBox(height: 12),
          ...List.generate(options.length, (i) {
            final opt = options[i];
            final sel = selected == i;
            final disabled = submitted;
            return ListTile(
              tileColor: sel ? Colors.white10 : Colors.transparent,
              onTap: disabled
                  ? null
                  : () {
                      setState(() {
                        selected = i;
                      });
                    },
              leading: Radio<int>(
                value: i,
                groupValue: selected,
                onChanged: disabled ? null : (v) => setState(() => selected = v),
                activeColor: Color(0xFFFFC1E3),
              ),
              title: Text(opt, style: TextStyle(color: Colors.white70)),
            );
          }),
          SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text('Close'))),
              SizedBox(width: 8),
              ElevatedButton(onPressed: submit, child: Text('Submit'), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFFC1E3)))
            ],
          )
        ]),
      ),
    );
  }
}
