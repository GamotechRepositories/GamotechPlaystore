import 'package:flutter/material.dart';

import '../services/banner_service.dart';

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key, this.bannerService});

  final BannerService? bannerService;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final _controller = PageController();
  late Future<List<HomeBanner>> _banners;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _banners = (widget.bannerService ?? BannerService()).fetchHomeBanners();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changePage(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<List<HomeBanner>>(
      future: _banners,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading banners',
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    error is BannerException
                        ? error.message
                        : 'Unable to load banners. Please try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _currentPage = 0;
                      _banners = (widget.bannerService ?? BannerService())
                          .fetchHomeBanners();
                    }),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final banners = snapshot.data!;
        if (banners.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: colors.surfaceContainerHighest,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: banners.length,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    itemBuilder: (context, index) {
                      final banner = banners[index];
                      return Image.network(
                        banner.imageUrl,
                        semanticLabel: banner.title,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                            ? child
                            : const Center(
                                child: CircularProgressIndicator(
                                  semanticsLabel: 'Loading banner image',
                                ),
                              ),
                        errorBuilder: (context, error, stackTrace) => Semantics(
                          label: '${banner.title}. Image unavailable',
                          excludeSemantics: true,
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Image unavailable',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (banners.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Previous banner',
                    onPressed: () => _changePage(
                      (_currentPage - 1 + banners.length) % banners.length,
                    ),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Flexible(
                    child: Text(
                      '${_currentPage + 1} / ${banners.length}',
                      semanticsLabel:
                          'Banner ${_currentPage + 1} of ${banners.length}',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next banner',
                    onPressed: () =>
                        _changePage((_currentPage + 1) % banners.length),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
