import 'package:sci_tercen_client/sci_client.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'tercen_url_parser.dart';

/// Container for resolved IDs.
class ResolvedIds {
  final String? documentId;
  final String? projectId;

  ResolvedIds({this.documentId, this.projectId});

  bool get hasAnyId => documentId != null || projectId != null;

  @override
  String toString() => 'ResolvedIds(documentId: $documentId, projectId: $projectId)';
}

/// Resolves metadata IDs to data IDs.
///
/// Tercen separates data from metadata:
/// - Metadata IDs: User-visible (taskId, documentId from URL)
/// - Data IDs: Actual data references (.documentId, .projectId)
///
/// When a project is cloned, metadata IDs change but data IDs remain the same.
/// This resolver navigates the task hierarchy to extract the actual data IDs
/// needed for file operations.
class DocumentIdResolver {
  final TercenUrlParser _urlParser;
  final String? _devZipFileId;

  DocumentIdResolver(this._urlParser, {String? devZipFileId})
      : _devZipFileId = devZipFileId;

  /// Resolves document ID using hierarchical fallback strategy.
  ///
  /// Strategy order:
  /// 1. Extract .documentId from task JSON (PRIMARY - PRODUCTION)
  /// 2. Search files by workflow/step (AUTO-DISCOVERY FALLBACK)
  /// 3. Use development hardcoded ID (DEVELOPMENT)
  /// 4. Return null for mock fallback
  Future<ResolvedIds?> resolveDocumentId() async {
    print('🔍 Resolving document ID...');

    // Strategy 1: Extract from task JSON
    if (_urlParser.taskId != null && _urlParser.taskId!.isNotEmpty) {
      final idsFromTask = await _tryGetFromTaskJson();
      if (idsFromTask != null && idsFromTask.hasAnyId) {
        print('✓ Resolved from task JSON: $idsFromTask');
        return idsFromTask;
      }
    }

    // Strategy 2: Search files by workflow/step
    if (_urlParser.isWorkflowMode) {
      final docIdFromFiles = await _tryFindFilesByWorkflowStep();
      if (docIdFromFiles != null) {
        print('✓ Resolved from file search: $docIdFromFiles');
        return ResolvedIds(documentId: docIdFromFiles);
      }
    }

    // Strategy 3: Use development hardcoded ID
    if (_devZipFileId != null && _devZipFileId.isNotEmpty) {
      print('🔧 Using development hardcoded ID: $_devZipFileId');
      return ResolvedIds(documentId: _devZipFileId);
    }

    // Strategy 4: Return null for mock fallback
    print('⚠️ Could not resolve document ID - will use mock data');
    return null;
  }

  /// Extracts .documentId from task JSON (bypasses schema filtering).
  Future<ResolvedIds?> _tryGetFromTaskJson() async {
    try {
      final taskService = tercen.ServiceFactory().taskService;
      final task = await taskService.get(_urlParser.taskId!);

      print('📋 Task type: ${task.runtimeType}');
      print('📋 Task kind: ${task.kind}');

      // Navigate to CubeQueryTask
      CubeQueryTask? cubeTask;

      if (task is RunWebAppTask) {
        print('📋 RunWebAppTask detected, navigating to cubeQueryTask...');

        if (task.cubeQueryTaskId.isEmpty) {
          print('⚠️ RunWebAppTask has empty cubeQueryTaskId');
          return null;
        }

        final cubeTaskObj = await taskService.get(task.cubeQueryTaskId);
        if (cubeTaskObj is! CubeQueryTask) {
          print('⚠️ Referenced task is not a CubeQueryTask: ${cubeTaskObj.runtimeType}');
          return null;
        }

        cubeTask = cubeTaskObj;
        print('✓ Navigated to CubeQueryTask: ${cubeTask.id}');
      } else if (task is CubeQueryTask) {
        cubeTask = task;
        print('✓ Task is already a CubeQueryTask');
      } else {
        print('⚠️ Task is neither RunWebAppTask nor CubeQueryTask');
        return null;
      }

      // Extract .documentId from JSON (bypasses schema filtering)
      return _extractDocumentIdFromJson(cubeTask);
    } catch (e) {
      print('✗ Error extracting from task JSON: $e');
      return null;
    }
  }

  /// Extracts .documentId from CubeQueryTask JSON structure.
  ResolvedIds? _extractDocumentIdFromJson(CubeQueryTask cubeTask) {
    try {
      final taskJson = cubeTask.toJson();
      final queryJson = taskJson['query'] as Map?;

      if (queryJson == null || queryJson['relation'] == null) {
        print('⚠️ Task has no query relation');
        return null;
      }

      String? dotDocumentId;
      String? dotProjectId;
      var currentRelation = queryJson['relation'] as Map?;

      // Navigate through relation structure to find InMemoryTable
      while (currentRelation != null) {
        if (currentRelation['kind'] == 'InMemoryRelation' &&
            currentRelation['inMemoryTable'] != null) {
          final inMemoryTable = currentRelation['inMemoryTable'] as Map;
          final columns = inMemoryTable['columns'] as List?;

          if (columns != null) {
            for (final col in columns) {
              final colMap = col as Map;
              final name = colMap['name'] as String?;
              final values = colMap['values'] as List?;

              if (name == '.documentId' && values != null && values.isNotEmpty) {
                dotDocumentId = values.first?.toString();
                print('📋 Found .documentId: $dotDocumentId');
              }
              if (name == '.projectId' && values != null && values.isNotEmpty) {
                dotProjectId = values.first?.toString();
                print('📋 Found .projectId: $dotProjectId');
              }
            }
          }
          break;
        }

        // Navigate deeper into relation tree
        currentRelation = currentRelation['relation'] as Map?;
      }

      if (dotDocumentId != null && dotDocumentId.isNotEmpty) {
        return ResolvedIds(documentId: dotDocumentId, projectId: dotProjectId);
      }

      print('⚠️ Could not find .documentId in task JSON');
      return null;
    } catch (e) {
      print('✗ Error parsing task JSON: $e');
      return null;
    }
  }

  /// Searches for files by workflow and step IDs.
  Future<String?> _tryFindFilesByWorkflowStep() async {
    try {
      if (_urlParser.workflowId == null || _urlParser.stepId == null) {
        return null;
      }

      print('🔍 Searching files by workflowId=${_urlParser.workflowId}, stepId=${_urlParser.stepId}');

      final files = await tercen.ServiceFactory().fileService
          .findFileByWorkflowIdAndStepId(
        startKey: [_urlParser.workflowId, _urlParser.stepId],
        endKey: [_urlParser.workflowId, _urlParser.stepId, {}],
        limit: 10,
        descending: false,
      );

      print('📋 Found ${files.length} files');

      if (files.isEmpty) return null;

      // Prefer ZIP files
      final zipFiles = files.where((f) => f.name.toLowerCase().endsWith('.zip')).toList();
      if (zipFiles.isNotEmpty) {
        print('✓ Found ZIP file: ${zipFiles.first.name} (${zipFiles.first.id})');
        return zipFiles.first.id;
      }

      // Fallback to first file
      print('✓ Using first file: ${files.first.name} (${files.first.id})');
      return files.first.id;
    } catch (e) {
      print('✗ Error searching files: $e');
      return null;
    }
  }
}
