import 'package:flutter/material.dart';

import '../data/fixtures.dart';
import '../theme/ig_theme.dart';
import '../widgets/post_card.dart';
import '../widgets/primitives.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static const double _gap = 2;
  static const List<String> _categories = <String>[
    'For you',
    'Travel',
    'Architecture',
    'Food',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const _SearchBar(),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int index) => Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: index == 0 ? IgColors.surfaceHigh : IgColors.bg,
                border: Border.all(color: IgColors.divider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _categories[index],
                style: IgText.semibold(size: 12.5),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double unit = (constraints.maxWidth - 2 * _gap) / 3;
                return _grid(unit);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _grid(double unit) {
    final List<Widget> rows = <Widget>[];
    int i = 0;
    while (i < exploreTiles.length) {
      final ExploreTile tile = exploreTiles[i];
      if (tile.span == 2 && i + 2 < exploreTiles.length) {
        rows.add(
            _featured(tile, exploreTiles[i + 1], exploreTiles[i + 2], unit));
        i += 3;
      } else {
        final int count = (exploreTiles.length - i).clamp(0, 3);
        rows.add(
          Row(
            children: <Widget>[
              for (int k = 0; k < count; k++) ...<Widget>[
                if (k > 0) const SizedBox(width: _gap),
                Expanded(
                  child: _Tile(
                    tile: exploreTiles[i + k],
                    index: i + k,
                    height: unit,
                  ),
                ),
              ],
            ],
          ),
        );
        i += count;
      }
      rows.add(const SizedBox(height: _gap));
    }
    return Column(children: rows);
  }

  Widget _featured(
      ExploreTile featured, ExploreTile a, ExploreTile b, double unit) {
    final double tall = unit * 2 + _gap;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: _Tile(tile: featured, index: 0, height: tall),
        ),
        const SizedBox(width: _gap),
        Expanded(
          child: Column(
            children: <Widget>[
              _Tile(tile: a, index: 1, height: unit),
              const SizedBox(height: _gap),
              _Tile(tile: b, index: 2, height: unit),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tile, required this.index, required this.height});

  final ExploreTile tile;
  final int index;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              _ExplorePost(tile: tile, index: index),
        ),
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ColoredBox(
          color: IgColors.mediaPlaceholder,
          child: Center(
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: 20,
              color: IgColors.textTertiary.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplorePost extends StatelessWidget {
  const _ExplorePost({required this.tile, required this.index});

  final ExploreTile tile;
  final int index;

  @override
  Widget build(BuildContext context) {
    final IgUser owner = exploreTiles[index % exploreTiles.length].igUser;
    final IgPost post = IgPost(
      id: 'explore-${tile.id}',
      user: owner,
      media: <String>[''],
      caption: tile.caption.isEmpty
          ? 'shot on a slow afternoon. more on the grid.'
          : tile.caption,
      likes: 1200 + index * 317,
      age: '${(index % 9) + 2}h',
      location: index.isEven ? 'Los Angeles, California' : null,
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Posts'),
      ),
      body: SingleChildScrollView(child: PostCard(post: post)),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar();

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: IgColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: <Widget>[
            const IgSvgIcon(
                asset: 'assets/icons/search.svg',
                size: 18,
                color: IgColors.textTertiary),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                controller: _controller,
                style: IgText.body(size: 14),
                cursorColor: IgColors.textPrimary,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle:
                      IgText.body(size: 14, color: IgColors.textTertiary),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (String _) => setState(() {}),
              ),
            ),
            if (_controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _controller.clear();
                  setState(() {});
                },
                child: const Icon(Icons.cancel,
                    size: 17, color: IgColors.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}
