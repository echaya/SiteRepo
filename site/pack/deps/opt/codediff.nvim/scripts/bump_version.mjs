#!/usr/bin/env node
/**
 * Version bumping utility for vscode-diff.nvim
 * Semantic versioning: MAJOR.MINOR.PATCH[-PRERELEASE.N]
 * 
 * Supports:
 *   - Regular versions: 1.5.1
 *   - Prerelease versions: 2.0.0-next.1
 */

import { readFileSync, writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { execSync } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * Parse version string into components
 * @param {string} version - Version string like "1.5.1" or "2.0.0-next.1"
 * @returns {{ major: number, minor: number, patch: number, prerelease?: string, prereleaseNum?: number }}
 */
function parseVersion(version) {
  const match = version.match(/^(\d+)\.(\d+)\.(\d+)(?:-([a-z]+)\.(\d+))?$/i);
  if (!match) {
    throw new Error(`Invalid version format: ${version}`);
  }
  
  const result = {
    major: Number(match[1]),
    minor: Number(match[2]),
    patch: Number(match[3]),
  };
  
  if (match[4]) {
    result.prerelease = match[4];
    result.prereleaseNum = Number(match[5]);
  }
  
  return result;
}

/**
 * Format version components back to string
 */
function formatVersion({ major, minor, patch, prerelease, prereleaseNum }) {
  let version = `${major}.${minor}.${patch}`;
  if (prerelease !== undefined && prereleaseNum !== undefined) {
    version += `-${prerelease}.${prereleaseNum}`;
  }
  return version;
}

function bumpVersion(level) {
  const versionFile = join(__dirname, '..', 'VERSION');
  
  // Read current version
  const current = readFileSync(versionFile, 'utf8').trim();
  
  let parsed;
  try {
    parsed = parseVersion(current);
  } catch (e) {
    console.error(e.message);
    process.exit(1);
  }
  
  let { major, minor, patch, prerelease, prereleaseNum } = parsed;
  
  // Bump according to level
  switch (level) {
    case 'major':
      major += 1;
      minor = 0;
      patch = 0;
      prerelease = undefined;
      prereleaseNum = undefined;
      break;
    case 'minor':
      minor += 1;
      patch = 0;
      prerelease = undefined;
      prereleaseNum = undefined;
      break;
    case 'patch':
      patch += 1;
      prerelease = undefined;
      prereleaseNum = undefined;
      break;
    case 'prerelease':
      // Bump prerelease number (e.g., 2.0.0-next.1 → 2.0.0-next.2)
      if (prerelease === undefined) {
        console.error('Error: Cannot bump prerelease on a non-prerelease version');
        console.log('Current version is a stable release. Use major/minor/patch instead.');
        process.exit(1);
      }
      prereleaseNum += 1;
      break;
    default:
      console.error(`Error: Unknown level '${level}'`);
      console.log('Usage: bump_version.mjs [major|minor|patch|prerelease]');
      process.exit(1);
  }
  
  const newVersion = formatVersion({ major, minor, patch, prerelease, prereleaseNum });
  
  // Write new version
  writeFileSync(versionFile, newVersion + '\n');
  
  console.log(`✓ Bumped version: ${current} → ${newVersion}`);
  
  // Auto-commit VERSION file
  try {
    execSync('git add VERSION', { stdio: 'inherit' });
    execSync(`git commit -m "chore: bump version to ${newVersion}"`, { stdio: 'inherit' });
    console.log(`✓ Committed VERSION file`);
    console.log('\nNext steps:');
    console.log(`  git tag v${newVersion}`);
    console.log(`  git push && git push --tags`);
  } catch (error) {
    console.error('\n⚠️  Failed to auto-commit. Please commit manually:');
    console.log(`  git add VERSION`);
    console.log(`  git commit -m 'chore: bump version to ${newVersion}'`);
    console.log(`  git tag v${newVersion}`);
    console.log(`  git push && git push --tags`);
  }
  
  return newVersion;
}

// Main
if (process.argv.length < 3) {
  console.log('Usage: bump_version.mjs [major|minor|patch|prerelease]');
  console.log('\nExamples:');
  console.log('  bump_version.mjs patch      # 0.3.0 → 0.3.1 (bug fixes)');
  console.log('  bump_version.mjs minor      # 0.3.0 → 0.4.0 (new features)');
  console.log('  bump_version.mjs major      # 0.3.0 → 1.0.0 (breaking changes)');
  console.log('  bump_version.mjs prerelease # 2.0.0-next.1 → 2.0.0-next.2 (next branch)');
  process.exit(1);
}

bumpVersion(process.argv[2]);
