/// Read projections of the canonical CoRAgent Monitor contract.
/// No lifecycle is inferred from model replies or job completion.
Map<String, Object?> monitorObject(Object? value) {
  if (value is! Map) throw const FormatException('Expected Monitor object');
  return Map<String, Object?>.from(value);
}

List<Map<String, Object?>> monitorItems(Object? value) {
  if (value is! List) throw const FormatException('Expected Monitor list');
  return value.map(monitorObject).toList(growable: false);
}

class MonitorTask {
  MonitorTask(Map<String, Object?> raw) : this._(raw, summary: false);
  MonitorTask.summary(Map<String, Object?> raw) : this._(raw, summary: true);

  MonitorTask._(this.raw, {required bool summary}) {
    // Overview and list responses use bounded task projections and omit the
    // durable task schema version; detail/control responses include it.
    if ((summary
            ? raw['schema_version'] != null
            : raw['schema_version'] != 'coragent-user-task/2') ||
        raw['user_task_id'] is! String ||
        raw['revision'] is! int ||
        revision < 1 ||
        !states.contains(state)) {
      throw const FormatException('Unsupported user task');
    }
  }
  static const states = {
    'active',
    'waiting',
    'paused',
    'blocked',
    'completing',
    'completed',
    'partial',
    'cancelled',
  };
  final Map<String, Object?> raw;
  String get id => raw['user_task_id'] as String;
  int get revision => raw['revision'] as int;
  String get title => raw['title'] as String? ?? id;
  String get state => raw['state'] as String? ?? '';
  String get objective => raw['objective'] as String? ?? '';
  String? get reason => raw['reason'] as String?;
  bool get terminal =>
      state == 'completed' || state == 'partial' || state == 'cancelled';
  String? get progress => raw['progress'] is Map
      ? (raw['progress'] as Map)['summary'] as String?
      : null;
}

class MonitorJob {
  MonitorJob(this.raw) {
    if (raw['job_id'] is! String || raw['state'] is! String) {
      throw const FormatException('Invalid job observation');
    }
  }
  final Map<String, Object?> raw;
  String get id => raw['job_id'] as String;
  String get title =>
      raw['title'] as String? ?? raw['job_name'] as String? ?? id;
  String get state => raw['state'] as String;
  String? get taskId => raw['user_task_id'] as String?;
  bool get cancellable => const {
    'created',
    'held',
    'queued',
    'pending',
    'running',
    'submitted',
    'unknown',
  }.contains(state);
}

class MonitorOverview {
  MonitorOverview(Map<String, Object?> raw)
    : task = raw['task'] == null
          ? null
          : MonitorTask.summary(monitorObject(raw['task'])),
      jobs = monitorItems(
        monitorObject(raw['jobs'])['active'],
      ).map(MonitorJob.new).toList(),
      jobScope = monitorObject(raw['jobs'])['scope'] as String? ?? 'session',
      jobCounts = monitorObject(raw['jobs'])['counts'] is Map
          ? monitorObject(monitorObject(raw['jobs'])['counts'])
          : const {},
      activeJobsOmitted =
          monitorObject(raw['jobs'])['active_omitted'] as int? ?? 0,
      continuationState =
          monitorObject(raw['continuation'])['state'] as String?,
      executionState = monitorObject(raw['execution'])['state'] as String?,
      updatedAt = DateTime.tryParse(raw['updated_at'] as String? ?? '') {
    if (raw['schema_version'] != 'coragent-monitor/2') {
      throw const FormatException('Unsupported Monitor overview');
    }
  }
  final MonitorTask? task;
  final List<MonitorJob> jobs;
  final String jobScope;
  final Map<String, Object?> jobCounts;
  final int activeJobsOmitted;
  final String? continuationState;
  final String? executionState;
  int get totalJobs => jobCounts['total'] as int? ?? 0;

  String get activityState => switch (continuationState) {
    'idle' =>
      task?.terminal == true
          ? task!.state
          : executionState == 'running'
          ? 'active'
          : 'idle',
    'paused' || 'blocked' => continuationState!,
    'error' || 'attention_required' => 'blocked',
    'disabled' => executionState == 'running' ? 'active' : 'stopped',
    'checking' => executionState == 'running' ? 'active' : '',
    'retrying' => executionState == 'running' ? 'active' : 'retrying',
    'waiting' => 'waiting',
    'pending' || 'ready' => 'active',
    _ => '',
  };
  final DateTime? updatedAt;
}

abstract interface class HostMonitorGateway {
  Future<Set<String>> monitorCapabilities();
  Stream<void> monitorChanges(String workspaceId, String sessionId);
  Future<Map<String, Object?>> monitorRequest(
    String workspaceId,
    String sessionId,
    String method, {
    Map<String, Object?> params = const {},
  });
}
