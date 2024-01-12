import 'package:flutter/material.dart';

class ListviewBuilderWithScrollToIndexController {
  ListviewBuilderWithScrollToIndexController(
      {required this.scrollController,
      this.onBuiltIndexesAfterScrollToIndex,
      this.durationForBuiltIndexesAfterScrollToIndex,
      required this.listViewKey});
  final ScrollController scrollController;
  final GlobalKey listViewKey;
  final Function(List<int> indexes)? onBuiltIndexesAfterScrollToIndex;
  final Duration? durationForBuiltIndexesAfterScrollToIndex;
  int requestedIndex = -1; // clicked index
  final Map<int, GlobalKey> keys = {};

  /// Generates and returns a key that must be used for the item in the ListView.
  GlobalKey getKey(int index) {
    if (!keys.containsKey(index)) {
      keys[index] = GlobalKey();
    }
    return keys[index]!;
  }

  void init() {
    scrollController.addListener(
      () async {
        // await SchedulerBinding.instance
        //     .endOfFrame;

        if (requestedIndex != -1 &&
            keys[requestedIndex]?.currentContext != null) {
          final tmp = requestedIndex;
          // Eerste keer ensureVisible.
          await Scrollable.ensureVisible(keys[requestedIndex]!
              .currentContext!); // This will cancel the animation, which is what we want.
          requestedIndex = -1;
          // NU zouden we de images moeten laten van alle items die nu gebuild zijn.
          // De caller moet in deze callback setState aanroepen en hierb
          if (onBuiltIndexesAfterScrollToIndex != null) {
            await Future.delayed(durationForBuiltIndexesAfterScrollToIndex ??
                const Duration(milliseconds: 0));
            // Hiermee moet in de aclled setState worden aangeroiepen met de iundexex
            // dat zal een re-0build doen waarbij je dan de images kan laden.
            // Maar afhankelijk van hoe snel die afbeeldingen geladen worden zal de volgende ensureVisible call goed lukken
            // want als de afbeeldingen nog steeds niet geladen zoijn, dan kan de listview natuurlijk niet gfoed de positie bepalken
            // en zal daarna alsnof een verschuiving optreden.
            onBuiltIndexesAfterScrollToIndex!(keys.entries
                .where((e) => e.value.currentContext != null)
                .map((e) => e.key)
                .toList());
            if (tmp != -1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (keys.containsKey(tmp) &&
                    keys[tmp]!.currentContext != null) {
                  print('Ensure visible for $tmp!');
                  // Tweede keer ensureVisible, omdat nu de images geladen zijn en dus de items van hoogte kunnen veranderen.
                  Scrollable.ensureVisible(keys[tmp]!
                      .currentContext!); // This will cancel the animation, which is what we want.
                }
              });
            }
          }
        }
      },
    );
  }

  int getRequestedIndex() {
    return requestedIndex;
  }

  Future scrollToIndex(int index) async {
    print(
        'Offset = ${scrollController.offset}'); // dit hoe ver listview gescrolt is.
    final listViewRenderObject = listViewKey.currentContext!.findRenderObject();
    var topIndex = -1;
    for (final entry in keys.entries) {
      if (entry.value.currentContext != null) {
        final translation = entry.value.currentContext!
            .findRenderObject()
            ?.getTransformTo(listViewRenderObject)
            .getTranslation();
        if (translation != null && translation.y >= 0) {
          topIndex = entry.key;
          break;
        }
      }
    }
    if (index == topIndex) {
      return;
    }
    requestedIndex = index;
    return scrollController.animateTo(
        index > topIndex
            ? scrollController.position.maxScrollExtent
            : scrollController.position.minScrollExtent,
        duration: Duration(
            seconds:
                1), // deze kunnen we zetten a.h.v. of we dicht in de buurt zitten of niet.
        // hoe labger hoe beter, want dan worden items niet geskipt.
        curve: Curves
            .linear); // linear is belangrijk, want dan komen alle items even snel voorbij en worden de snelste niet geskipt.
    // print('Animate completed: ${requestedIndex}');
    // if (requestedIndex != -1) {
    //   // Niet gelukt, dus we kunnen dan eventueel nog 2 keer proberen bijv.
    // }
  }
}
