# ==========================================
# 1. 基本パス・環境変数の設定
# ==========================================
export PATH="$HOME/scripts:$PATH"
export GITHUB_PATH="$HOME/projects/github.com"
export XDG_CONFIG_HOME="$HOME/.config"
export GPG_TTY=$(tty)

os_type="$(uname)"
arch_name="$(uname -m)"

# 対話シェルの時だけOS情報を表示
if [[ $- == *i* ]]; then
    echo ">>> ${os_type}/${arch_name} <<<"
fi

# ==========================================
# 2. Homebrew のセットアップと高速化
# ==========================================
HOMEBREW_PREFIX_PATH=""
if [ "${arch_name}" = "x86_64" ] && [ -f "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
    HOMEBREW_PREFIX_PATH="/usr/local"
elif [ "${arch_name}" = "arm64" ] && [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    HOMEBREW_PREFIX_PATH="/opt/homebrew"
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
    alias zi="zi" # fzf連携モードで起動
fi

# ==========================================
# 4. fzf (インクリメンタルサーチ) の統合設定
# ==========================================
if command -v fzf > /dev/null; then
    # 基本コマンド設定 (ripgrepを使用)
    export FZF_DEFAULT_COMMAND="rg --files --hidden -l -g '!.git/*' -g '!node_modules/*'"
    
    # 全体的な表示設定とプレビューの統合 (ezaを使用)
    export FZF_DEFAULT_OPTS="--height 100% --layout=reverse --border --multi --preview '
        if [ -d {} ]; then
            eza --icons --tree --level=2 {} | head -200
        else
            cat {}
        fi'"

    # Homebrew経由のキーバインド (Ctrl+R, Ctrl+T) を読み込む
    if [ -n "$HOMEBREW_PREFIX_PATH" ]; then
        [ -f "$HOMEBREW_PREFIX_PATH/opt/fzf/shell/key-bindings.zsh" ] && source "$HOMEBREW_PREFIX_PATH/opt/fzf/shell/key-bindings.zsh"
        [ -f "$HOMEBREW_PREFIX_PATH/opt/fzf/shell/completion.zsh" ] && source "$HOMEBREW_PREFIX_PATH/opt/fzf/shell/completion.zsh"
    fi
fi

# ==========================================
# 5. Yazi (ファイルマネージャー) の設定
# ==========================================
# 'y' コマンドで起動し、終了時にそのディレクトリへ移動する
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# ==========================================
# 6. 開発環境のパス設定 (dotnet, Android, pnpm, etc.)
# ==========================================
# dotnet
export DOTNET_ROOT="$HOME/.mise/installs/dotnet/latest"
export PATH="$DOTNET_ROOT:$PATH"

# Android
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# Node / Python / Flutter / scripts
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$HOME/.local/bin:$HOME/.pub-cache/bin:$GITHUB_PATH/dotfiles/packages/common/cli/scripts:$PNPM_HOME:$PATH"

# SQLite3 (Homebrew)
if [ -n "$HOMEBREW_PREFIX_PATH" ]; then
    export PATH="$HOMEBREW_PREFIX_PATH/opt/sqlite/bin:$PATH"
fi

# ==========================================
# 7. エイリアス
# ==========================================
alias code="open -a 'Visual Studio Code'"
alias syncsh=". syncsh"
alias cdrepo=". cdrepo"
alias lscmd="ls ~/scripts"
alias vi="nvim"
alias top="ytop"
alias battery="ioreg -c AppleSmartBattery | grep -i Capacity"

# Xcode Simulator (動的パス取得)
alias sim='sim_path="$(ls -dr /Applications/Xcode-* | head -n1)" && open "${sim_path}/Contents/Developer/Applications/Simulator.app/"'

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

# zsh-autosuggestions (爆速読み込み)
if [ -n "$HOMEBREW_PREFIX_PATH" ] && [ -f "$HOMEBREW_PREFIX_PATH/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$HOMEBREW_PREFIX_PATH/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    bindkey '^e' autosuggest-accept
fi