#!/bin/bash

################################################################################
# Excel Export Library - Export artifact data to Excel format
#
# Description:
#   Exports artifact search results to Excel (.xlsx) format
#   Columns: Artifact Path, Artifact Type, Size, Project Path
################################################################################

set -eo pipefail

# Export artifacts to Excel file
# Args: output_filename
export_to_excel() {
    local output_file="$1"
    local temp_csv="${output_file%.xlsx}.csv"

    # Create CSV header
    echo "Artifact Path,Artifact Type,Size,Project Path" > "$temp_csv"

    # Add artifact data
    local i
    for i in "${!ARTIFACT_PATHS[@]}"; do
        local path="${ARTIFACT_PATHS[$i]}"
        local type="${ARTIFACT_TYPES[$i]}"
        local project="${ARTIFACT_PROJECTS[$i]}"
        local size=$(du -sh "$path" 2>/dev/null | cut -f1)

        # Escape commas in paths
        path="${path//,/\,}"
        project="${project//,/\,}"

        echo "\"$path\",\"$type\",\"$size\",\"$project\"" >> "$temp_csv"
    done

    # Check if we have Python available for xlsx conversion
    if command -v python3 &>/dev/null; then
        # Try to convert CSV to XLSX using Python
        python3 -c "
import sys
try:
    import pandas as pd
    df = pd.read_csv('$temp_csv')
    df.to_excel('$output_file', index=False, engine='openpyxl')
    print('Excel file created successfully')
    sys.exit(0)
except ImportError:
    print('pandas or openpyxl not available, keeping CSV format')
    sys.exit(1)
" 2>/dev/null

        if [[ $? -eq 0 ]]; then
            # Successfully created XLSX, remove CSV
            rm "$temp_csv"
            echo "$output_file"
        else
            # Fallback to CSV
            mv "$temp_csv" "${output_file%.xlsx}.csv"
            echo "${output_file%.xlsx}.csv"
        fi
    else
        # No Python, just use CSV
        mv "$temp_csv" "${output_file%.xlsx}.csv"
        echo "${output_file%.xlsx}.csv"
    fi
}

# Prompt user for Excel export
# Returns: 0 if export requested, 1 if skipped
prompt_excel_export() {
    echo ""
    echo -n "Export results to Excel? [y/N]: "
    read -r response

    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
