
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _onIntroEnd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false); // Mark as done

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "レシートをポン！",
          body: "面倒な入力はもう不要。レシートを撮影するだけで、買った食材が自動でリストに追加されます。「あれ、まだあったっけ？」買い出し中もスマホでチェックできます。",
          image: const Center(child: Icon(Icons.receipt_long, size: 100, color: Colors.orange)),
          decoration: const PageDecoration(
            pageColor: Colors.white,
            imagePadding: EdgeInsets.only(top: 24),
            bodyTextStyle: TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        PageViewModel(
          title: "期限を管理",
          body: "「賞味期限、いつだっけ？」期限が近づくと色が変わってお知らせ。冷蔵庫を開けなくても、スマホでパッと確認できます。",
          image: const Center(child: Icon(Icons.access_time, size: 100, color: Colors.green)),
          decoration: const PageDecoration(
            pageColor: Colors.white,
             imagePadding: EdgeInsets.only(top: 24),
             bodyTextStyle: TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        PageViewModel(
          title: "通知でお知らせ",
          body: "うっかり廃棄をゼロに。「1週間前」「3日前」など、あなたの生活スタイルに合わせて通知タイミングを自由に設定できます。",
          image: const Center(child: Icon(Icons.notifications_active, size: 100, color: Colors.blue)),
          decoration: const PageDecoration(
            pageColor: Colors.white,
             imagePadding: EdgeInsets.only(top: 24),
             bodyTextStyle: TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        PageViewModel(
          title: "好きな順番に並べ替え",
          body: "よく使う食材を上に置きたい？期限順だけでなく、ドラッグ＆ドロップで自分だけのカスタム順に並べ替えることができます。",
          image: const Center(child: Icon(Icons.swap_vert, size: 100, color: Colors.purple)),
          decoration: const PageDecoration(
            pageColor: Colors.white,
             imagePadding: EdgeInsets.only(top: 24),
             bodyTextStyle: TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        PageViewModel(
          title: "アイコンをカスタマイズ",
          body: "自動で設定されるアイコンがしっくりこない？食材のアイコンをタップすれば、60種類以上の絵文字から好きなものに変更できます。",
          image: const Center(child: Icon(Icons.emoji_food_beverage, size: 100, color: Colors.teal)),
          decoration: const PageDecoration(
            pageColor: Colors.white,
             imagePadding: EdgeInsets.only(top: 24),
             bodyTextStyle: TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      showSkipButton: true,
      skip: const Text("スキップ"),
      next: const Icon(Icons.arrow_forward),
      done: const Text("はじめる", style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: Theme.of(context).primaryColor,
        color: Colors.black26,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }
}
