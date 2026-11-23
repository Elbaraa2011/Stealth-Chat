import 'package:flutter/material.dart';

class IgUser {
  IgUser({
    required this.avatar,
    required this.handle,
    this.isCloseFriend = false,
    this.isVerified = false,
    this.isOnline = false,
    this.name = '',
    this.posts = 0,
    this.followers = 0,
    this.following = 0,
  });
  final String avatar;
  final String handle;
  final bool isCloseFriend;
  final bool isVerified;
  final bool isOnline;
  final String name;
  final int posts;
  final int followers;
  final int following;
}

// ----------------------------------------------------------------- feed / DM accounts
IgUser me = IgUser(
  avatar: 'assets/images/UsersPfps/IMG_1088.jpeg',
  handle: 'stealth.kh',
  isVerified: false,
  isOnline: false,
  name: 'Stealth.kh',
  posts: 0,
  followers: 90,
  following: 229,
);

IgUser lexi = IgUser(
  avatar: '',
  handle: 'lexi_designs_22',
  isVerified: false,
  isOnline: false,
  name: 'Lexi',
  posts: 1230,
  followers: 45230,
  following: 156,
);

IgUser theo = IgUser(
  avatar: '',
  handle: 'theogaming',
  isVerified: true,
  isOnline: true,
  name: 'Theo',
  posts: 894,
  followers: 23450,
  following: 312,
);

IgUser maria = IgUser(
  avatar: '',
  handle: 'maria_arts',
  isVerified: false,
  isOnline: false,
  name: 'Maria',
  posts: 672,
  followers: 12890,
  following: 89,
);

IgUser james = IgUser(
  avatar: '',
  handle: 'james_footy',
  isVerified: false,
  isOnline: false,
  name: 'James',
  posts: 312,
  followers: 8760,
  following: 234,
);
IgUser elbaraa = IgUser(
  avatar: '',
  handle: 'barbarinio2011',
  isVerified: false,
  isOnline: false,
  name: 'Elbaraa',
  posts: 189,
  followers: 3420,
  following: 56,
);

IgUser bellingham = IgUser(
  avatar: '',
  handle: 'bellingham',
  isVerified: false,
  isOnline: false,
  name: 'Bellingham',
  posts: 45,
  followers: 12340,
  following: 234,
);

IgUser messi = IgUser(
  avatar: '',
  handle: 'messi',
  isVerified: false,
  isOnline: false,
  name: 'Lionel Messi',
  posts: 87,
  followers: 250000000,
  following: 12,
);

IgUser ronaldo = IgUser(
  avatar: '',
  handle: 'ronaldo',
  isVerified: false,
  isOnline: false,
  name: 'Cristiano Ronaldo',
  posts: 156,
  followers: 500000000,
  following: 15,
);

// --------------------------------------------------------- reels — WhatsApp imports
// Caption screenshots provided by the user.

// Reel 1
// Video:   WhatsApp Video 2026-11-01 at 8.07.08 AM.mp4
// Caption: "😂😭"
IgUser thatlovingfam = IgUser(
  avatar: '',
  handle: 'thatlovingfam',
  isVerified: false,
  isOnline: false,
  name: 'That Loving Fam',
  posts: 240,
  followers: 191000,
  following: 412,
);

// Reel 2
// Video:   WhatsApp Video 2026-11-01 at 8.07.12 AM.mp4
// Caption: "What a strike, Harry! 🥵"
IgUser fcbayern = IgUser(
  avatar: 'assets/images/avatar_posts/fcbayern.jpg',
  handle: 'fcbayern',
  isVerified: true,
  isOnline: false,
  name: 'FC Bayern München',
  posts: 4200,
  followers: 52000000,
  following: 334,
);

// Reel 3
// Video:   WhatsApp Video 2026-11-01 at 8.07.16 AM.mp4
// Caption: "An unforgettable strike 🚀"
IgUser liverpoolfc = IgUser(
  avatar: 'assets/images/avatar_posts/liverpoolfc.jpg',
  handle: 'liverpoolfc',
  isVerified: true,
  isOnline: false,
  name: 'Liverpool FC',
  posts: 6100,
  followers: 58000000,
  following: 221,
);

// Reel 4
// Video:   WhatsApp Video 2026-11-01 at 8.07.24 AM.mp4
// Caption: "🪄💫"
IgUser alahly = IgUser(
  avatar: '',
  handle: 'alahly',
  isVerified: false,
  isOnline: false,
  name: 'Al Ahly SC',
  posts: 1840,
  followers: 31200000,
  following: 188,
);

// Reel 5
// Video:   WhatsApp Video 2026-11-01 at 8.06.23 AM.mp4
// Caption: "Because we just cannot post enough about International Day..."
IgUser misqatar = IgUser(
  avatar: '',
  handle: 'mis.qatar',
  isVerified: false,
  isOnline: false,
  name: 'MIS Qatar',
  posts: 380,
  followers: 421000,
  following: 890,
);

class IgStory {
  IgStory(this.mediaId, this.timeAgo);

  /// Local asset path of the story frame.
  final String mediaId;
  final String timeAgo;
}

class ExploreTile {
  ExploreTile({
    required this.igUser,
    this.title = 'Explore',
    this.icon = Icons.person,
    this.image = '',
    this.span = 1,
    this.caption = '',
    this.id = '',
  });
  final IgUser igUser;
  final String title;
  final IconData icon;
  final String image;
  final int span;
  final String caption;
  final String id;
}

class StoryGroup {
  StoryGroup(this.user, this.items, this.stories);
  final IgUser user;
  final List<IgPost> items;
  final List<IgStory> stories;
}

class IgPost {
  IgPost({
    required this.id,
    required this.user,
    required this.media,
    this.caption = '',
    this.likes = 0,
    this.age,
    this.location,
  });
  final String id;
  final IgUser user;
  final List<String> media;
  final String caption;
  final int likes;
  final String? age;
  final String? location;
}

class IgReel {
  IgReel({
    required this.id,
    required this.user,
    required this.video,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.audio,
    required this.audioUser,
    this.verified = false,
  });
  final String id;
  final IgUser user;
  final String video;
  final String caption;
  final int likes;
  final int comments;
  final String audio;
  final String audioUser;
  final bool verified;
}

class DmThread {
  DmThread({
    required this.user,
    required this.preview,
    this.age = '',
    this.unread = false,
    this.seen = false,
  });
  final IgUser user;
  final String preview;
  final String age;
  final bool unread;
  final bool seen;
}

class IgNotification {
  IgNotification({
    required this.user,
    required this.action,
    this.age = '',
    this.followBack = false,
    this.thumb,
  });
  final IgUser user;
  final String action;
  final String age;
  final bool followBack;
  final String? thumb;
}

// ---------------------------------------------------------------- stories
// The story tray is clubs, newsrooms and football insiders only — the same
// mix Instagram serves on a real account: a club account, a transfer
// reporter, a news organisation and a football media brand.

IgUser realmadrid = IgUser(
  avatar: 'assets/images/stories/realmadrid_avatar.png',
  handle: 'realmadrid',
  isVerified: true,
  isOnline: false,
  name: 'Real Madrid C.F.',
  posts: 4126,
  followers: 178000000,
  following: 47,
);

IgUser fabrizioromano = IgUser(
  avatar: 'assets/images/stories/fabrizioromano_avatar.png',
  handle: 'fabrizioromano',
  isVerified: true,
  isOnline: false,
  name: 'Fabrizio Romano',
  posts: 21840,
  followers: 34800000,
  following: 812,
);

IgUser cnn = IgUser(
  avatar: 'assets/images/stories/cnn_avatar.png',
  handle: 'cnn',
  isVerified: true,
  isOnline: false,
  name: 'CNN',
  posts: 61240,
  followers: 21600000,
  following: 118,
);

IgUser fourThreeThree = IgUser(
  avatar: 'assets/images/stories/a433_avatar.png',
  handle: '433',
  isVerified: true,
  isOnline: false,
  name: '433',
  posts: 18420,
  followers: 8400000,
  following: 96,
);

IgUser cristianoRonaldo = IgUser(
  avatar: 'assets/images/stories/CR7 avatar.jpeg',
  handle: 'cr7',
  isVerified: true,
  isOnline: false,
  name: 'Cristiano Ronaldo',
  posts: 28400,
  followers: 628000000,
  following: 608,
);

IgUser bbc = IgUser(
  avatar: 'assets/images/stories/BBC avatar.jpeg',
  handle: 'bbc',
  isVerified: true,
  isOnline: false,
  name: 'BBC',
  posts: 61240,
  followers: 21600000,
  following: 118,
);

IgUser viniJr = IgUser(
  avatar: 'assets/images/stories/Vini Jr avatar.jpeg',
  handle: 'vini_jr',
  isVerified: true,
  isOnline: false,
  name: 'Vini Jr',
  posts: 7540,
  followers: 22400000,
  following: 132,
);

IgUser courtious = IgUser(
  avatar: 'assets/images/stories/Cortious avatar.jpeg',
  handle: 'courtious',
  isVerified: false,
  isOnline: false,
  name: 'Courtious',
  posts: 1880,
  followers: 8420000,
  following: 411,
);

IgUser lunin = IgUser(
  avatar: 'assets/images/stories/Lunin avatar.jpeg',
  handle: 'lunin',
  isVerified: false,
  isOnline: false,
  name: 'Lunin',
  posts: 320,
  followers: 12400000,
  following: 289,
);

IgUser adidas = IgUser(
  avatar: 'assets/images/stories/Addidas avatar.jpeg',
  handle: 'adidas',
  isVerified: true,
  isOnline: false,
  name: 'adidas',
  posts: 4280,
  followers: 38600000,
  following: 212,
);

var storyGroups = [
  StoryGroup(realmadrid, [], [
    IgStory('assets/images/stories/realmadrid_1.jpg', '50m'),
    IgStory('assets/images/stories/realmadrid_2.jpg', '48m'),
    IgStory('assets/images/stories/realmadrid_3.jpg', '46m'),
    IgStory('assets/images/stories/realmadrid_4.jpg', '44m'),
    IgStory('assets/images/stories/realmadrid_5.jpg', '41m'),
  ]),
  StoryGroup(fabrizioromano, [], [
    IgStory('assets/images/stories/fabrizioromano_1.jpg', '17h'),
    IgStory('assets/images/stories/fabrizioromano_2.jpg', '16h'),
    IgStory('assets/images/stories/fabrizioromano_3.jpg', '14h'),
    IgStory('assets/images/stories/fabrizioromano_4.jpg', '11h'),
    IgStory('assets/images/stories/fabrizioromano_5.jpg', '8h'),
    IgStory('assets/images/stories/fabrizioromano_6.jpg', '5h'),
  ]),
  StoryGroup(cnn, [], [
    IgStory('assets/images/stories/cnn_1.jpg', '20h'),
    IgStory('assets/images/stories/cnn_2.jpg', '19h'),
    IgStory('assets/images/stories/cnn_3.jpg', '15h'),
    IgStory('assets/images/stories/cnn_4.jpg', '12h'),
    IgStory('assets/images/stories/cnn_5.jpg', '9h'),
  ]),
  StoryGroup(fourThreeThree, [], [
    IgStory('assets/images/stories/a433_1.jpg', '19h'),
  ]),
  StoryGroup(
    cristianoRonaldo,
    [],
    [IgStory('assets/images/stories/cr7_1.jpg', '23h ago')],
  ),
  StoryGroup(
    bbc,
    [],
    [
      IgStory('assets/images/stories/bbc_1.jpg', '3h ago'),
      IgStory('assets/images/stories/bbc_2.jpg', '2h ago'),
      IgStory('assets/images/stories/bbc_3.jpg', '1h ago'),
      IgStory('assets/images/stories/bbc_4.jpg', '22m ago'),
    ],
  ),
  StoryGroup(
    adidas,
    [],
    [
      IgStory('assets/images/stories/adidas_1.jpg', '8h ago'),
    ],
  ),
  StoryGroup(
    lunin,
    [],
    [
      IgStory('assets/images/stories/lunin_1.jpg', '4h ago'),
    ],
  ),
  StoryGroup(
    courtious,
    [],
    [
      IgStory('assets/images/stories/Cortious avatar.jpeg', '2h ago'),
    ],
  ),
  StoryGroup(
    viniJr,
    [],
    [
      IgStory('assets/images/stories/vini_1.jpg', '1h ago'),
    ],
  ),
];

var exploreTiles = [
  ExploreTile(
    igUser: lexi,
    id: 'explore-0',
    title: 'Recent',
    icon: Icons.person,
    image: '',
    span: 1,
    caption: '',
  ),
  ExploreTile(
    igUser: theo,
    id: 'explore-1',
    title: 'Gaming',
    icon: Icons.person,
    image: '',
    span: 1,
    caption: '',
  ),
  ExploreTile(
    igUser: maria,
    id: 'explore-2',
    title: 'Art',
    icon: Icons.person,
    image: '',
    span: 1,
    caption: '',
  ),
  ExploreTile(
    igUser: james,
    id: 'explore-3',
    title: 'Sports',
    icon: Icons.person,
    image: '',
    span: 1,
    caption: '',
  ),
];

// ------------------------------------------------ real accounts in the feed
// Handles, avatars, captions and like counts below were scraped from the ten
// posts themselves, so the feed is a one-to-one mirror of the real thing.

IgUser brfootball = IgUser(
  avatar: 'assets/images/avatar_posts/brfootball.jpg',
  handle: 'brfootball',
  isVerified: true,
  isOnline: false,
  name: 'B/R Football',
  posts: 56601,
  followers: 16000000,
  following: 412,
);

IgUser bestoffootball = IgUser(
  avatar: 'assets/images/avatar_posts/bestoffootball.jpg',
  handle: 'bestoffootball',
  isVerified: false,
  isOnline: false,
  name: 'Best of Football',
  posts: 14097,
  followers: 5000000,
  following: 268,
);

IgUser arsenal = IgUser(
  avatar: 'assets/images/avatar_posts/arsenal.jpg',
  handle: 'arsenal',
  isVerified: true,
  isOnline: false,
  name: 'Arsenal',
  posts: 27381,
  followers: 32500000,
  following: 178,
);

IgUser chelseafc = IgUser(
  avatar: 'assets/images/avatar_posts/chelseafc.jpg',
  handle: 'chelseafc',
  isVerified: true,
  isOnline: false,
  name: 'Chelsea FC',
  posts: 31075,
  followers: 44400000,
  following: 196,
);

IgUser premierleague = IgUser(
  avatar: 'assets/images/avatar_posts/premierleague.jpg',
  handle: 'premierleague',
  isVerified: true,
  isOnline: false,
  name: 'Premier League',
  posts: 43064,
  followers: 80600000,
  following: 88,
);

IgUser laliga = IgUser(
  avatar: 'assets/images/avatar_posts/laliga.jpg',
  handle: 'laliga',
  isVerified: true,
  isOnline: false,
  name: 'LALIGA',
  posts: 86193,
  followers: 55800000,
  following: 124,
);

IgUser harrykane = IgUser(
  avatar: 'assets/images/avatar_posts/harrykane.jpg',
  handle: 'harrykane',
  isVerified: true,
  isOnline: false,
  name: 'Harry Kane',
  posts: 2026,
  followers: 21300000,
  following: 341,
);

var feedPosts = [
  IgPost(
    id: 'post-001',
    user: brfootball,
    media: ['assets/images/posts/post01.jpg'],
    caption: 'One man, two wins, 14 years apart 🫶',
    likes: 15443,
    age: '2h',
  ),
  IgPost(
    id: 'post-002',
    user: bestoffootball,
    media: ['assets/images/posts/post02.jpg'],
    caption: '9 straight games without a win for Manchester United 😱',
    likes: 46208,
    age: '4h',
    location: 'London, United Kingdom',
  ),
  IgPost(
    id: 'post-003',
    user: arsenal,
    media: ['assets/images/posts/post03.jpg'],
    caption: 'Pulling up the big 3️⃣0️⃣0️⃣',
    likes: 112488,
    age: '6h',
  ),
  IgPost(
    id: 'post-004',
    user: chelseafc,
    media: ['assets/images/posts/post04.jpg'],
    caption: 'Wishing Moises Caicedo a very happy birthday! 💙',
    likes: 63213,
    age: '8h',
  ),
  IgPost(
    id: 'post-005',
    user: realmadrid,
    media: ['assets/images/posts/post05.jpg'],
    caption: '😘 @judebellingham 😘\n#RacingRealMadrid',
    likes: 589789,
    age: '10h',
    location: 'El Sardinero',
  ),
  IgPost(
    id: 'post-006',
    user: fcbayern,
    media: ['assets/images/posts/post06.jpg'],
    caption: 'We keep pushing 🔥\n\nThe Bundesliga table after Matchday 8. 📊',
    likes: 27803,
    age: '12h',
  ),
  IgPost(
    id: 'post-007',
    user: premierleague,
    media: ['assets/images/posts/post07.jpg'],
    caption:
        '@arsenal are only the second team to reach 300 Premier League away wins, after @manutd!',
    likes: 88040,
    age: '1d',
  ),
  IgPost(
    id: 'post-008',
    user: laliga,
    media: ['assets/images/posts/post08.jpg'],
    caption: 'Unaí Simón Mendibil. 🦁🏆\n\n#AthleticRealSociedad #LALIGAESPORTS',
    likes: 25038,
    age: '1d',
  ),
  IgPost(
    id: 'post-009',
    user: harrykane,
    media: ['assets/images/posts/post09.jpg'],
    caption:
        'Really proud to share the Ballon d’Or with all the fans last night. The support you’ve shown me since I signed for @fcbayern has been incredible! 🙌❤️',
    likes: 527197,
    age: '2d',
  ),
  IgPost(
    id: 'post-010',
    user: arsenal,
    media: ['assets/images/posts/post10.jpg'],
    caption: 'BIG PERFORMANCE. BIG WIN.',
    likes: 361136,
    age: '3d',
    location: 'Anfield Stadium, Liverpool',
  ),
];

// ---------------------------------------------------------- video reels (WhatsApp)
// Videos were dropped into assets/videos/ from the user's WhatsApp files.
// Captions were read off the 5 screenshots the user sent; each reel keeps
// the uploaded cover frame as its thumbnail so the grid reads like real IG.
var reels = [
  IgReel(
    id: 'reel-01',
    user: thatlovingfam,
    video: 'assets/videos/thatlovingfam.mp4',
    caption: '😂😭',
    likes: 191000,
    verified: false,
    comments: 3176,
    audio: 'Trashy • Reach Po',
    audioUser: 'stbank',
  ),
  IgReel(
    id: 'reel-02',
    user: fcbayern,
    video: 'assets/videos/fcbayern.mp4',
    caption: 'What a strike, Harry! 🥵',
    likes: 435000,
    verified: true,
    comments: 725,
    audio: 'Dark Eyes',
    audioUser: 'Tony Dark',
  ),
  IgReel(
    id: 'reel-03',
    user: liverpoolfc,
    video: 'assets/videos/liverpoolfc.mp4',
    caption: 'An unforgettable strike 🚀',
    likes: 209000,
    verified: true,
    comments: 312,
    audio: 'Paisajes Futuros (Fut)',
    audioUser: 'ico',
  ),
  IgReel(
    id: 'reel-04',
    user: alahly,
    video: 'assets/videos/alahly.mp4',
    caption: '🪄💫',
    likes: 27200,
    verified: false,
    comments: 190,
    audio: 'magic loop',
    audioUser: 'alahly_sounds',
  ),
  IgReel(
    id: 'reel-05',
    user: misqatar,
    video: 'assets/videos/mis_qatar.mp4',
    caption: 'Because we just cannot post enough about International Day...',
    likes: 43,
    verified: false,
    comments: 3,
    audio: 'celebration vibes',
    audioUser: 'mis_qatar',
  ),
];

// ------------------------------------------------------------ DMs (actual users)
// Ten users mapped to UsersPfps images only

IgUser wisam = IgUser(
  avatar: 'assets/images/UsersPfps/IMG_1088.jpeg',
  handle: 'wisam.k123',
  isVerified: false,
  isOnline: false,
  name: 'Wisam.kh',
  posts: 0,
  followers: 90,
  following: 229,
);

IgUser r2d1q = IgUser(
  avatar: 'assets/images/UsersPfps/IMG_1089.jpeg',
  handle: 'r2d1q',
  isVerified: false,
  isOnline: false,
  name: 'Rad',
  posts: 0,
  followers: 823,
  following: 1135,
);

IgUser asmaagaber = IgUser(
  avatar: 'assets/images/UsersPfps/IMG_1090.jpeg',
  handle: 'asmaagaber22',
  isVerified: false,
  isOnline: false,
  name: 'Asmaa Gaber',
  posts: 140,
  followers: 550,
  following: 1941,
);

IgUser keithlasono = IgUser(
  avatar: 'assets/images/UsersPfps/IMG_1091.jpeg',
  handle: 'keithlasono',
  isVerified: false,
  isOnline: false,
  name: 'keithlasono',
  posts: 1,
  followers: 354,
  following: 1355,
);

IgUser gabarmohammad = IgUser(
  avatar: 'assets/images/UsersPfps/IMG_1092.jpeg',
  handle: 'gabar.mohammad',
  isVerified: false,
  isOnline: false,
  name: 'Mohammad Gabar',
  posts: 2,
  followers: 201,
  following: 496,
);

IgUser fwmoayaad = IgUser(
  avatar: 'assets/images/UsersPfps/IMG_1093.jpeg',
  handle: 'fwmoayaad',
  isVerified: false,
  isOnline: false,
  name: 'Mo',
  posts: 0,
  followers: 16,
  following: 31,
);

IgUser ahmadelsous = IgUser(
  avatar: 'assets/images/UsersPfps/85844.jpg',
  handle: 'ahmad_elsous',
  isVerified: false,
  isOnline: false,
  name: 'Ahmad el sous',
  posts: 0,
  followers: 204,
  following: 940,
);

IgUser xelshiekh = IgUser(
  avatar: 'assets/images/UsersPfps/IMG_1094.jpeg',
  handle: 'xelshiekh_7',
  isVerified: false,
  isOnline: false,
  name: 'Elshiekh Omer',
  posts: 0,
  followers: 335,
  following: 2646,
);

IgUser wtvysf11 = IgUser(
  avatar: 'assets/images/UsersPfps/IMG_1097.jpeg',
  handle: 'wtv.ysf11',
  isVerified: false,
  isOnline: false,
  name: 'wtv.ysf11',
  posts: 0,
  followers: 181,
  following: 631,
);

IgUser txaha14 = IgUser(
  avatar: 'assets/images/UsersPfps/IMG_1098.jpeg',
  handle: 'txaha14',
  isVerified: false,
  isOnline: false,
  name: 'taahaali',
  posts: 0,
  followers: 1158,
  following: 2920,
);

List<IgUser> accounts = [
  lexi, theo, maria, james, elbaraa, bellingham, messi, ronaldo,
  thatlovingfam, fcbayern, liverpoolfc, alahly, misqatar,
];

List<DmThread> dmThreads = [
  DmThread(
    user: wisam,
    preview: 'Haha that was class 😂',
    age: '2m',
    unread: true,
  ),
  DmThread(
    user: r2d1q,
    preview: 'You: see you at 8',
    age: '18m',
    seen: true,
  ),
  DmThread(
    user: asmaagaber,
    preview: 'Sent you the notes 📚',
    age: '1h',
    unread: true,
  ),
  DmThread(
    user: keithlasono,
    preview: 'Nehemiah 8:10 ✝️',
    age: '2h',
  ),
  DmThread(
    user: gabarmohammad,
    preview: 'Replied to your story',
    age: '4h',
  ),
  DmThread(
    user: fwmoayaad,
    preview: 'You: you around later?',
    age: '6h',
    seen: true,
  ),
  DmThread(
    user: ahmadelsous,
    preview: 'Co-founder call at 7?',
    age: '9h',
  ),
  DmThread(
    user: xelshiekh,
    preview: '📍 Doha',
    age: '1d',
  ),
  DmThread(
    user: wtvysf11,
    preview: 'Liked a message',
    age: '2d',
    seen: true,
  ),
  DmThread(
    user: txaha14,
    preview: 'You: 🇵🇸',
    age: '3d',
    seen: true,
  ),
];

List<IgNotification> notifications = [
  IgNotification(
    user: lexi,
    action: 'liked your post',
    age: '2h',
    followBack: false,
    thumb: null,
  ),
  IgNotification(
    user: theo,
    action: 'commented on your post',
    age: '5h',
    followBack: false,
    thumb: null,
  ),
  IgNotification(
    user: maria,
    action: 'started following you',
    age: '1d',
    followBack: false,
    thumb: null,
  ),
  IgNotification(
    user: james,
    action: 'mentioned you in a comment',
    age: '2d',
    followBack: false,
    thumb: null,
  ),
  IgNotification(
    user: elbaraa,
    action: 'reacted to your story',
    age: '3h',
    followBack: false,
    thumb: null,
  ),
];
