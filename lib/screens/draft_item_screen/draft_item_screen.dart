import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/draft_item_screen/draft_item_screen_bloc.dart';

class DraftItemScreen extends StatefulWidget {
  final TimelineItem timelineItem;
  final Timeline timeline;
  final TimelineHost timelineHost;
  const DraftItemScreen(
      {super.key,
      required this.timelineItem,
      required this.timeline,
      required this.timelineHost});

  @override
  State<DraftItemScreen> createState() => _DraftItemScreenState();
}

class _DraftItemScreenState extends State<DraftItemScreen> {
  late final TextEditingController titleController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.timelineItem.title);
  }

  @override
  void dispose() {
    titleController.dispose();
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
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          final cubit = BlocProvider.of<DraftItemScreenCubit>(context);
          return Scaffold(
              appBar: AppBar(),
              body: Column(
                children: [
                  TextField(
                    controller: titleController,
                  ),
                  FilledButton(
                      onPressed: state.busy
                          ? null
                          : () {
                              cubit.update(
                                  widget.timelineHost,
                                  widget.timeline,
                                  widget.timelineItem
                                      .copyWith(title: titleController.text));
                            },
                      child: Text('Save'))
                ],
              ));
        },
      ),
    );
  }
}
