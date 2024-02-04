import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_widgets.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/draft_item_screen/draft_item_screen_bloc.dart';
import 'package:timeline/utils.dart';

class DraftItemScreen extends StatefulWidget {
  final TimelineItem? timelineItem; // If create this is empty.
  final List<Timeline> timelines; // All timelines for this host
  final TimelineHost timelineHost;
  const DraftItemScreen(
      {super.key,
      required this.timelineItem,
      required this.timelines,
      required this.timelineHost});

  @override
  State<DraftItemScreen> createState() => _DraftItemScreenState();
}

class _DraftItemScreenState extends State<DraftItemScreen> {
  late final TextEditingController titleController;
  late final TextEditingController yearController;
  late final TextEditingController yearEndController;
  late final TextEditingController introController;

  int? timelineId;

  @override
  void initState() {
    super.initState();
    if (widget.timelineItem != null) {
      timelineId = widget.timelineItem!.timelineId;
    }
    titleController = TextEditingController(text: widget.timelineItem?.title);
    yearController =
        TextEditingController(text: widget.timelineItem?.year.toString());
    yearEndController =
        TextEditingController(text: widget.timelineItem?.yearEnd?.toString());
    introController = TextEditingController(text: widget.timelineItem?.intro);
  }

  @override
  void dispose() {
    titleController.dispose();
    yearController.dispose();
    yearEndController.dispose();
    introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<TimelineRepository>(context);
    return BlocProvider(
      create: (context) => DraftItemScreenCubit(repo),
      child: BlocConsumer<DraftItemScreenCubit, DraftItemScreenState>(
        listener: (context, state) {
          if (state.completed) {
            Navigator.of(context).pop<bool>(true);
          }
        },
        builder: (context, state) {
          final cubit = BlocProvider.of<DraftItemScreenCubit>(context);
          return Scaffold(
              appBar: AppBar(
                title: Text(
                    widget.timelineItem?.title ?? myLoc(context).draftItems),
                actions: widget.timelineItem != null
                    ? [
                        IconButton(
                            onPressed: () {
                              cubit.delete(
                                  widget.timelineHost,
                                  widget.timelines.firstWhere(
                                      (element) => element.id == timelineId),
                                  widget.timelineItem!);
                            },
                            icon: const Icon(Icons.delete))
                      ]
                    : null,
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MyWidgets.textField(
                      context,
                      labelText: 'Title',
                      controller: titleController,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownMenu<Timeline>(
                        inputDecorationTheme: InputDecorationTheme(
                            enabledBorder:
                                MyWidgets.getOutlineInputBorderEnabled(context),
                            focusedBorder:
                                MyWidgets.getOutlineInputBorderFocused(
                                    context)),
                        initialSelection: widget.timelineItem != null
                            ? widget.timelines.firstWhereOrNull((element) =>
                                element.id == widget.timelineItem!.timelineId)
                            : null,
                        onSelected: (value) {
                          if (value != null) {
                            setState(() {
                              timelineId = value.id;
                            });
                          }
                        },
                        dropdownMenuEntries: widget.timelines
                            .map((e) => DropdownMenuEntry<Timeline>(
                                value: e, label: e.name))
                            .toList()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MyWidgets.textField(context,
                        controller: yearController, labelText: 'Year'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MyWidgets.textField(context,
                        controller: yearEndController, labelText: 'Year end'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MyWidgets.textField(context,
                        controller: introController,
                        labelText: 'Intro',
                        maxLines: 6),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FilledButton(
                        onPressed: state.busy
                            ? null
                            : () {
                                final newTimelineItem = TimelineItem(
                                    image: widget.timelineItem?.image ?? {},
                                    hasContent:
                                        widget.timelineItem?.hasContent ??
                                            false,
                                    intro: introController.text,
                                    title: titleController.text,
                                    timelineId: timelineId!,
                                    year: int.parse(yearController.text),
                                    postId: widget.timelineItem?.postId ?? 0,
                                    yearEnd: yearEndController.text.isNotEmpty
                                        ? int.parse(yearEndController.text)
                                        : null,
                                    links: const []);
                                if (widget.timelineItem != null) {
                                  cubit.update(
                                      widget.timelineHost,
                                      widget.timelines.firstWhere((element) =>
                                          element.id == timelineId),
                                      newTimelineItem);
                                } else {
                                  cubit.create(
                                      widget.timelineHost,
                                      widget.timelines.firstWhere((element) =>
                                          element.id == timelineId),
                                      newTimelineItem);
                                }
                              },
                        child: Text(myLoc(context).ok)),
                  ),
                ],
              ));
        },
      ),
    );
  }
}
