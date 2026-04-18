export PATH="$HOME/scripts:$PATH"
export GITHUB_PATH="$HOME/projects/github.com"

os_type="$(uname)"
arch_name="$(uname -m)"
# 注: rsyncやscpなどで非対話シェルとして呼ばれた際にエラーになるのを防ぐため、
# 対話シェルでのみエコーするように変更
if [[ $- == *i* ]]; then
    echo ">>> ${os_type}/${arch_name} <<<"
fi

# ==========================================
# Homebrew のセットアップと高速化
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
# tmux 自動アタッチ (VS Code内では起動しないよう配慮)
# ==========================================
if [ -z "$TMUX" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
    tmux attach-session || tmux new-session
fi

# ==========================================
# ツール類の初期化 (mise, starship, zoxide)
# ==========================================
if command -v mise > /dev/null; then
    eval "$(mise activate zsh)"
    export MISE_DATA_DIR="$HOME/.mise"
    export MISE_CACHE_DIR="$MISE_DATA_DIR/cache"
fi

if command -v starship > /dev/null; then
    eval "$(starship init zsh)"
fi

if command -v zoxide > /dev/null; then
    eval "$(zoxide init zsh)"
    # zoxide init が自動で 'z' を定義するため alias cd="z" は削除
fi

# ==========================================
# 環境変数
# ==========================================
export GPG_TTY=$(tty)
export XDG_CONFIG_HOME="$HOME/.config"

# dotnet
export DOTNET_ROOT="$HOME/.mise/installs/dotnet/latest"
export PATH="$DOTNET_ROOT:$PATH"

# Android
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# pipx / pub-cache / github scripts
export PATH="$HOME/.local/bin:$HOME/.pub-cache/bin:$GITHUB_PATH/dotfiles/packages/common/cli/scripts:$PATH"

# pnpm ($HOMEを使用するように修正)
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

# SQLite3 (DYLD_LIBRARY_PATH は危険なため削除し、PATHのみ追加)
if [ -n "$HOMEBREW_PREFIX_PATH" ]; then
    export PATH="$HOMEBREW_PREFIX_PATH/opt/sqlite/bin:$PATH"
fi

# Ruby (バージョンに依存しないGemパスも追加推奨)
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
    # mise を使っている場合は mise に管理させるのがベストです
fi

# fzf
export FZF_DEFAULT_COMMAND="rg --files --hidden -l -g '!.git/*' -g '!node_modules/*'"
export FZF_DEFAULT_OPTS="-m --height 100% --border --preview 'cat {}'"

# ==========================================
# エイリアス
# ==========================================
alias code="open -a 'Visual Studio Code'"
alias syncsh=". syncsh"
alias cdrepo=". cdrepo"
alias lscmd="ls ~/scripts"

# sim エイリアスの修正 (動的に取得)
alias sim='sim_path="$(ls -dr /Applications/Xcode-* | head -n1)" && open "${sim_path}/Contents/Developer/Applications/Simulator.app/"'

alias keycodes="cat /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/Events.h"
alias battery="ioreg -c AppleSmartBattery | grep -i Capacity"

if command -v eza > /dev/null; then
    alias ls="eza"
    alias ll="eza -lah --git"
    alias lt="eza -lah -T --level=3 --git-ignore"
else
    alias ll="ls -lah"
fi

alias top="ytop"
alias vi="nvim"

# ==========================================
# プラグイン & キーバインド
# ==========================================
# brew コマンドを使わず、変数化して高速読み込み
if [ -f "$HOMEBREW_PREFIX_PATH/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$HOMEBREW_PREFIX_PATH/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    bindkey '^e' autosuggest-accept
fi

# ==========================================
# LF Icons
# ==========================================
export LF_ICONS="\
tw=:\
st=:\
ow=:\
dt=:\
di=:\
fi=:\
ln=:\
or=:\
ex=:\
*.c=:\
*.cc=:\
*.clj=:\
*.coffee=:\
*.cpp=:\
*.css=:\
*.d=:\
*.dart=:\
*.erl=:\
*.exs=:\
*.fs=:\
*.go=:\
*.h=:\
*.hh=:\
*.hpp=:\
*.hs=:\
*.html=:\
*.java=:\
*.jl=:\
*.js=:\
*.json=:\
*.lua=:\
*.md=:\
*.php=:\
*.pl=:\
*.pro=:\
*.py=:\
*.rb=:\
*.rs=:\
*.scala=:\
*.ts=:\
*.vim=:\
*.cmd=:\
*.ps1=:\
*.sh=:\
*.bash=:\
*.zsh=:\
*.fish=:\
*.tar=:\
*.tgz=:\
*.arc=:\
*.arj=:\
*.taz=:\
*.lha=:\
*.lz4=:\
*.lzh=:\
*.lzma=:\
*.tlz=:\
*.txz=:\
*.tzo=:\
*.t7z=:\
*.zip=:\
*.z=:\
*.dz=:\
*.gz=:\
*.lrz=:\
*.lz=:\
*.lzo=:\
*.xz=:\
*.zst=:\
*.tzst=:\
*.bz2=:\
*.bz=:\
*.tbz=:\
*.tbz2=:\
*.tz=:\
*.deb=:\
*.rpm=:\
*.jar=:\
*.war=:\
*.ear=:\
*.sar=:\
*.rar=:\
*.alz=:\
*.ace=:\
*.zoo=:\
*.cpio=:\
*.7z=:\
*.rz=:\
*.cab=:\
*.wim=:\
*.swm=:\
*.dwm=:\
*.esd=:\
*.jpg=:\
*.jpeg=:\
*.mjpg=:\
*.mjpeg=:\
*.gif=:\
*.bmp=:\
*.pbm=:\
*.pgm=:\
*.ppm=:\
*.tga=:\
*.xbm=:\
*.xpm=:\
*.tif=:\
*.tiff=:\
*.png=:\
*.svg=:\
*.svgz=:\
*.mng=:\
*.pcx=:\
*.mov=:\
*.mpg=:\
*.mpeg=:\
*.m2v=:\
*.mkv=:\
*.webm=:\
*.ogm=:\
*.mp4=:\
*.m4v=:\
*.mp4v=:\
*.vob=:\
*.qt=:\
*.nuv=:\
*.wmv=:\
*.asf=:\
*.rm=:\
*.rmvb=:\
*.flc=:\
*.avi=:\
*.fli=:\
*.flv=:\
*.gl=:\
*.dl=:\
*.xcf=:\
*.xwd=:\
*.yuv=:\
*.cgm=:\
*.emf=:\
*.ogv=:\
*.ogx=:\
*.aac=:\
*.au=:\
*.flac=:\
*.m4a=:\
*.mid=:\
*.midi=:\
*.mka=:\
*.mp3=:\
*.mpc=:\
*.ogg=:\
*.ra=:\
*.wav=:\
*.oga=:\
*.opus=:\
*.spx=:\
*.xspf=:\
*.pdf=:\
*.nix=:\
"