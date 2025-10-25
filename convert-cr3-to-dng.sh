#!/usr/bin/env bash
#
# Convert all *.cr3 files under /mnt/qnap/photos/landing to DNG,
# preserving folder structure in /mnt/qnap/photos/landing-converted.
# Features:
#   --dry-run : list files without converting
#
# Requires: dnglab

set -euo pipefail

SRC="/mnt/qnap/photos/landing"
DST="/mnt/qnap/photos/landed-converted"
DRY_RUN=false

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --jobs) echo "⚠️  Warning: --jobs option is no longer used. dnglab handles parallelization internally."; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# --- Pre-flight checks ---
command -v dnglab >/dev/null 2>&1 || { echo "❌ dnglab not found in PATH"; exit 1; }

if [[ ! -d "$SRC" ]]; then
  echo "❌ Source directory does not exist: $SRC"
  exit 1
fi

mkdir -p "$DST"

# --- Function to process a directory ---
convert_directory() {
  local src_dir="$1"
  local dst_dir="$2"
  local relative_path="${src_dir#$SRC}"
  relative_path="${relative_path#/}"  # Remove leading slash
  
  if $DRY_RUN; then
    # In dry-run, only check this specific directory (not recursive)
    if ! find "$src_dir" -maxdepth 1 -type f -iname "*.cr3" -print -quit | grep -q .; then
      return 0
    fi
    echo "[DRY-RUN] Would convert directory: ${relative_path:-"(root)"}"
    find "$src_dir" -maxdepth 1 -type f -iname "*.cr3" -printf "  %f → %f\n" | sed 's/\.cr3$/.dng/'
    return 0
  fi

  echo "⚙️ Converting directory: ${relative_path:-"(root)"}"
  echo "   Source: $src_dir"
  echo "   Target: $dst_dir"
  
  # Use dnglab's directory conversion with recursive processing
  if dnglab convert --recursive --override --embed-raw false --compression lossless -v "$src_dir" "$dst_dir"; then
    echo "✅ Done: ${relative_path:-"(root)"}"
  else
    echo "❌ Error converting directory: ${relative_path:-"(root)"}"
    return 1
  fi
}

echo "🔍 Converting CR3 files from $SRC to $DST ..."

if $DRY_RUN; then
  echo "[DRY-RUN] Scanning for CR3 files..."
  # Simple dry-run: just list all CR3 files that would be converted
  if ! find "$SRC" -maxdepth 1 -type d -readable 2>/dev/null | grep -q .; then
    echo "[DRY-RUN] ❌ Cannot access source directory: $SRC"
    exit 1
  fi
  
  cr3_files=$(find "$SRC" -type f -iname "*.cr3" 2>/dev/null | wc -l)
  if [[ $cr3_files -gt 0 ]]; then
    echo "[DRY-RUN] Found $cr3_files CR3 files that would be converted:"
    find "$SRC" -type f -iname "*.cr3" 2>/dev/null | sed "s|$SRC/||" | sed 's/\.cr3$/.dng/' | head -10
    if [[ $cr3_files -gt 10 ]]; then
      echo "   ... and $((cr3_files - 10)) more files"
    fi
  else
    echo "[DRY-RUN] No CR3 files found in $SRC"
  fi
else
  # For actual conversion, let dnglab handle the entire source directory at once
  convert_directory "$SRC" "$DST"
fi

if $DRY_RUN; then
  echo "✨ Dry-run complete — no files converted."
else
  echo "🎉 All conversions complete."
fi
