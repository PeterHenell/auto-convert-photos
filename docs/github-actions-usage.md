# Example: Using CR3-to-DNG Converter in Your GitHub Actions

This shows how to use the pre-built CR3-to-DNG converter container image in your own GitHub Actions workflows.

## Example Workflow

```yaml
name: Convert Camera Photos

on:
  workflow_dispatch:
    inputs:
      source_path:
        description: 'Path to CR3 files'
        required: true
        default: './photos/raw'
      dest_path:
        description: 'Path for converted DNG files'
        required: true
        default: './photos/converted'

jobs:
  convert-photos:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Create directories
        run: |
          mkdir -p ${{ github.event.inputs.dest_path }}

      - name: Convert CR3 to DNG
        run: |
          docker run --rm \
            -v "$PWD/${{ github.event.inputs.source_path }}:/photos/landing:ro" \
            -v "$PWD/${{ github.event.inputs.dest_path }}:/photos/converted" \
            ghcr.io/peterhenell/auto-convert-photos:latest

      - name: Upload converted files
        uses: actions/upload-artifact@v4
        with:
          name: converted-dng-files
          path: ${{ github.event.inputs.dest_path }}
```

## Automated Photo Processing

```yaml
name: Automated Photo Processing

on:
  push:
    paths:
      - 'photos/raw/**/*.cr3'
      - 'photos/raw/**/*.CR3'

jobs:
  process-photos:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Convert new CR3 files
        run: |
          docker run --rm \
            -v "$PWD/photos/raw:/photos/landing:ro" \
            -v "$PWD/photos/converted:/photos/converted" \
            ghcr.io/peterhenell/auto-convert-photos:latest

      - name: Commit converted files
        uses: stefanzweifel/git-auto-commit-action@v5
        with:
          commit_message: 'Auto-convert CR3 files to DNG'
          file_pattern: 'photos/converted/*.dng'
```

## Using in Docker Compose

```yaml
version: '3.8'

services:
  cr3-converter:
    image: ghcr.io/peterhenell/auto-convert-photos:latest
    volumes:
      - ./photos/raw:/photos/landing:ro
      - ./photos/converted:/photos/converted
    command: ["--dry-run"]  # Remove for actual conversion
```

## Tips

1. **Use specific tags** for production workflows: `ghcr.io/peterhenell/auto-convert-photos:v1.0.0`
2. **Always dry-run first** to verify what will be converted
3. **Use artifacts** to store converted files from GitHub Actions
4. **Mount directories** as read-only (`:ro`) when possible for safety