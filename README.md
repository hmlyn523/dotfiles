# dotfiles

dotfiles managed with
- [GNU stow](https://www.gnu.org/software/stow/)
- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)
- [rtx](https://github.com/jdx/rtx)

## Introduction

This repository is a forked and modified version of [@JunichiSugiura](https://github.com/JunichiSugiura/dotfiles) repository. Thank you very much.

## Installation

1. Sign in to App store manually (Temporary solution. See more: <https://github.com/mas-cli/mas/issues/164>)

2. Run install

```sh
curl -o - https://raw.githubusercontent.com/hmlyn523/dotfiles/main/packages/cli/scripts/dotfiles | sh
```

Add the -g option if you want to skip the GitHub configuration.

```sh
curl -o - https://raw.githubusercontent.com/hmlyn523/dotfiles/main/packages/cli/scripts/dotfiles | sh -s -- -g
```

3. [macOS] Start Yabai and skhd

```sh
brew services start yabai
brew services start skhd
# or
brew services start --all
```
Then allow accessibility permissions on `Security & Privacy` inside `System Preferences.app`

4. Setting Alacritty

Reconfigure the location of tmux depending on the execution environment.
```
$HOME/.tmux.conf
$HOME/.config/alacritty/alacritty.yaml
```

5. [macOS] Change OS language to English.

Because yabai's bsp excluded window cannot be set in Japanese settings.

## Manual operations
haven't figure out ways to automate
- add google-japanese-ime to input sources
- `^space` to switch input source
- show battery percentage
- install
  - [Karabiner Elements](https://karabiner-elements.pqrs.org/)
- add [Vimari](https://apps.apple.com/us/app/vimari/id1480933944?mt=12) Safari extension

## Installed Apps

Check [Brewfile](./Brewfile) for the latest bundle.

## Tutorial

If you like to learn how to create dotfiles, check out [@JunichiSugiura](https://github.com/JunichiSugiura/dotfiles) [tutorial ](https://github.com/JunichiSugiura/tutorials/tree/master/dotfiles).

## Note

If the macOS language is not English, yabai's rule does not apply.
If Super+Ctrl+Up(Down) does not change the backlight brightness, changing the PREFIX in dotfiles/packages/linux/cli/scripts/brightness.sh may change it.
