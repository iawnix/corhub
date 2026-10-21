import 'app_localizations.dart';

extension HostMonitorLocalizations on AppLocalizations {
  String get hostMonitors => monitorTitle;
  String hostMonitorState(String state) => switch (state) {
    'active' => monitorActive,
    'open' => monitorOpen,
    'waiting' => monitorWaiting,
    'paused' => monitorPaused,
    'blocked' || 'degraded' => monitorBlocked,
    'completing' => monitorCompleting,
    'completed' => monitorCompleted,
    'partial' => monitorPartial,
    'stopped' => monitorStopped,
    'idle' => monitorIdle,
    'retrying' => monitorRetrying,
    'cancelled' || 'canceled' => monitorCancelled,
    'running' => monitorRunning,
    'created' ||
    'held' ||
    'queued' ||
    'pending' ||
    'submitted' => monitorQueued,
    'failed' || 'error' => monitorFailed,
    'succeeded' || 'success' => monitorSucceeded,
    'cancel_requested' || 'cancelling' => monitorCancelPending,
    'done' || 'closed' => monitorEnded,
    _ => state.isEmpty ? monitorUnknown : state,
  };
}
