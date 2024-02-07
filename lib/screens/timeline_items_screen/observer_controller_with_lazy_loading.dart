import 'package:flutter/widgets.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

/// Class with a ListObserverController that allows the caller to lazy load content from the ListView items,
/// for example images from a network. Because during `jumpTo` and `animateTo` all items are getting build
/// which means that alle images from a network are loaded as well, which can use a lot of bandwidth.
class ObserverControllerWithLazyLoading {
  /// The index requested to scroll to
  var requestedIndex = -1;

  /// Whether we are currently scrolling to a certain index
  var isScrollingToIndex = false;

  /// Unique keys for list items, needed for knowing which list items have been built by the listview
  /// and calling Scrollable.ensureVisible after loading the images.
  final Map<int, GlobalKey> keys = {};

  /// Callback after jumpTo / animateTo has ended and contains the indexes of the built list items.
  final void Function(List<int> indexes) onBuiltEnd;

  final ScrollController scrollController;

  /// The ListObserverController, important to set cacheJumpIndexOffset to false, as some content
  /// is only loaded after the scrolling ended.
  late final ListObserverController listObserverController;

  ObserverControllerWithLazyLoading(
      {required this.onBuiltEnd, required this.scrollController});

  /// Gets a unique key for each list item, should be called when building the list items.
  GlobalKey getKey(int index) {
    if (!keys.containsKey(index)) {
      keys[index] = GlobalKey();
    }
    return keys[index]!;
  }

  /// Should be called before using this class
  void init() {
    listObserverController =
        ListObserverController(controller: scrollController)
          ..cacheJumpIndexOffset = false;
  }

  Future scrollToIndex(int index) async {
    requestedIndex = index;
    isScrollingToIndex = true;
    await listObserverController.jumpTo(index: requestedIndex);
    isScrollingToIndex = false;
  }

  /// Whether this index is now built and not scrolling to a specific index,
  /// so this means that all resources should be loaded from this item.
  bool shouldActivelyLoad(int index, List<int> displayedIndexes) {
    return requestedIndex == -1 || displayedIndexes.contains(index);
  }

  /// Should be called by the onObserve of the ListViewObserver.
  /// This calls the `onBuiltEnd` callback with the indexes that should be loaded fully
  /// and makes sure that the requested index is displayed.
  void onObserve(ListViewObserveModel model) {
    if (requestedIndex > -1) {
      if (!isScrollingToIndex) {
        requestedIndex = -1;
        return;
      }
      final tmp = requestedIndex;
      requestedIndex = -1;
      final builtIndexes = keys.entries
          .where((entry) => entry.value.currentContext != null)
          .map((e) => e.key)
          .toList();
      // Caller should update the state with the built indexes in this callback so items get rebuilt and you are able to load images.
      onBuiltEnd(builtIndexes);
      try {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          //await Future.delayed(Duration(seconds: 1));
          if (keys[tmp]?.currentContext != null) {
            try {
              Scrollable.ensureVisible(keys[tmp]!.currentContext!);
            } catch (ex) {
              debugPrintStack();
            }
          }
        });
      } catch (ex) {
        debugPrintStack();
      }
    }
  }
}
