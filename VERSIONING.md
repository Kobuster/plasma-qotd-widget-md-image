# Version Management

This project uses a centralized version management system to keep versions consistent across Plasma 5 and Plasma 6 widgets.

## Files

- **`VERSION`** - Single source of truth for the current version number
- **`set-version.sh`** - Script to update version across all metadata files
- **`plasma5/metadata.desktop`** - Plasma 5 metadata (auto-updated)
- **`plasma6/metadata.json`** - Plasma 6 metadata (auto-updated)

## Updating the Version

To update the version number for both Plasma 5 and Plasma 6:

```bash
./set-version.sh <version>
```

### Examples

```bash
# Update to version 3.1
./set-version.sh 3.1

# Update to version 3.1.2
./set-version.sh 3.1.2
```

The script will:
1. Show the current version
2. Validate the new version format
3. Ask for confirmation
4. Update the VERSION file
5. Update plasma5/metadata.desktop
6. Update plasma6/metadata.json

## Version Format

Use semantic versioning: `MAJOR.MINOR` or `MAJOR.MINOR.PATCH`

Examples: `3.0`, `3.1`, `3.1.2`, `4.0.0`

## Workflow

1. **Update version**: `./set-version.sh 3.1`
2. **Review changes**: `git diff`
3. **Commit**: `git commit -am 'Bump version to 3.1'`
4. **Tag release**: `git tag v3.1`
5. **Build packages**: `./build-packages.sh`
6. **Push**: `git push && git push --tags`
