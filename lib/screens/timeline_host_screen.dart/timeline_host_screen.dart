import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/my_loading_overlay.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/timeline_host_screen.dart/timeline_host_screen_bloc.dart';

// Je krijgt een host en geeft de timelineAll terug.
class TimelineHostScreen extends StatefulWidget {
  final TimelineAll timelineAll;
  final TimelineHost host;
  const TimelineHostScreen(
      {super.key, required this.host, required this.timelineAll});

  @override
  State<TimelineHostScreen> createState() => _TimelineHostScreenState();
}

class _TimelineHostScreenState extends State<TimelineHostScreen> {
  final _loadingOverlay = LoadingOverlay();

  @override
  void dispose() {
    _loadingOverlay.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<TimelineRepository>(context);
    return BlocProvider(
      create: (context) => TimelineHostScreenCubit(widget.timelineAll, repo),
      child: BlocConsumer<TimelineHostScreenCubit, TimelineHostScreenState>(
        listener: (context, state) {
          if (!state.busy) {
            _loadingOverlay.hide();
          }
        },
        builder: (context, state) {
          final cubit = BlocProvider.of<TimelineHostScreenCubit>(context);
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (didPop) {
                return;
              }
              Navigator.of(context).pop<int>(state.timelineAll.hashCode);
            },
            child: Scaffold(
                appBar: AppBar(
                  title: Text(widget.host.host),
                ),
                body: Column(
                  children: [
                    ...state.timelineAll.timelines
                        .where((e) => e.hostId == widget.host.id)
                        .map((e) => ListTile(title: Text(e.name))),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                          onPressed: () async {
                            _loadingOverlay.show(context);
                            await cubit.removeHost(
                                state.timelineAll, widget.host);
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('Delete')),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                          onPressed: () {
                            _loadingOverlay.show(context);
                            cubit.refreshHost(state.timelineAll, widget.host);
                          },
                          child: const Text('Refresh')),
                    )
                  ],
                )),
          );
        },
      ),
    );
  }
}
