// lib/data/coping_tips.dart

import 'dart:math';

// A simple data model for a coping tip.
class CopingTip {
  final String title;
  final String body;

  const CopingTip({required this.title, required this.body});
}

// A static class to hold and provide the list of tips.
class CopingTipsData {
  static final List<CopingTip> _tips = [
    const CopingTip(
      title: "Focus on Your 'Why'",
      body:
          "Take a moment to remember your core reason for quitting. Is it for your health, your family, or your finances? Keep that reason in sharp focus.",
    ),
    const CopingTip(
      title: "The 5-Minute Rule",
      body:
          "Tell yourself you will wait just five more minutes before smoking. The urge is temporary and will likely lessen or pass entirely within that time.",
    ),
    const CopingTip(
      title: "Drink a Full Glass of Water",
      body:
          "Sip it slowly. This simple action satisfies the hand-to-mouth habit, hydrates you, and gives your body a different sensation to focus on.",
    ),
    const CopingTip(
      title: "Health Fact: 20 Minutes Later...",
      body:
          "In just 20 minutes after your last cigarette, your heart rate and blood pressure have already started to drop back to normal levels. You're healing right now.",
    ),
    const CopingTip(
      title: "Change Your Scenery",
      body:
          "If you're in a place where you usually smoke, get up and move. Go to a different room, step outside, or simply walk to the other side of the room to break the association.",
    ),
    const CopingTip(
      title: "Financial Fact: A Quick Calculation",
      body:
          "Think about the cost of a single pack. What else could you buy with that money right now? A coffee? A snack? A movie ticket? This craving has a real cost.",
    ),
    const CopingTip(
      title: "Health Fact: 12 Hours Later...",
      body:
          "Within 12 hours, the toxic carbon monoxide level in your blood drops to normal. Your body's cells are already getting more of the oxygen they need to thrive.",
    ),
    const CopingTip(
      title: "The Power of a Deep Breath",
      body:
          "Even one slow, deep breath can interrupt a craving. Inhale through your nose for four counts, and exhale slowly through your mouth. It resets your nervous system.",
    ),
  ];

  // A method to get a random tip from the list.
  static CopingTip getRandomTip() {
    final random = Random();
    return _tips[random.nextInt(_tips.length)];
  }
}
