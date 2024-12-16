#!/bin/bash

# -----------------------------------------------------------------------------
# Script Name: copy_nix.sh
# Description: 
#   - Recursively searches for all .nix files within a specified directory 
#     (including all subdirectories).
#   - Generates a tree-like structure of the found .nix files, excluding
#     directories without any .nix files.
#   - Precedes each file's content with a comment indicating its file path.
#   - Concatenates the tree and all file contents.
#   - Copies the combined content to the clipboard using wl-copy.
# Usage: ./copy_nix.sh [directory]
#        If no directory is specified, the current directory is used.
# Requirements:
#   - bash
#   - find
#   - wl-copy (part of the wl-clipboard package)
#   - tree (optional, for enhanced tree structure)
# -----------------------------------------------------------------------------

# Function to display usage information
usage() {
    echo "Usage: $0 [directory]"
    echo "Recursively copies the contents of all .nix files in the specified directory"
    echo "and its subdirectories to the clipboard using wl-copy."
    echo
    echo "  directory    The target directory to search for .nix files."
    echo "               If not provided, the current directory is used."
    exit 1
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

# Set the target directory to the first argument or default to current directory
TARGET_DIR="${1:-.}"

# Verify that the target directory exists and is a directory
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: '$TARGET_DIR' is not a valid directory."
    exit 1
fi

# Check if wl-copy is installed
if ! command -v wl-copy >/dev/null 2>&1; then
    echo "Error: 'wl-copy' is not installed. Please install it and try again."
    echo "You can install it on most systems via your package manager, e.g.,"
    echo "  sudo apt install wl-clipboard    # On Debian/Ubuntu"
    echo "  sudo pacman -S wl-clipboard      # On Arch Linux"
    echo "  sudo dnf install wl-clipboard    # On Fedora"
    exit 1
fi

# Optional: Check if 'tree' is installed for a better tree structure
USE_TREE=false
if command -v tree >/dev/null 2>&1; then
    USE_TREE=true
else
    echo "Notice: 'tree' command is not installed. A simple tree structure will be generated."
    echo "       To install 'tree' for a better tree structure, run:"
    echo "         sudo apt install tree         # On Debian/Ubuntu"
    echo "         sudo pacman -S tree           # On Arch Linux"
    echo "         sudo dnf install tree         # On Fedora"
    echo
fi

# Find all .nix files recursively
echo "Searching for .nix files in '$TARGET_DIR' and its subdirectories..."

# Using find to locate all .nix files
# -type f ensures only regular files are found
# -name "*.nix" filters for files ending with .nix
# -print0 and read -d '' handle filenames with spaces and special characters
NIX_FILES_FOUND=false
while IFS= read -r -d '' file; do
    NIX_FILES_FOUND=true
    break
done < <(find "$TARGET_DIR" -type f -name "*.nix" -print0)

if [[ "$NIX_FILES_FOUND" != true ]]; then
    echo "No .nix files found in '$TARGET_DIR' or its subdirectories."
    exit 0
fi

# Generate the tree structure of .nix files
echo "Generating tree structure of .nix files..."

if $USE_TREE; then
    # Using 'tree' to generate a tree of .nix files
    # The '-P' option filters files matching the pattern
    # The '--prune' option omits directories without matching files
    # The '--noreport' option omits the file/directory count at the end
    TREE_OUTPUT=$(tree "$TARGET_DIR" -P "*.nix" --prune --noreport 2>/dev/null)
    # If TREE_OUTPUT is empty, it means no .nix files were found (should not happen here)
    if [[ -z "$TREE_OUTPUT" ]]; then
        echo "No .nix files found to include in the tree structure."
        TREE_OUTPUT="No .nix files found."
    fi
else
    # Generate a simple tree structure using find and awk
    # This will only list .nix files, indented to represent directory hierarchy
    # Note: This is a basic approximation and may not handle all edge cases
    TREE_OUTPUT=$(find "$TARGET_DIR" -type f -name "*.nix" | sed "s|^$TARGET_DIR/||" | awk '
    BEGIN {
        FS="/";
    }
    {
        indent = ""
        for(i=1;i<NF;i++) {
            indent = indent "    "
        }
        print indent "|-- " $NF
    }')
    if [[ -z "$TREE_OUTPUT" ]]; then
        TREE_OUTPUT="No .nix files found."
    fi
fi

# Combine tree and file contents and copy to clipboard
echo "Aggregating tree structure and contents of all .nix files..."

{
    # Output the tree structure
    echo "Nix Files Tree Structure:"
    echo "$TREE_OUTPUT"
    echo ""

    # Output the file contents with file indicators
    # Using find with -print0 to handle special filenames
    find "$TARGET_DIR" -type f -name "*.nix" -print0 | while IFS= read -r -d '' file; do
        # Prepend a comment indicating the file path
        echo "// ==== $file ===="
        
        # Output the file's content
        cat "$file"
        
        # Add extra newline for separation
        echo ""
    done
} | wl-copy

# Verify that wl-copy succeeded
if [[ $? -eq 0 ]]; then
    echo "Successfully copied the tree structure and contents of all .nix files to the clipboard."
    if $USE_TREE; then
        echo "The tree structure was generated using the 'tree' command."
    else
        echo "A simple tree structure was generated using 'find' and 'awk'."
    fi
else
    echo "Failed to copy contents to the clipboard."
    exit 1
fi

exit 0


