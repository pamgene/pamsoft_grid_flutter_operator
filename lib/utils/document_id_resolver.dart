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

      // Look for documentId aliases in the InMemoryRelations
      final documentIdAliases = <String>[];

      for (var inMemoryRelation in relation.inMemoryRelations) {
        final table = inMemoryRelation.inMemoryTable;
        final columns = table.columns;

        // Find the 'documentId' (alias) column
        final aliasColumn = columns
            .where((col) => col.type == 'string')
            .where((col) => col.name == Relation.DocumentIdAlias ||
                           col.name.endsWith('.${Relation.DocumentIdAlias}'))
            .firstOrNull;

        if (aliasColumn != null && aliasColumn.values != null) {
          final aliases = (aliasColumn.values as List)
              .cast<String?>()
              .where((val) => val != null && val.isNotEmpty)
              .cast<String>()
              .toSet();

          documentIdAliases.addAll(aliases);
          print('📋 Found ${aliases.length} documentId alias(es) in column "${aliasColumn.name}": ${aliases.join(", ")}');
        }
      }

      if (documentIdAliases.isEmpty) {
        print('⚠️ No documentId aliases found in InMemoryRelations');
        return null;
      }

      // Resolve each alias to actual .documentId using Relation.findDocumentId()
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

      if (resolvedDocumentIds.isEmpty) {
        print('⚠️ Could not resolve any documentId aliases to .documentId');
        return null;
      }

      // Use the first resolved .documentId
      final documentId = resolvedDocumentIds.first;
      print('✓ Using .documentId: $documentId');

      return ResolvedIds(documentId: documentId);
    } catch (e, stackTrace) {
      print('✗ Error resolving document ID: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}
