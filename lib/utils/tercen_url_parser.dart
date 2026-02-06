/// Parses Tercen URL to determine deployment mode and extract IDs.
class TercenUrlParser {
  String? documentId;
  String? workflowId;
  String? stepId;
  String? taskId;
  bool isStandaloneMode = false;
  bool isWorkflowMode = false;

  TercenUrlParser() {
    _parseUrl();
  }

  /// Returns true if app is running inside a Data Step (has taskId parameter).
  bool get isInDataStep => taskId != null;

  /// Returns true if app should show its own top bar (not in Data Step).
  bool get shouldShowTopBar => !isInDataStep;

  /// Returns true if either standalone or workflow mode is detected.
  bool get hasValidContext => isStandaloneMode || isWorkflowMode;

  void _parseUrl() {
    final uri = Uri.base;
    final pathSegments = uri.pathSegments;

    print('🔍 Parsing URL: ${uri.toString()}');
    print('📋 Path segments: $pathSegments');

    // Check for Data Step context (taskId in query parameters)
    taskId = uri.queryParameters['taskId'];
    if (taskId != null) {
      print('✓ Data Step context detected: taskId=$taskId');
    }

    // Mode 1: Standalone - /_w3op/{documentId}/
    if (pathSegments.contains('_w3op')) {
      final index = pathSegments.indexOf('_w3op');
      if (index + 1 < pathSegments.length) {
        documentId = pathSegments[index + 1];
        isStandaloneMode = true;
        print('✓ Standalone mode detected: documentId=$documentId');
      }
    }
    // Mode 2: Workflow - /w/{workflowId}/ds/{stepId}
    else if (pathSegments.contains('w') && pathSegments.contains('ds')) {
      final wIndex = pathSegments.indexOf('w');
      final dsIndex = pathSegments.indexOf('ds');

      if (wIndex + 1 < pathSegments.length &&
          dsIndex + 1 < pathSegments.length) {
        workflowId = pathSegments[wIndex + 1];
        stepId = pathSegments[dsIndex + 1];
        isWorkflowMode = true;
        print('✓ Workflow mode detected: workflowId=$workflowId, stepId=$stepId');
      }
    }
    // Development mode (localhost)
    else if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      // For local development, try query params
      workflowId = uri.queryParameters['workflowId'];
      stepId = uri.queryParameters['stepId'];

      if (workflowId != null && stepId != null) {
        isWorkflowMode = true;
        print('🔧 DEV MODE: Using workflowId=$workflowId, stepId=$stepId from query params');
      } else {
        print('🔧 DEV MODE: localhost detected, will use mock data or query params');
      }
    } else {
      print('✗ No valid Tercen URL pattern detected');
    }
  }
}
