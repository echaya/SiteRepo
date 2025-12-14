# Merge Alignment Parity Gap Analysis

## Status: Test Framework Complete

Date: 2025-12-09

## Test Framework

Created comparison test framework to validate merge alignment between VSCode and our Lua implementation.

### Files Created

1. **`vscode-merge.mjs`** (project root) - Bundled VSCode merge alignment algorithm
   - Built from VSCode source using `scripts/build-vscode-merge.sh`
   - Uses VSCode's actual `MappingAlignment.compute()` and `getAlignments()`
   - Guarantees 100% identical algorithm to VSCode

2. **`scripts/build-vscode-merge.sh`** - Build script for vscode-merge.mjs
   - Sparse clones VSCode repository
   - Imports from `mergeEditor/browser/model/mapping.ts`, `view/lineAlignment.ts`
   - Uses esbuild to bundle into standalone .mjs

3. **`scripts/merge_alignment_cli.lua`** - Lua CLI tool for our implementation
   - Uses `merge_alignment.compute_merge_fillers_and_conflicts()`
   - Outputs compatible JSON format

4. **`scripts/test_merge_comparison.sh`** - Comparison test script
   - Runs both implementations on same input files
   - Compares diff results, fillers, and alignments
   - Reports differences

### Usage

```bash
# With explicit files
./scripts/test_merge_comparison.sh <base> <input1> <input2>

# Auto-extract from git merge conflict
cd ~/vscode-merge-test
/path/to/scripts/test_merge_comparison.sh
```

## Test Results Summary

Tested with `~/vscode-merge-test` merge conflict (app.py, 244 base lines):

| Metric | VSCode | Lua | Status |
|--------|--------|-----|--------|
| Diff base→input1 | 51 changes | 51 changes | ✅ Match |
| Diff base→input2 | 47 changes | 47 changes | ✅ Match |
| Left fillers count | 13 | 12 | ❌ Differ |
| Right fillers count | 15 | 15 | ⚠️ Positions differ |

## Identified Gaps

### Gap 1: Missing Filler at Line 145
- VSCode produces a filler at `after_line: 145, count: 1`
- Lua implementation misses this filler

### Gap 2: Filler Position Differences
- VSCode: `after_line: 108` vs Lua: `after_line: 103`
- VSCode: `after_line: 281` vs Lua: `after_line: 282`

### Gap 3: Filler Count Difference
- Right filler at line 148: VSCode count=3, Lua count=2

## Root Cause Analysis

The differences stem from how `getAlignments()` processes common equal range mappings:

1. **VSCode's approach**: Uses `toEqualRangeMappings()` with character-level RangeMappings from `innerChanges`
2. **Lua's approach**: Uses line-level inner_changes without full character position information

The key issue is that VSCode's `getAlignments()` operates on character positions (`Position` objects with line+column), while our Lua port may be simplifying to line-only positions.

## Recommended Fixes

1. **Ensure inner_changes preserve character positions** - Verify our diff output includes full `startColumn`, `endColumn` for inner changes

2. **Review `to_equal_range_mappings`** - Compare character-level position handling between VSCode and Lua

3. **Test with simpler cases** - Create minimal test cases that isolate specific alignment scenarios

## Next Steps

1. Create minimal test cases with known expected outputs
2. Debug `get_alignments()` step by step for a single mapping_alignment
3. Compare intermediate values (equalRanges1, equalRanges2, commonRanges)
4. Fix position calculation in Lua implementation
