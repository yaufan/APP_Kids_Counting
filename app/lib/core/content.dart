/// The names of everything on the farm (docs/design.md): the six places,
/// the animals, the things that are counted and their measure words, and the
/// 回真實生活 cards.
library;

/// 小小農夫 (3 to 4) or 小農夫 (4 to 5): docs/design.md 「兩個難度的差別」.
enum Level {
  small('小小農夫', '3～4 歲', 5),
  big('小農夫', '4～5 歲', 10);

  const Level(this.zh, this.ages, this.countTo);

  final String zh;
  final String ages;

  /// How far it counts, unless a parent changed it.
  final int countTo;
}

/// The six places on the farm, in the order they stand on the farm path.
enum Place {
  chicks('餵小雞'),
  eggs('撿雞蛋'),
  fruit('摘水果'),
  share('分點心'),
  garden('排排隊'),
  market('去市場');

  const Place(this.zh);

  final String zh;

  /// The free version has these (docs/design.md 「以後上架和收費」, the user's 5a).
  static const free = {Place.chicks, Place.eggs, Place.fruit};
}

/// Something that is counted: its picture (`assets/art/food/<id>.svg` or
/// `animals/`), its name, and the measure word said with a number (「7 顆蛋」).
class Thing {
  const Thing(this.id, this.zh, this.unit, {this.art});

  final String id;
  final String zh;

  /// The measure word (量詞).
  final String unit;
  final String? art;

  String get picture => art ?? 'food/$id';
}

abstract final class Things {
  static const egg = Thing('egg', '蛋', '顆');
  static const corn = Thing('corn', '玉米', '顆');
  static const chick = Thing('chick', '小雞', '隻', art: 'animals/chick');
  static const melon = Thing('melon', '西瓜', '個');
  static const pumpkin = Thing('pumpkin', '南瓜', '顆');

  /// 摘水果: six Taiwanese fruit, one kind per question.
  static const fruit = [
    Thing('guava', '芭樂', '顆'),
    Thing('banana', '香蕉', '根'),
    Thing('mango', '芒果', '顆'),
    Thing('orange', '橘子', '顆'),
    Thing('waxapple', '蓮霧', '顆'),
    Thing('papaya', '木瓜', '顆'),
  ];

  /// 分點心: the snacks.
  static const snacks = [
    Thing('potato', '烤地瓜', '個'),
    Thing('cob', '玉米', '根'),
    Thing('banana', '香蕉', '根'),
    Thing('bun', '肉包', '個'),
  ];

  /// 排排隊: what grows in the vegetable patch.
  static const veg = [
    Thing('cabbage', '高麗菜', '顆'),
    Thing('carrot', '紅蘿蔔', '根'),
    Thing('cob', '玉米', '根'),
    Thing('eggplant', '茄子', '條'),
  ];
}

/// The farm animals that come to buy, eat or cross the bridge.
enum Animal {
  sheep('小羊', 'baa'),
  rabbit('小兔', 'sniff'),
  duck('小鴨', 'quack'),
  pig('小豬', 'oink'),
  chick('小雞', 'cheep');

  const Animal(this.zh, this.sound);

  final String zh;

  /// Its sound (`assets/sounds/<sound>.wav`).
  final String sound;

  String get picture => 'animals/$name';

  /// The ones who come to 摘水果 with a sign.
  static const customers = [Animal.sheep, Animal.rabbit, Animal.duck];

  /// The ones who eat in 分點心 (mostly the piglets).
  static const eaters = [Animal.pig, Animal.pig, Animal.sheep, Animal.chick];
}

/// A 回真實生活 card: something to do away from the screen, with a picture.
class LifeCard {
  const LifeCard(this.id, this.place, this.text, this.picture);

  final String id;
  final Place place;
  final String text;

  /// Under assets/art/, without .svg.
  final String picture;
}

/// Five cards for each place (docs/design.md 「回真實生活卡」): all things to
/// do at home, at the table, at the market or the park, nothing to buy.
const lifeCards = [
  LifeCard('chopsticks', Place.chicks, '吃飯的時候，幫每個人放一雙筷子，一人一雙。', 'ui/card_chopsticks'),
  LifeCard('slippers', Place.chicks, '數數看，家裡門口有幾雙拖鞋？', 'ui/card_slippers'),
  LifeCard('spoons', Place.chicks, '吃晚飯的時候，幫每個人放一支湯匙。數數看，放了幾支？', 'ui/card_spoons'),
  LifeCard('cups', Place.chicks, '倒水的時候，一個人一個杯子。數數看，要拿幾個杯子？', 'ui/card_cups'),
  LifeCard('birds', Place.chicks, '去公園的時候，數數看看到幾隻小鳥。', 'ui/card_birds'),
  LifeCard('fridge', Place.eggs, '打開冰箱，數數看有幾顆蛋。', 'food/egg'),
  LifeCard('eggrack', Place.eggs, '幫忙把買回來的蛋，一顆一顆放進冰箱的蛋架。', 'ui/card_eggrack'),
  LifeCard('buttons', Place.eggs, '穿衣服的時候，數數看衣服上有幾顆扣子。', 'ui/card_buttons'),
  LifeCard('fingers', Place.eggs, '伸出一隻手：一、二、三、四、五，五根手指頭！再伸出另一隻手數數看。', 'ui/card_hand'),
  LifeCard('stairs', Place.eggs, '上樓梯的時候，一階一階數。', 'ui/card_stairs'),
  LifeCard('bag', Place.fruit, '去市場買水果時，數數看袋子裡有幾顆。', 'food/orange'),
  LifeCard('grapes', Place.fruit, '和家人比一比：誰碗裡的葡萄比較多？', 'ui/card_bowl'),
  LifeCard('plates', Place.fruit, '吃水果的時候，數數看盤子裡有幾片。', 'food/guava'),
  LifeCard('cars', Place.fruit, '在路邊等車時，數數看經過幾台公車。', 'ui/card_bus'),
  LifeCard('books', Place.fruit, '睡覺前，挑三本書，數數看，一、二、三！', 'ui/card_books'),
  LifeCard('cookies', Place.share, '把一包餅乾分給家人，一人一片，輪流分，看看每個人是不是一樣多。', 'ui/card_cookie'),
  LifeCard('toys', Place.share, '和朋友分玩具：你一個、我一個，輪流拿。', 'ui/card_blocks'),
  LifeCard('fruitshare', Place.share, '切好的水果，分給家裡每個人，一人兩片。', 'food/papaya'),
  LifeCard('table', Place.share, '擺碗筷的時候，一個位子放一個碗。', 'ui/card_bowl'),
  LifeCard('stickers', Place.share, '分貼紙：給媽媽一張、給爸爸一張、給自己一張。', 'ui/card_star'),
  LifeCard('shoes', Place.garden, '把家裡的鞋子排一排：大的、小的、大的、小的。', 'ui/card_slippers'),
  LifeCard('clap', Place.garden, '一起拍手：拍、拍、跺腳；拍、拍、跺腳！', 'ui/card_hand'),
  LifeCard('tall', Place.garden, '家裡的人排一排，從矮的排到高的。', 'ui/card_family'),
  LifeCard('steps', Place.garden, '上樓梯的時候一階一階數：一、二、三……', 'ui/card_stairs'),
  LifeCard('socks', Place.garden, '收衣服的時候，把襪子一雙一雙配好。', 'ui/card_socks'),
  LifeCard('tidy', Place.market, '收玩具時數數看：放進箱子幾個？拿出來一個，還剩幾個？', 'ui/card_blocks'),
  LifeCard('bus', Place.market, '搭公車時，數數看上車幾個人、下車幾個人。', 'ui/card_bus'),
  LifeCard('shopping', Place.market, '去超市的時候，幫忙拿三顆蘋果放進籃子。', 'ui/card_basket'),
  LifeCard('oneMore', Place.market, '吃飯的時候數數看碗裡有幾塊紅蘿蔔，再加一塊是幾塊？', 'food/carrot'),
  LifeCard('pay', Place.market, '玩買東西的遊戲：一個西瓜一塊錢，買兩個要給幾塊？', 'food/melon'),
];

List<LifeCard> cardsOf(Place p) => [for (final c in lifeCards) if (c.place == p) c];

LifeCard? cardById(String id) {
  for (final c in lifeCards) {
    if (c.id == id) return c;
  }
  return null;
}
