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

