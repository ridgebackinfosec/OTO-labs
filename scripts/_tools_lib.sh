# _tools_lib.sh — shared library for lab_essential_tools.sh and extra_tools.sh
# Source this file; do not execute directly.

FAILURES=()

run_step() {
    local label="$1"; shift
    local tmpfile exit_code
    tmpfile=$(mktemp)
    "$@" 2>&1 | tee "$tmpfile"
    exit_code=${PIPESTATUS[0]}
    if [ $exit_code -eq 0 ]; then
        rm -f "$tmpfile"
        return 0
    fi
    # If an apt install failed with a 404, refresh the cache and retry once
    if grep -q "404" "$tmpfile" && [[ " $* " == *" apt "* || " $* " == *" apt-get "* ]]; then
        echo -e "\e[0;33m[RETRYING] $label — 404 detected, refreshing apt cache\e[m"
        sudo apt-get -o DPkg::Lock::Timeout=300 update
        rm -f "$tmpfile"
        tmpfile=$(mktemp)
        "$@" 2>&1 | tee "$tmpfile"
        exit_code=${PIPESTATUS[0]}
        if [ $exit_code -eq 0 ]; then
            rm -f "$tmpfile"
            return 0
        fi
    fi
    echo -e "\e[0;31m[FAILED] $label\e[m"
    FAILURES+=("$label")
    rm -f "$tmpfile"
}

tools_summary_and_exit() {
    set +x
    local script_name
    script_name="$(basename "$0")"
    echo ""
    echo "=================================================="
    if [ ${#FAILURES[@]} -eq 0 ]; then
        echo -e "\e[0;32m[$script_name] All steps completed successfully.\e[m"
    else
        echo -e "\e[0;31m[$script_name] ${#FAILURES[@]} tool(s) failed to install:\e[m"
        for i in "${!FAILURES[@]}"; do
            echo -e "  \e[0;31m- ${FAILURES[$i]}\e[m"
        done
        echo ""
        echo "Full output: $LOG_FILE"
    fi
    echo "=================================================="
    echo "[$(date)] $script_name finished"
    exit ${#FAILURES[@]}
}
