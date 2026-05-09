# ==========================================
# 1. 基本パス・環境変数の設定
# ==========================================

# 重複するパスを自動的に削除する設定
typeset -U path PATH

export PATH="$HOME/scripts:$HOME/.local/bin:$PATH"
export GITHUB_PATH="$HOME/projects/github.com"
export XDG_CONFIG_HOME="$HOME/.config"
export GPG_TTY=$(tty)

os_type="$(uname)"
arch_name="$(uname -m)"

# Linux: ディストリビューション名を取得
if [ "$os_type" = "Linux" ] && [ -f /etc/os-release ]; then
    distro=$(. /etc/os-release && echo "${ID:-linux}" | tr '[:upper:]' '[:lower:]')
else
    distro="$os_type"
fi

# 対話シェルの時だけOS情報を表示
if [[ $- == *i* ]]; then
    echo ">>> ${os_type}/${arch_name} <<<"
fi

# ==========================================
# 2. Homebrew のセットアップ (macOS / Linux Homebrew)
# ==========================================
HOMEBREW_PREFIX_PATH=""
if [ "$os_type" = "Darwin" ]; then
    if [ "${arch_name}" = "arm64" ] && [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        HOMEBREW_PREFIX_PATH="/opt/homebrew"
    elif [ -f "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
        HOMEBREW_PREFIX_PATH="/usr/local"
    fi
elif [ "$os_type" = "Linux" ] && [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    # Linuxbrew 用
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    HOMEBREW_PREFIX_PATH="/home/linuxbrew/.linuxbrew"
fi

# ==========================================
# 3. ツール類の初期化 (mise, starship, zoxide)
# ==========================================
# mise (言語マネージャー)
if command -v mise > /dev/null; then
    eval "$(mise activate zsh)"
    export MISE_DATA_DIR="$HOME/.mise"
    export MISE_CACHE_DIR="$MISE_DATA_DIR/cache"
fi

# ==========================================
# 4. fzf (インクリメンタルサーチ) の統合設定
# ==========================================
if command -v fzf > /dev/null; then
    export FZF_DEFAULT_COMMAND="rg --files --hidden -g '!.git/*' -g '!node_modules/*'"

    export FZF_DEFAULT_OPTS="--height 100% --layout=reverse --border --multi --preview '
        if [ -d {} ]; then
            ls -F --color=always {} | head -200
        else
            cat {}
        fi'"

    # Homebrew経由 (macOS)
    if [ -n "$HOMEBREW_PREFIX_PATH" ]; then
        [ -f "$HOMEBREW_PREFIX_PATH/opt/fzf/shell/key-bindings.zsh" ] && \
            source "$HOMEBREW_PREFIX_PATH/opt/fzf/shell/key-bindings.zsh"
        [ -f "$HOMEBREW_PREFIX_PATH/opt/fzf/shell/completion.zsh" ] && \
            source "$HOMEBREW_PREFIX_PATH/opt/fzf/shell/completion.zsh"
    fi

    # システムインストール (Fedora / Ubuntu)
    [ -f "/usr/share/fzf/shell/key-bindings.zsh" ] && \
        source "/usr/share/fzf/shell/key-bindings.zsh"
    [ -f "/usr/share/fzf/shell/completion.zsh" ] && \
        source "/usr/share/fzf/shell/completion.zsh"
    # Ubuntu の場合
    [ -f "/usr/share/doc/fzf/examples/key-bindings.zsh" ] && \
        source "/usr/share/doc/fzf/examples/key-bindings.zsh"
fi

# ==========================================
# 5. ファイル一覧取得 (ripgrep最適化版)
# ==========================================
myfind() {
    if command -v rg > /dev/null 2>&1; then
        # --- ripgrepがある場合 ---
        # -L (--follow): シンボリックリンクを辿る
        # --files: ファイル一覧のみ出力
        # --hidden: 隠しファイルも含む
        # --glob: 特定の除外パターンを追加（.gitなどはデフォルトで除外される）
        rg --files --hidden -L 2>/dev/null
    else
        # --- ripgrepがない場合 (従来のfind処理) ---
        local prune_args=()
        local name_args=()
        prune_args+=( -path "./.git" -prune -o -path "./node_modules" -prune -o -path "./__pycache__" -prune -o )
        name_args+=( -not -name "*.pyc" -not -name ".DS_Store" )

        for ignore_file in .gitignore .claudecodeignore; do
            if [[ -f "$ignore_file" ]]; then
                while IFS= read -r line; do
                    [[ "$line" =~ ^[[:space:]]*# ]] && continue
                    [[ -z "$line" ]] && continue
                    local pattern="${line%/}"; pattern="${pattern#./}"; pattern="${pattern#/}"
                    if [[ "$line" == */ ]]; then
                        prune_args+=( -path "./$pattern" -prune -o )
                    else
                        name_args+=( -not -name "$pattern" -not -path "*/$pattern" )
                    fi
                done < "$ignore_file"
            fi
        done
        find . "${prune_args[@]}" \( -type f -o -type l \) "${name_args[@]}" -print | sed 's|^\./||'
    fi
}

# ==========================================
# 6. インクリメンタル検索 & 選択
# ==========================================
fvi() {
    local initial_query="$1"
    
    # rgがある場合は非常に高速なため、5000件制限を緩和してもOK（ここでは10000件にアップ）
    local limit=50000
    echo -n "🔍 読み込み中... "
    
    local all_files
    all_files=$(myfind | head -n $limit)
    
    if [[ -z "$all_files" ]]; then
        echo -e "\nファイルが見つかりません。"
        return 1
    fi

    # --- (中略: インクリメンタルサーチのループ部分は変更なし) ---
    # ※ current_list の生成部分を少しだけ高速化
    
    local query="$initial_query"
    local char=""
    local -a current_list
    
    tput smcup 2>/dev/null || clear
    
    while :; do
        tput clear
        echo "🔍 インクリメンタル検索 (Enter: 決定, Esc/Ctrl-C: キャンセル)"
        echo "---------------------------------------------------------"
        echo -e "Query: \e[4m${query}\e[24m_"
        echo "---------------------------------------------------------"

        if [[ -z "$query" ]]; then
            # ls -dt が重い場合があるため、簡易表示
            current_list=("${(@f)$(echo "$all_files" | head -n 20)}")
        else
            # ここでも rg があれば rg でフィルタリングするとさらに速いですが、
            # すでに変数に格納済みの全ファイルに対しては grep -i で十分です。
            current_list=("${(@f)$(echo "$all_files" | grep -i "$query" | head -n 20)}")
        fi

        local i=1
        for f in "${current_list[@]}"; do
            printf "%2d) %s\n" $i "$f"
            ((i++))
        done
        echo "---------------------------------------------------------"

        if ! read -rs -k 1 char < /dev/tty; then
            tput rmcup 2>/dev/null; return 0
        fi

        if [[ "$char" == $'\x03' || "$char" == $'\e' ]]; then
            tput rmcup 2>/dev/null; return 0
        fi

        if [[ "$char" == $'\n' || "$char" == $'\r' ]]; then
            break
        fi

        if [[ "$char" == $'\x7f' || "$char" == $'\b' ]]; then
            query="${query%?}"
        elif [[ "$char" =~ [[:print:]] ]]; then
            query="${query}${char}"
        fi
    done
    
    tput rmcup 2>/dev/null

    # --- (以下、番号選択処理は元のコードと同じ) ---
    if [[ ${#current_list[@]} -eq 0 ]]; then
        echo "候補がありませんでした。"
        return 1
    elif [[ ${#current_list[@]} -eq 1 ]]; then
        ${EDITOR:-vi} "${current_list[1]}"
        return 0
    fi

    echo "■ 以下の候補から選択してください"
    local i=1
    for f in "${current_list[@]}"; do
        printf "%2d) %s\n" $i "$f"
        ((i++))
    done

    echo -n "番号を入力 (1-${#current_list[@]}, q:キャンセル) [Default: 1]: "
    local res
    read -r res < /dev/tty
    [[ "$res" == "q" ]] && return 0
    [[ -z "$res" ]] && res=1
    if [[ "$res" =~ ^[0-9]+$ ]] && [[ "$res" -le "${#current_list[@]}" ]]; then
        ${EDITOR:-vi} "${current_list[$res]}"
    fi
}

# ==========================================
# 7. 簡易オートサジェスト
# ==========================================

_MY_AS_IGNORE_ONCE=0

_my_autosuggest_strategy() {
    if [[ $_MY_AS_IGNORE_ONCE -eq 1 ]]; then
        _MY_AS_IGNORE_ONCE=0
        POSTDISPLAY=""
        region_highlight=()
        return
    fi

    # バッファが空、または「カーソルが行末にない」場合はサジェストしない
    if [[ -z "$BUFFER" || $CURSOR -ne ${#BUFFER} ]]; then
        POSTDISPLAY=""
        region_highlight=()
        return
    fi

    # (b)フラグで BUFFER 内の特殊記号(*や[など)をエスケープして安全に検索
    local suggestion=${history[(r)${(b)BUFFER}*]}

    if [[ -n "$suggestion" && "$suggestion" != "$BUFFER" ]]; then
        POSTDISPLAY="${suggestion#$BUFFER}"
        region_highlight=("$#BUFFER $(($#BUFFER + $#POSTDISPLAY)) fg=242")
    else
        POSTDISPLAY=""
        region_highlight=()
    fi
}

_my_autosuggest_refresh() {
    _my_autosuggest_strategy
    zle redisplay
}

# --- Tabキー（補完）のフック ---
_my_tab_handler() {
    POSTDISPLAY=""
    region_highlight=()
    zle .expand-or-complete
    _my_autosuggest_refresh
}
zle -N _my_tab_handler
bindkey '^I' _my_tab_handler

# --- Enter（確定）のフック ---
_my_accept_line_handler() {
    POSTDISPLAY=""
    region_highlight=()
    zle .accept-line
}
zle -N _my_accept_line_handler
bindkey '^M' _my_accept_line_handler

# --- 文字入力・削除のフック (★共通化してスマートに) ---
_my_autosuggest_type_handler() {
    # 呼ばれたウィジェット(self-insert等)を動的に実行
    zle .$WIDGET
    _my_autosuggest_refresh
}
zle -N self-insert _my_autosuggest_type_handler
zle -N backward-delete-char _my_autosuggest_type_handler

# --- 右矢印 / Ctrl+F でサジェスト採用 ---
_my_autosuggest_accept() {
    if [[ -n "$POSTDISPLAY" ]]; then
        _MY_AS_IGNORE_ONCE=1
        BUFFER="$BUFFER$POSTDISPLAY"
        POSTDISPLAY=""
        region_highlight=()
        CURSOR=${#BUFFER}
    else
        zle .forward-char
    fi
}
zle -N _my_autosuggest_accept
bindkey '^[[C' _my_autosuggest_accept
bindkey '^F' _my_autosuggest_accept

# ==========================================
# 8. 開発環境のパス設定
# ==========================================
# dotnet (mise管理)
export DOTNET_ROOT="$HOME/.mise/installs/dotnet/latest"
export PATH="$DOTNET_ROOT:$PATH"

# Android SDK (macOS と Linux でパスが異なる)
if [ "$os_type" = "Darwin" ]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
else
    export ANDROID_HOME="$HOME/Android/sdk"
fi
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# pnpm (macOS と Linux でパスが異なる)
if [ "$os_type" = "Darwin" ]; then
    export PNPM_HOME="$HOME/Library/pnpm"
else
    export PNPM_HOME="$HOME/.local/share/pnpm"
fi
export PATH="$HOME/.pub-cache/bin:$GITHUB_PATH/dotfiles/packages/common/cli/scripts:$PNPM_HOME:$PATH"

# SQLite3 (Homebrew)
if [ -n "$HOMEBREW_PREFIX_PATH" ]; then
    export PATH="$HOMEBREW_PREFIX_PATH/opt/sqlite/bin:$PATH"
fi

# ==========================================
# 9. エイリアス
# ==========================================
alias syncsh=". syncsh"
alias cdrepo=". cdrepo"
alias lscmd="ls ~/scripts"
# alias vi="nvim"
alias ff='myfind | grep -i'
alias f='fvi'

if [ "$os_type" = "Darwin" ]; then
    # macOS用
    alias code="open -a 'Visual Studio Code'"
    alias battery="ioreg -c AppleSmartBattery | grep -i Capacity"
    alias sim='sim_path="$(ls -dr /Applications/Xcode-* | head -n1)" && open "${sim_path}/Contents/Developer/Applications/Simulator.app/"'
    alias ll="ls -lahFG"
else
    # Linux用 (色は --color=auto)
    alias ll="ls -lahF --color=auto"
fi

# watch
watch() {
  local interval=2
  local help_mode=false

  # help message
  usage() {
    cat << EOF
Usage: watch [options] command

Options:
  -n <seconds>  Specify update interval (default: 2)
  -h, --help    Show this help message

Example:
  watch -n 1 ls -la
  watch "tree -L 2"
EOF
  }

  # 1. 引数の解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n)
        if [[ "$2" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
          interval=$2
          shift 2
        else
          echo "watch: -n requires a numeric argument" >&2
          return 1
        fi
        ;;
      -h|--help)
        usage
        return 0
        ;;
      -*)
        # 未知のオプションは無視
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  # 実行コマンドの確認
  if [[ -z "$*" ]]; then
    usage
    return 1
  fi

  # 終了時の処理（カーソル再表示と画面リセット）
  trap "printf '\033[?25h'; echo; return" INT TERM

  # 画面の準備
  clear
  printf "\033[?25l" # カーソルを隠す

  while true; do
    # カーソルを左上(1,1)へ移動
    printf "\033[H"
    
    # ヘッダー情報の表示 (printfで整形)
    local header_time=$(date +%H:%M:%S)
    local header_info="Every ${interval}s: $*"
    printf "%-40s %20s\n" "$header_info" "$header_time"
    echo "------------------------------------------------------------"
    
    # コマンド実行
    eval "$@"
    
    # 残った古い出力を消去
    printf "\033[J"
    
    sleep "$interval"
  done
}

# tree
tree() {
  local depth=10
  local target="."
  local find_args=()
  local ignore_list=()
  local show_all=false
  local dir_only=false

  # ヘルプメッセージの定義
  usage() {
    cat << EOF
Usage: tree [DIRECTORY] [OPTIONS]

A directory tree generator (Shell Function version).

Options:
  -L depth      Max display depth of the directory tree. (Default: 10)
  -d            List directories only.
  -a            All files are listed (including hidden files).
  -I pattern    Ignore files/directories matching the pattern.
                Can be used multiple times. (e.g., -I ".git" -I "node_modules")
  -h, --help    Show this help message.

Example:
  tree -L 2 -a -I ".git"
EOF
  }

  # Argument Analysis
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        return 0
        ;;
      -L)
        [[ "$2" =~ ^[0-9]+$ ]] && { depth="$2"; shift 2; } || shift
        ;;
      -d)
        dir_only=true; shift
        ;;
      -a)
        show_all=true; shift
        ;;
      -I)
        ignore_list+=("$2")
        shift 2
        ;;
      -*)
        shift
        ;;
      *)
        target="$1"; shift
        ;;
    esac
  done

  # Building search criteria
  if [ ${#ignore_list[@]} -eq 0 ]; then
    ignore_list=(".git")
  fi

  local ignore_group=()
  for pattern in "${ignore_list[@]}"; do
    [ ${#ignore_group[@]} -gt 0 ] && ignore_group+=("-o")
    
    # Use -path if the path contains a slash, and -name if it does not
    if [[ "$pattern" == *"/"* ]]; then
      # - Adjust the beginning to ./* for -path
      local p="$pattern"
      [[ "$p" != ./* ]] && p="./${p%/}"
      ignore_group+=("-path" "$p")
    else
      ignore_group+=("-name" "$pattern")
    fi
  done

  # Leave the escaping of parentheses to array expansion
  if [ ${#ignore_group[@]} -gt 0 ]; then
    find_args+=( "(" "${ignore_group[@]}" ")" "-prune" "-o" )
  fi

  if [ "$show_all" = false ]; then
    find_args+=( "-name" ".*" "!" "-name" "." "-prune" "-o" )
  fi

  [ "$dir_only" = true ] && find_args+=( "-type" "d" )
  find_args+=( "-print" )

  # Run
  (
    cd "$target" 2>/dev/null || return 1
    # Sort using `-f` to sort without distinguishing between uppercase and lowercase letters
    find . -maxdepth "$depth" "${find_args[@]}" | sort -f | sed -e "
      1s@^\.@$target@;
      1!s@^\./@@;
      1!s@[^/]*/@  @g;
      1!s@^\(  *\)@\1|-- @;
      1!s@^[^ ]@|-- &@
    "
  )
}
