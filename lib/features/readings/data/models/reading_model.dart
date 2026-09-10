class ReadingValueModel {
  final String id;
  final String paramId;
  final String paramLabel;
  final String paramType;
  final String val;
  final double? numericVal;
  final String? unit;
  final double? minVal;
  final double? maxVal;
  final bool isViolation;
  final String? violationMessage;
  final String? imageUrl;

  ReadingValueModel({
    required this.id,
    required this.paramId,
    required this.paramLabel,
    this.paramType = 'text',
    required this.val,
    this.numericVal,
    this.unit,
    this.minVal,
    this.maxVal,
    this.isViolation = false,
    this.violationMessage,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'param_id': paramId,
        'param_label': paramLabel,
        'param_type': paramType,
        'val': val,
        'numeric_val': numericVal,
        'unit': unit,
        'min_val': minVal,
        'max_val': maxVal,
        'is_violation': isViolation,
        'violation_message': violationMessage,
        'image_url': imageUrl,
      };

  factory ReadingValueModel.fromMap(Map<String, dynamic> m) => ReadingValueModel(
        id: m['id']?.toString() ?? '',
        paramId: (m['param_id'] ?? m['paramId'])?.toString() ?? '',
        paramLabel: (m['param_label'] ?? m['paramLabel'])?.toString() ?? '',
        paramType: (m['param_type'] ?? m['paramType'])?.toString() ?? 'text',
        val: (m['val'] ?? m['value'])?.toString() ?? '',
        numericVal: m['numeric_val'] != null
            ? (m['numeric_val'] as num).toDouble()
            : (m['numericVal'] != null ? (m['numericVal'] as num).toDouble() : null),
        unit: m['unit']?.toString(),
        minVal: m['min_val'] != null ? (m['min_val'] as num).toDouble() : null,
        maxVal: m['max_val'] != null ? (m['max_val'] as num).toDouble() : null,
        isViolation: m['is_violation'] == true || m['is_violation'] == 1,
        violationMessage: (m['violation_message'] ?? m['violationMessage'])?.toString(),
        imageUrl: (m['image_url'] ?? m['imageUrl'])?.toString(),
      );
}

class ReadingImageModel {
  final String id;
  final String? paramId;
  final String category;
  final String imageUrl;
  final String? filePath;

  ReadingImageModel({
    required this.id,
    this.paramId,
    required this.category,
    required this.imageUrl,
    this.filePath,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'param_id': paramId,
        'category': category,
        'image_url': imageUrl,
        'file_path': filePath,
      };

  factory ReadingImageModel.fromMap(Map<String, dynamic> m) => ReadingImageModel(
        id: m['id']?.toString() ?? '',
        paramId: (m['param_id'] ?? m['paramId'])?.toString(),
        category: m['category']?.toString() ?? 'manual_capture_image',
        imageUrl: (m['image_url'] ?? m['imageUrl'])?.toString() ?? '',
        filePath: (m['file_path'] ?? m['filePath'])?.toString(),
      );
}

class ReadingModel {
  final String id;
  final String tankId;
  final String? tankSnapshotName;
  final double? finalLevel;
  final Map<String, dynamic> inspectionValues;
  final List<ReadingValueModel> valuesList;
  final List<ReadingImageModel> imagesList;
  final String? imageUrl;
  final String source;
  final String capturedBy;
  final String capturedByName;
  final String? inferenceTimeMs;
  final String? capturedAtStart;
  final String capturedAt;

  ReadingModel({
    required this.id,
    required this.tankId,
    this.tankSnapshotName,
    this.finalLevel,
    Map<String, dynamic>? inspectionValues,
    List<ReadingValueModel>? valuesList,
    List<ReadingImageModel>? imagesList,
    this.imageUrl,
    this.source = 'manual',
    required this.capturedBy,
    required this.capturedByName,
    this.inferenceTimeMs,
    this.capturedAtStart,
    required this.capturedAt,
  })  : inspectionValues = inspectionValues ?? {},
        valuesList = valuesList ?? const [],
        imagesList = imagesList ?? const [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'tank_id': tankId,
        'tank_snapshot_name': tankSnapshotName,
        'final_level': finalLevel,
        'inspection_values': inspectionValues,
        'values_json': inspectionValues,
        'values_list': valuesList.map((v) => v.toMap()).toList(),
        'images_list': imagesList.map((i) => i.toMap()).toList(),
        'image_url': imageUrl,
        'source': source,
        'captured_by': capturedBy,
        'recorded_by_id': capturedBy,
        'captured_by_name': capturedByName,
        'recorded_by_name': capturedByName,
        'recorded_by_role': 'user',
        'inference_time_ms': inferenceTimeMs,
        'captured_at_start': capturedAtStart,
        'captured_at': capturedAt,
        'timestamp': capturedAt,
      };

  factory ReadingModel.fromMap(Map<String, dynamic> m) {
    List<ReadingValueModel> vList = [];
    if (m['values_list'] is List) {
      vList = (m['values_list'] as List)
          .map((v) => ReadingValueModel.fromMap(Map<String, dynamic>.from(v as Map)))
          .toList();
    }

    List<ReadingImageModel> iList = [];
    if (m['images_list'] is List) {
      iList = (m['images_list'] as List)
          .map((i) => ReadingImageModel.fromMap(Map<String, dynamic>.from(i as Map)))
          .toList();
    }

    return ReadingModel(
      id: m['id']?.toString() ?? '',
      tankId: (m['tank_id'] ?? m['tankId'])?.toString() ?? '',
      tankSnapshotName: (m['tank_snapshot_name'] ?? m['tankSnapshotName'])?.toString(),
      finalLevel: m['final_level'] != null
          ? (m['final_level'] as num).toDouble()
          : (m['finalLevel'] != null ? (m['finalLevel'] as num).toDouble() : null),
      inspectionValues: m['inspection_values'] != null
          ? Map<String, dynamic>.from(m['inspection_values'] as Map)
          : (m['values_json'] != null
              ? Map<String, dynamic>.from(m['values_json'] as Map)
              : {}),
      valuesList: vList,
      imagesList: iList,
      imageUrl: (m['image_url'] ?? m['imageUrl'])?.toString(),
      source: m['source']?.toString() ?? 'manual',
      capturedBy: (m['captured_by'] ?? m['recorded_by_id'])?.toString() ?? '',
      capturedByName: (m['captured_by_name'] ?? m['recorded_by_name'])?.toString() ?? '',
      inferenceTimeMs: (m['inference_time_ms'] ?? m['inferenceTimeMs'])?.toString(),
      capturedAtStart: (m['captured_at_start'] ?? m['capturedAtStart'])?.toString(),
      capturedAt: (m['captured_at'] ?? m['timestamp'])?.toString() ??
          DateTime.now().toIso8601String(),
    );
  }
}
