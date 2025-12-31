
import '../models/food_item.dart';

class FoodIconDetector {
  static String getIcon(String name, FoodCategory category, {String? customIcon}) {
    if (customIcon != null && customIcon.isNotEmpty) {
      return customIcon;
    }

    final lowerName = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    // --- Eggs ---
    if (_matches(lowerName, [r'tamago', r'egg', r'卵', r'玉子', r'たまご', r'タマゴ'])) {
      return '🥚';
    }

    // --- Dairy / Milk ---
    if (_matches(lowerName, [r'milk', r'gyu{0,2}nyu{0,2}', r'牛乳', r'ミルク', r'cream', r'yogurt', r'ヨーグルト'])) {
      return '🥛';
    }
    if (_matches(lowerName, [r'cheese', r'ti-zu', r'chi-zu', r'チーズ'])) {
      return '🧀';
    }

    // --- Vegetables ---
    // Leafy Greens
    if (_matches(lowerName, [
      r'lettuce', r'cabbage', r'spinach', r'komatsuna', r'greens', 
      r'retasu', r'kyabetsu', r'houren[s]+ou',
      r'レタス', r'キャベツ', r'きゃべつ', r'ほうれん草', r'ホウレンソウ', r'小松菜', r'白菜'
    ])) {
      return '🥬';
    }
    // Tomato
    if (_matches(lowerName, [r'tomato', r'トマト', r'とまと'])) {
      return '🍅';
    }
    // Potato/Sweet Potato
    if (_matches(lowerName, [r'potato', r'imo', r'jagaimo', r'satsumaimo', r'芋', r'イモ', r'いも', r'ポテト'])) {
      return '🥔';
    }
    // Onion
    if (_matches(lowerName, [r'onion', r'tamanegi', r'negi', r'玉ねぎ', r'タマネギ', r'たまねぎ', r'ネギ', r'葱'])) {
      return '🧅';
    }
    // Carrot
    if (_matches(lowerName, [r'carrot', r'ninjin', r'人参', r'にんじん', r'ニンジン'])) {
      return '🥕';
    }
    // Corn
    if (_matches(lowerName, [r'corn', r'toumorokoshi', r'コーン', r'トウモロコシ', r'とうもろこし'])) {
      return '🌽';
    }
    // Eggplant
    if (_matches(lowerName, [r'eggplant', r'nasu', r'nasubi', r'茄子', r'ナス', r'なす'])) {
      return '🍆';
    }

    // --- Fruits ---
    if (_matches(lowerName, [r'apple', r'ringo', r'林檎', r'りんご', r'リンゴ'])) {
      return '🍎';
    }
    if (_matches(lowerName, [r'banana', r'バナナ', r'ばなな'])) {
      return '🍌';
    }
    if (_matches(lowerName, [r'grape', r'budou', r'ぶどう', r'ブドウ', r'葡萄'])) {
      return '🍇';
    }
    if (_matches(lowerName, [r'strawberry', r'ichigo', r'苺', r'いちご', r'イチゴ'])) {
      return '🍓';
    }

    // --- Meat ---
    // Chicken
    if (_matches(lowerName, [r'chicken', r'tori', r'bird', r'鶏', r'チキン', r'とり肉', r'鳥肉', r'ササミ', r'mune', r'momo'])) {
      return '🍗';
    }
    // Pig
    if (_matches(lowerName, [r'pork', r'buta', r'豚', r'ポーク'])) {
      return '🐖';
    }
    // Beef
    if (_matches(lowerName, [r'beef', r'gyu', r'ushi', r'cow', r'牛', r'ビーフ', r'steak', r'ステーキ'])) {
      return '🥩';
    }
    // General Meat check if categories match but specific wasn't found
    if (_matches(lowerName, [r'meat', r'niku', r'肉', r'ミンチ', r'hike', r'hiki'])) {
      return '🥩';
    }

    // --- Seafood ---
    if (_matches(
        lowerName, 
        [
          r'fish', r'sakana', r'sashimi', r'sushi', r'魚', r'刺身', r'鮭', r'salmon', r'maguro', r'鮪', r'saba', r'鯖',
          r'san[n]?ma', r'サンマ', r'さんま', r'秋刀魚' // Added sanma/sannma
        ])) {
      return '🐟';
    }
    if (_matches(lowerName, [r'shrimp', r'ebi', r'海老', r'エビ', r'えび'])) {
      return '🦐';
    }
    if (_matches(lowerName, [r'crab', r'kani', r'蟹', r'カニ', r'かに'])) {
      return '🦀';
    }
    if (_matches(lowerName, [r'squid', r'ika', r'烏賊', r'イカ', r'いか', r'ako', r'tako', r'蛸', r'タコ'])) {
      return '🐙';
    }

    // --- Carbs ---
    // Rice
    if (_matches(lowerName, [r'rice', r'kome', r'gohan', r'米', r'ご飯', r'ごはん', r'ライス'])) {
      return '🍚';
    }
    // Bread
    if (_matches(lowerName, [r'bread', r'pan', r'パン', r'食パン', r'baguette', r'バゲット', r'sand', r'サンド'])) {
      return '🍞';
    }
    // Noodles
    if (_matches(lowerName, [r'noodle', r'men', r'pasta', r'spaghetti', r'ramen', r'udon', r'soba', r'麺', r'パスタ', r'ラーメン', r'うどん', r'そば', r'蕎麦'])) {
      return '🍜';
    }

    // --- Others / Drinks ---
    if (_matches(lowerName, [r'beer', r'biru', r'ビール', r'酒', r'sake', r'alcohol'])) {
      return '🍺';
    }
    if (_matches(lowerName, [r'coffee', r'kohi', r'コーヒー', r'珈琲'])) {
      return '☕';
    }
    if (_matches(lowerName, [r'tea', r'ocha', r'茶', r'ティー'])) {
      return '🍵';
    }

    // If no specific match, fall back to category default
    switch (category) {
      case FoodCategory.meat: return '🥩';
      case FoodCategory.dairy: return '🥛';
      case FoodCategory.vegetable: return '🥦';
      case FoodCategory.frozen: return '🧊';
      case FoodCategory.pantry: return '🥫';
      case FoodCategory.other: return '📦';
    }
  }

  static bool _matches(String name, List<String> patterns) {
    for (final pattern in patterns) {
      if (name.contains(RegExp(pattern))) return true;
    }
    return false;
  }

  static const Map<String, List<String>> categorizedIcons = {
     '🥬 野菜': ['🥦', '🥬', '🍅', '🍆', '🌽', '🥕', '🥔', '🧅', '🫑', '🥒', '🧄', '🥜'],
     '🍎 フルーツ': ['🍎', '🍌', '🍇', '🍓', '🍊', '🍋', '🍑', '🍒', '🍍', '🥝', '🍈', '🫐'],
     '🥩 肉': ['🥩', '🍗', '🍖', '🥓', '🌭', '🍔', '🐔', '🐖', '🐄'],
     '🐟 魚介': ['🐟', '🐠', '🦈', '🦀', '🦞', '🦐', '🦑', '🐙', '🍣', '🦪', '🍤'],
     '🍞 パン・穀物': ['🍞', '🥐', '🥖', '🥨', '🥯', '🥞', '🧇', '🍚', '🍙', '🍘', '🍛', '🍜', '🍝'],
     '🥛 乳製品・卵': ['🥛', '🧀', '🥚', '🍦', '🧈', '🍳'],
     '🍰 お菓子・デザート': ['🍫', '🍿', '🍩', '🍪', '🎂', '🍰', '🧁', '🍮', '🍡', '🍬', '🍭'],
     '🍵 飲み物': ['☕', '🍵', '🧃', '🍺', '🍷', '🧋', '🥤'],
     '📦 その他': ['🧊', '🥫', '📦', '🍳', '🥡', '🍱'],
  };

  // Flatten for backward compatibility if needed
  static List<String> get presetIcons => categorizedIcons.values.expand((e) => e).toList();
}
