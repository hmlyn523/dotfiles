# ==========================================
# 1. 基本パス・環境変数の設定
# ==========================================
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

# starship (プロンプト)
if command -v starship > /dev/null; then
    eval "$(starship init zsh)"
fi

# zoxide (ディレクトリジャンプ)
if command -v zoxide > /dev/null; then
    eval "$(zoxide init zsh)"
    alias zi="zi"
fi

# ==========================================
# 4. fzf (インクリメンタルサーチ) の統合設定
# ==========================================
if command -v fzf > /dev/null; then
    export FZF_DEFAULT_COMMAND="rg --files --hidden -g '!.git/*' -g '!node_modules/*'"

    export FZF_DEFAULT_OPTS="--height 100% --layout=reverse --border --multi --preview '
        if [ -d {} ]; then
            eza --icons --tree --level=2 {} | head -200
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
# 5. Yazi (ファイルマネージャー) の設定
# ==========================================
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# ==========================================
# 6. 開発環境のパス設定
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
# 7. エイリアス
# ==========================================
alias syncsh=". syncsh"
alias cdrepo=". cdrepo"
alias lscmd="ls ~/scripts"
alias vi="nvim"

# top: ytop があれば使用、なければ htop
if command -v ytop > /dev/null; then
    alias top="ytop"
elif command -v htop > /dev/null; then
    alias top="htop"
fi

# macOS 専用エイリアス
if [ "$os_type" = "Darwin" ]; then
    alias code="open -a 'Visual Studio Code'"
    alias battery="ioreg -c AppleSmartBattery | grep -i Capacity"
    alias sim='sim_path="$(ls -dr /Applications/Xcode-* | head -n1)" && open "${sim_path}/Contents/Developer/Applications/Simulator.app/"'
fi

# eza (lsの代替)
if command -v eza > /dev/null; then
    alias ls="eza --icons"
    alias ll="eza -lah --icons --git"
    alias lt="eza -lah -T --level=3 --icons --git-ignore"
else
    alias ll="ls -lah"
fi

# ==========================================
# 8. tmux & プラグイン & キーバインド
# ==========================================
# tmux 自動アタッチ (VS Code内では無効)
if [ -z "$TMUX" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
    tmux attach-session || tmux new-session
fi

# zsh-autosuggestions
if [ -n "$HOMEBREW_PREFIX_PATH" ] && \
   [ -f "$HOMEBREW_PREFIX_PATH/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    # macOS (Homebrew)
    source "$HOMEBREW_PREFIX_PATH/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [ -f "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    # Fedora / Ubuntu (dnf / apt)
    source "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [ -f "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    # Arch Linux (pacman)
    source "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

bindkey '^e' autosuggest-accept
