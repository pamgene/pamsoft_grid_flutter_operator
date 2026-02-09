# Pamsoft Grid Flutter Operator - Development Guide

## Project Overview

This is a Flutter web application for quality control of automated fiducial grid fitting on Pamstation experiment images. It runs as a Tercen operator, loading TIFF images from ZIP files and allowing users to manually adjust grid positions.

## Architecture

### Key Components

- **TercenImageService**: Loads images from Tercen ZIP files
- **TercenGridService**: Loads grid data from Tercen tables
- **DocumentIdResolver**: Resolves document IDs from Tercen task data
- **GridProvider**: State management for grid adjustments
- **ImageService**: Abstract interface for image loading (mock vs Tercen)

## Tercen Document ID Resolution

### The Problem

Tercen uses **document ID aliasing** to prevent file duplication across projects/workflows:

- **`documentId`** (no dot) = ALIAS - metadata ID that changes when projects are cloned
- **`.documentId`** (with dot) = ACTUAL FILE ID - immutable ID of the physical file

**Critical**: `fileService.download()` requires the actual `.documentId`, NOT an alias or WebAppOperator ID.

### The Solution

Navigate through Tercen's relation hierarchy to find `.documentId` in the InMemoryTable.

#### Relation Hierarchy

Tercen Relations are **expression trees**, not flat tables:

```
Relation (abstract)
├── Leaf Relations (actual data)
│   └── InMemoryRelation    ← Contains InMemoryTable with columns
└── Unary Wrappers (transformations)
    ├── GatherRelation      ← Wide → Long pivot
    └── CompositeRelation   ← Has mainRelation + joinOperators
```

#### Typical Structure

```
GatherRelation (depth 0)
    └── CompositeRelation (depth 1)
            └── mainRelation: InMemoryRelation (depth 2)
                    └── InMemoryTable
                            └── columns[]
                                    ├── .documentId (actual file ID) ✓
                                    ├── documentId (alias)
                                    ├── Image
                                    ├── spotRow
                                    └── ...
```

#### Navigation Algorithm

```dart
// Start from query.relation
var currentRelation = taskJson['query']['relation'] as Map?;
int depth = 0;

while (currentRelation != null && depth < 20) {
  final kind = currentRelation['kind'];

  // Found InMemoryRelation? Extract columns
  if (kind == 'InMemoryRelation' && currentRelation['inMemoryTable'] != null) {
    final columns = currentRelation['inMemoryTable']['columns'];

    // Search for .documentId column
    for (final col in columns) {
      if (col['name'] == '.documentId') {
        final documentId = col['values'].first;  // ← Use this!
        break;
      }
    }
    break;
  }

  // Navigate deeper:
  // - Most wrappers use 'relation' property
  // - CompositeRelation uses 'mainRelation' property
  if (currentRelation['relation'] != null) {
    currentRelation = currentRelation['relation'];
  } else if (kind == 'CompositeRelation' && currentRelation['mainRelation'] != null) {
    currentRelation = currentRelation['mainRelation'];
  } else {
    break;  // No more children
  }

  depth++;
}
```

### Fallback Strategy

If `.documentId` is not found directly in columns:

1. **Strategy 1**: Look for `.documentId` in InMemoryTable columns (preferred)
2. **Strategy 2**: Look for `documentId` aliases and resolve using `Relation.findDocumentId(alias)`
3. **NEVER use URL documentId** - it's the WebAppOperator ID, not a file ID

### Using Relation.findDocumentId() (SDK 1.11.0+)

The `sci_tercen_client` 1.11.0+ provides `Relation.findDocumentId(alias)` which resolves aliases:

```dart
// If you have an alias, resolve it to actual .documentId
final relation = cubeTask.query.relation;
final actualDocId = relation.findDocumentId(aliasDocumentId);

// Then use the actual .documentId for file download
final stream = fileService.download(actualDocId);
```

**How it works internally**:
- Searches InMemoryRelations for both `documentId` and `.documentId` columns
- Finds the index where alias matches
- Returns the `.documentId` value at that same index

## Common Pitfalls

### ❌ Wrong: Using URL documentId
```dart
// This is the WebAppOperator ID, not the file ID!
final documentId = urlParser.documentId;
fileService.download(documentId);  // ← 500 Error: "WebAppOperator"
```

### ❌ Wrong: Using relation.inMemoryRelations getter
```dart
// This doesn't navigate through wrappers!
final inMemoryRelations = relation.inMemoryRelations;  // ← Empty!
```

### ✅ Correct: Navigate manually through JSON
```dart
// Navigate through wrappers to find InMemoryTable
var currentRelation = taskJson['query']['relation'];
while (currentRelation != null) {
  if (currentRelation['kind'] == 'InMemoryRelation') {
    // Found it! Extract .documentId from columns
  }
  // Navigate deeper...
}
```

## Development

### Build and Deploy
```bash
flutter build web --release
git add -A
git commit -m "Description"
git push
```

### Testing Locally
Use the mock service by not initializing Tercen:
```dart
// In service_locator.dart
locator.registerSingleton<ImageService>(MockImageService());
```

### Debugging Document ID Issues

1. Check console logs for relation navigation:
   ```
   📋 Relation[0] kind: GatherRelation
   📋 Relation[1] kind: CompositeRelation
   📋 CompositeRelation detected, navigating to mainRelation...
   📋 Relation[2] kind: InMemoryRelation
   ✓ Found InMemoryRelation at depth 2
   📋 InMemoryTable has X columns
   📋 Found Y .documentId value(s) in column "...": <id>
   ✓ Using .documentId directly: <id>
   ```

2. If file download fails with "WebAppOperator" error:
   - You're using an alias or URL documentId instead of `.documentId`
   - Check that you navigated to InMemoryRelation successfully
   - Verify the value is from the `.documentId` column (with dot!)

## Dependencies

- **sci_tercen_client 1.11.0+**: Required for `Relation.findDocumentId()` method
- **Flutter SDK 3.38.3+**: For web compilation
- **archive**: For ZIP extraction
- **image**: For TIFF to PNG conversion

## References

- [Tercen Relational Algebra Docs](https://github.com/tercen/sci/blob/main/docs/TERCEN_RELATIONAL_ALGEBRA.md)
- [sci_tercen_client SDK](https://github.com/tercen/sci_tercen_client)
- Working example: `_local/pamsoft_grid_shiny_operator/server.R` (ShinyR implementation)
