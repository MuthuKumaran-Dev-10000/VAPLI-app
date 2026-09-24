// lib/features/alerts/data/models/alert_model.dart
// ══════════════════════════════════════════════════════════════════════════════
// AlertModel — stored at /alerts/{alertId} in Firebase RTDB
//
// Created automatically by ReadingRepository (or ReadingEntryScreen) when a
// submitted inspection value violates a constraint that has
// store_history == true.
//
// Schema:
//   id                    — push-key
//   tank_id               — the tank this reading belongs to
//   tank_code             — snapshot of tankCode at time of violation
//   tank_name             — snapshot of tankName
//   tank_location         — snapshot of location / zone
//   tank_path             — tree path (from TankNode.path), if available
//   reading_id            — the reading that triggered this alert
//   captured_by           — userId of the inspector
//   captured_by_name      — full name of the inspector
//   captured_at           — ISO timestamp of the reading
//   constraint_id         — the constraint that was violated
//   constraint_op         — operator string, e.g. ">" / "contains"
//   constraint_value      — the threshold value as a string
//   constraint_severity   — "warning" | "critical" | "info"
//   constraint_label      — human label of the parameter that was checked
//   violated_value        — the actual value that caused the violation (string)
//   alert_title           — short title (from constraint.alert_title or auto)
//   message               — full message (from constraint.message)
//   show_dashboard_alert  — whether the dashboard should surface this
//   play_sound            — whether a sound should play
//   capture_image_on_violation — whether a photo was required
//   block_submission      — whether submission was blocked (informational)
//   last_inspection_values — full Map<label, value> snapshot of the reading
//   resolved              — false by default; set to true when admin dismisses
//   resolved_at           — ISO timestamp when resolved
//   resolved_by           — userId of resolver
// ══════════════════════════════════════════════════════════════════════════════

class AlertModel {
  final String  id;
  final String  tankId;
  final String  tankCode;
  final String  tankName;
  final String? tankLocation;
  final String? tankPath;

  final String  readingId;
  final String  capturedBy;
  final String  capturedByName;
  final String  capturedAt;

  final String  constraintId;
  final String  constraintOp;
  final String  constraintValue;
  final String  constraintSeverity; // "warning" | "critical" | "info"
  final String  constraintLabel;    // parameter label
  final String  violatedValue;      // actual value that triggered this

  final String  alertTitle;
  final String  message;

  final bool    showDashboardAlert;
  final bool    playSound;
  final bool    captureImageOnViolation;
  final bool    blockSubmission;

  final Map<String, dynamic> lastInspectionValues;

  final bool    resolved;
  final String? resolvedAt;
  final String? resolvedBy;
  final String  status; // "active" | "COMPLETED"
  final String? ifThen; // 🔖 Added for IF-THEN detail

  const AlertModel({
    required this.id,
    required this.tankId,
    required this.tankCode,
    required this.tankName,
    this.tankLocation,
    this.tankPath,
    required this.readingId,
    required this.capturedBy,
    required this.capturedByName,
    required this.capturedAt,
    required this.constraintId,
    required this.constraintOp,
    required this.constraintValue,
    required this.constraintSeverity,
    required this.constraintLabel,
    required this.violatedValue,
    required this.alertTitle,
    required this.message,
    required this.showDashboardAlert,
    required this.playSound,
    required this.captureImageOnViolation,
    required this.blockSubmission,
    required this.lastInspectionValues,
    this.resolved = false,
    this.resolvedAt,
    this.resolvedBy,
    this.status = 'active',
    this.ifThen, // 🔖 Added for IF-THEN detail
  });

  // ── Serialise ──────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id':                        id,
    'tank_id':                   tankId,
    'tank_code':                 tankCode,
    'tank_name':                 tankName,
    'tank_location':             tankLocation,
    'tank_path':                 tankPath,
    'reading_id':                readingId,
    'captured_by':               capturedBy,
    'captured_by_name':          capturedByName,
    'captured_at':               capturedAt,
    'timestamp':                 capturedAt,
    'constraint_id':             constraintId,
    'param_id':                  constraintId,
    'constraint_op':             constraintOp,
    'op':                        constraintOp,
    'constraint_value':          constraintValue,
    'constraint_severity':       constraintSeverity,
    'severity':                  constraintSeverity,
    'constraint_label':          constraintLabel,
    'param_label':               constraintLabel,
    'label':                     constraintLabel,
    'violated_value':            violatedValue,
    'param_value':               violatedValue,
    'alert_title':               alertTitle,
    'message':                   message,
    'show_dashboard_alert':      showDashboardAlert,
    'play_sound':                playSound,
    'capture_image_on_violation':captureImageOnViolation,
    'block_submission':          blockSubmission,
    'last_inspection_values':    lastInspectionValues,
    'resolved':                  resolved,
    'acknowledged':              resolved,
    'resolved_at':               resolvedAt,
    'resolved_by':               resolvedBy,
    'status':                    status,
    'if_then':                   ifThen,
  };

  factory AlertModel.fromMap(String id, Map<dynamic, dynamic> m) {
    bool parseBool(dynamic val, {bool defaultValue = false}) {
      if (val == null) return defaultValue;
      if (val is bool) return val;
      if (val is num) return val != 0;
      if (val is String) {
        final s = val.toLowerCase().trim();
        return s == 'true' || s == '1';
      }
      return defaultValue;
    }

    String parseFirstNonEmpty(List<String> keys, {String fallback = ''}) {
      for (final k in keys) {
        final val = m[k]?.toString().trim();
        if (val != null && val.isNotEmpty && val.toLowerCase() != 'general' && val != '.') {
          return val;
        }
      }
      return fallback;
    }

    Map<String, dynamic> inspVals = {};
    if (m['last_inspection_values'] is Map) {
      inspVals = Map<String, dynamic>.from(m['last_inspection_values'] as Map);
    }

    final parsedParamLabel = parseFirstNonEmpty(['param_label', 'label', 'constraint_label', 'param_name']);
    final parsedAlertTitle = parseFirstNonEmpty(['alert_title', 'constraint_label', 'label', 'message'], fallback: 'Alert');

    return AlertModel(
      id:                        id,
      tankId:                    m['tank_id']?.toString()             ?? '',
      tankCode:                  m['tank_code']?.toString()           ?? '',
      tankName:                  m['tank_name']?.toString()           ?? '',
      tankLocation:              m['tank_location']?.toString(),
      tankPath:                  m['tank_path']?.toString(),
      readingId:                 m['reading_id']?.toString()          ?? '',
      capturedBy:                m['captured_by']?.toString()         ?? '',
      capturedByName:            (m['captured_by_name'] ?? m['captured_by'])?.toString() ?? 'System Administrator',
      capturedAt:                (m['captured_at'] ?? m['timestamp'])?.toString() ?? '',
      constraintId:              (m['constraint_id'] ?? m['param_id'])?.toString() ?? '',
      constraintOp:              (m['constraint_op'] ?? m['op'])?.toString() ?? '',
      constraintValue:           (m['constraint_value'] ?? m['compare_value'] ?? m['threshold_value'] ?? m['param_value'] ?? m['value_json'])?.toString() ?? '',
      constraintSeverity:        (m['constraint_severity'] ?? m['severity'])?.toString() ?? 'warning',
      constraintLabel:           parsedParamLabel.isNotEmpty ? parsedParamLabel : 'System Alert',
      violatedValue:             (m['violated_value'] ?? m['param_value'] ?? m['value_json'] ?? m['value'] ?? m['val'])?.toString() ?? '',
      alertTitle:                parsedAlertTitle,
      message:                   m['message']?.toString()             ?? '',
      showDashboardAlert:        parseBool(m['show_dashboard_alert'], defaultValue: true),
      playSound:                 parseBool(m['play_sound']),
      captureImageOnViolation:   parseBool(m['capture_image_on_violation']),
      blockSubmission:           parseBool(m['block_submission']),
      lastInspectionValues:      inspVals,
      resolved:                  parseBool(m['resolved'] ?? m['acknowledged']),
      resolvedAt:                m['resolved_at']?.toString(),
      resolvedBy:                m['resolved_by']?.toString(),
      status:                    m['status']?.toString()              ?? 'active',
      ifThen:                    m['if_then']?.toString(),
    );
  }

  AlertModel copyWith({
    bool?    resolved,
    String?  resolvedAt,
    String?  resolvedBy,
    String?  status,
    String?  ifThen, // 🔖 Added for IF-THEN detail
  }) => AlertModel(
    id:                        id,
    tankId:                    tankId,
    tankCode:                  tankCode,
    tankName:                  tankName,
    tankLocation:              tankLocation,
    tankPath:                  tankPath,
    readingId:                 readingId,
    capturedBy:                capturedBy,
    capturedByName:            capturedByName,
    capturedAt:                capturedAt,
    constraintId:              constraintId,
    constraintOp:              constraintOp,
    constraintValue:           constraintValue,
    constraintSeverity:        constraintSeverity,
    constraintLabel:           constraintLabel,
    violatedValue:             violatedValue,
    alertTitle:                alertTitle,
    message:                   message,
    showDashboardAlert:        showDashboardAlert,
    playSound:                 playSound,
    captureImageOnViolation:   captureImageOnViolation,
    blockSubmission:           blockSubmission,
    lastInspectionValues:      lastInspectionValues,
    resolved:                  resolved ?? this.resolved,
    resolvedAt:                resolvedAt ?? this.resolvedAt,
    resolvedBy:                resolvedBy ?? this.resolvedBy,
    status:                    status ?? this.status,
    ifThen:                    ifThen ?? this.ifThen, // 🔖 Added for IF-THEN detail
  );
}