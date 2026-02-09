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

/// Resolves documentId aliases to actual .documentId values.
///
/// Tercen separates data from metadata:
/// - Metadata IDs: User-visible (taskId, documentId from URL) - ALIASES
/// - Data IDs: Actual data references (.documentId, .projectId) - ACTUAL FILE IDs
///
/// When a project is cloned, metadata IDs change but data IDs remain the same.
/// This resolver uses the new Relation.findDocumentId() method to resolve aliases.
class DocumentIdResolver {
  final TercenUrlParser _urlParser;
  final String? _devZipFileId;

  DocumentIdResolver(this._urlParser, {String? devZipFileId})
      : _devZipFileId = devZipFileId;

  /// Resolves document ID from task using Relation.findDocumentId().
  Future<ResolvedIds?> resolveDocumentId() async {
    print('🔍 Resolving document ID using Relation.findDocumentId()...');

    // Development mode: use hardcoded ID
    if (_devZipFileId != null && _devZipFileId.isNotEmpty) {
      print('🔧 Using development hardcoded ID: $_devZipFileId');
      return ResolvedIds(documentId: _devZipFileId);
    }

    // Production mode: resolve from task
    if (_urlParser.taskId == null || _urlParser.taskId!.isEmpty) {
      print('⚠️ No taskId available');
      return null;
    }

    try {
      final taskService = tercen.ServiceFactory().taskService;
      final task = await taskService.get(_urlParser.taskId!);

      print('📋 Task type: ${task.runtimeType}');

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

      // Get the relation from the query
      final relation = cubeTask.query.relation;
      print('📋 Query relation type: ${relation.runtimeType}');
      print('📋 Query relation kind: ${relation.kind}');

      // Navigate through relation hierarchy to find InMemoryRelations
      // (GatherRelation, JoinRelation, etc. wrap InMemoryRelations)
      final taskJson = cubeTask.toJson();
      final queryJson = taskJson['query'] as Map?;

      if (queryJson == null || queryJson['relation'] == null) {
        print('⚠️ Task has no query relation');
        return null;
      }

      // Strategy 1: Look for .documentId (actual file ID) directly
      final actualDocumentIds = <String>{};
      final documentIdAliases = <String>[];

      var currentRelation = queryJson['relation'] as Map?;
      int depth = 0;

      // Navigate through relation hierarchy
      while (currentRelation != null && depth < 20) {
        final kind = currentRelation['kind'] as String?;
        print('📋 Relation[$depth] kind: $kind');

        if (kind == 'InMemoryRelation' && currentRelation['inMemoryTable'] != null) {
          print('✓ Found InMemoryRelation at depth $depth');

          final inMemoryTable = currentRelation['inMemoryTable'] as Map;
          final columns = inMemoryTable['columns'] as List?;

          if (columns == null) {
            print('⚠️ InMemoryTable has no columns');
            break;
          }

          print('📋 InMemoryTable has ${columns.length} columns');

          // Search for documentId columns
          for (final col in columns) {
            final colMap = col as Map;
            final name = colMap['name'] as String?;
            final type = colMap['type'] as String?;
            final values = colMap['values'] as List?;

            if (type != 'string' || values == null || values.isEmpty) {
              continue;
            }

            // Check for .documentId (actual file ID)
            if (name == Relation.DocumentId || (name != null && name.endsWith('.${Relation.DocumentId}'))) {
              final docIds = values
                  .cast<String?>()
                  .where((val) => val != null && val.isNotEmpty)
                  .cast<String>()
                  .toSet();

              actualDocumentIds.addAll(docIds);
              print('📋 Found ${docIds.length} .documentId value(s) in column "$name": ${docIds.join(", ")}');
            }

            // Check for documentId (alias)
            if (name == Relation.DocumentIdAlias || (name != null && name.endsWith('.${Relation.DocumentIdAlias}'))) {
              final aliases = values
                  .cast<String?>()
                  .where((val) => val != null && val.isNotEmpty)
                  .cast<String>()
                  .toSet();

              documentIdAliases.addAll(aliases);
              print('📋 Found ${aliases.length} documentId alias(es) in column "$name": ${aliases.join(", ")}');
            }
          }

          // Found InMemoryTable, exit loop
          break;
        }

        // Navigate deeper into relation tree
        currentRelation = currentRelation['relation'] as Map?;
        depth++;
      }

      // If we found .documentId directly, use it
      if (actualDocumentIds.isNotEmpty) {
        final documentId = actualDocumentIds.first;
        print('✓ Using .documentId directly: $documentId');
        return ResolvedIds(documentId: documentId);
      }

      // Strategy 2: If no .documentId found, try resolving aliases
      if (documentIdAliases.isNotEmpty) {
        print('📋 No .documentId found, attempting to resolve aliases...');
        final resolvedDocumentIds = <String>{};

        for (final alias in documentIdAliases) {
          print('🔍 Resolving alias "$alias" to actual .documentId...');
          final actualDocId = relation.findDocumentId(alias);

          if (actualDocId != null && actualDocId.isNotEmpty) {
            resolvedDocumentIds.add(actualDocId);
            print('✓ Resolved alias "$alias" → .documentId "$actualDocId"');
          } else {
            print('⚠️ Could not resolve alias "$alias"');
          }
        }

        if (resolvedDocumentIds.isNotEmpty) {
          final documentId = resolvedDocumentIds.first;
          print('✓ Using resolved .documentId: $documentId');
          return ResolvedIds(documentId: documentId);
        }
      }

      // Note: URL documentId is NOT used because it's the WebAppOperator ID,
      // not the file document ID. The actual file ID must come from the table data.
      print('⚠️ Could not find documentId in table data');
      print('⚠️ URL documentId (${_urlParser.documentId}) is WebAppOperator ID, not file ID');
      return null;
    } catch (e, stackTrace) {
      print('✗ Error resolving document ID: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}
