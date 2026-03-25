# _tools_lib.sh — shared library for lab_essential_tools.sh and extra_tools.sh
# Source this file; do not execute directly.

SCRIPT_START=$(date +%s)
FAILURES=()

format_elapsed() {
    local secs="$1"
    if [ "$secs" -ge 60 ]; then
        printf "%dm %ds" $(( secs / 60 )) $(( secs % 60 ))
    else
        printf "%ds" "$secs"
    fi
}

run_step() {
    local label="$1"; shift
    local tmpfile exit_code step_start elapsed
    tmpfile=$(mktemp)
    step_start=$(date +%s)
    echo -n "  Installing $label..."
    "$@" > "$tmpfile" 2>&1
    exit_code=$?
    elapsed=$(( $(date +%s) - step_start ))
    cat "$tmpfile" >> "$LOG_FILE"
    if [ $exit_code -eq 0 ]; then
        echo " done ($(format_elapsed $elapsed))"
        rm -f "$tmpfile"
        return 0
    fi
    # If an apt install failed with a 404, refresh the cache and retry once
    if grep -q "404" "$tmpfile" && [[ " $* " == *" apt "* || " $* " == *" apt-get "* ]]; then
        echo ""
        echo -e "\e[0;33m[RETRYING] $label — 404 detected, refreshing apt cache\e[m"
        rm -f "$tmpfile"
        tmpfile=$(mktemp)
        sudo apt-get -o DPkg::Lock::Timeout=300 update > "$tmpfile" 2>&1
        cat "$tmpfile" >> "$LOG_FILE"
        rm -f "$tmpfile"
        tmpfile=$(mktemp)
        step_start=$(date +%s)
        echo -n "  Installing $label (retry)..."
        "$@" > "$tmpfile" 2>&1
        exit_code=$?
        elapsed=$(( $(date +%s) - step_start ))
        cat "$tmpfile" >> "$LOG_FILE"
        if [ $exit_code -eq 0 ]; then
            echo " done ($(format_elapsed $elapsed))"
            rm -f "$tmpfile"
            return 0
        fi
    fi
    echo ""
    echo -e "\e[0;31m[FAILED] $label ($(format_elapsed $elapsed))\e[m"
    FAILURES+=("$label")
    rm -f "$tmpfile"
}

# pipx_install <label> <url> <upgrade-name>
pipx_install() {
    local label="$1" url="$2" upgrade_name="$3"
    run_step "pipx: $label" bash -c "pipx install git+$url || pipx upgrade $upgrade_name"
}

# clone_tool <label> <url>  — clone only, no venv
clone_tool() {
    local label="$1" url="$2"
    local dir="$HOME/git-tools/$label"
    if [ ! -d "$dir" ]; then
        run_step "git: $label" bash -c "git clone $url $dir"
    else
        echo "  $label already cloned, skipping..."
    fi
}

# clone_tool_venv <label> <url>  — clone + venv + pip install -r requirements.txt
clone_tool_venv() {
    local label="$1" url="$2"
    local dir="$HOME/git-tools/$label"
    if [ ! -d "$dir" ]; then
        run_step "git: $label" bash -c "
            git clone $url $dir &&
            cd $dir &&
            python3 -m venv venv &&
            source venv/bin/activate &&
            pip install -r requirements.txt &&
            deactivate
        "
    else
        echo "  $label already cloned, skipping..."
    fi
}

tools_summary_and_exit() {
    set +x
    local script_name total_elapsed
    script_name="$(basename "$0")"
    total_elapsed=$(( $(date +%s) - SCRIPT_START ))

    sudo apt autoremove -y
    sudo updatedb

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
    echo "Total time: $(format_elapsed $total_elapsed)"
    echo "=================================================="
    echo "[$(date)] $script_name finished"
    exit ${#FAILURES[@]}
}
