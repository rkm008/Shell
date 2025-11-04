#!/data/data/com.termux/files/usr/bin/bash

echo "[*] Checking for stuck apt processes..."
APT_PID=$(lsof /data/data/com.termux/files/usr/var/lib/dpkg/lock-frontend 2>/dev/null | awk 'NR==2 {print $2}')

if [ -n "$APT_PID" ]; then
    echo "[!] Killing stuck apt process (PID: $APT_PID)..."
    kill -9 "$APT_PID" && sleep 1
fi

echo "[*] Removing lock files..."
rm -rf /data/data/com.termux/files/usr/var/lib/dpkg/lock-frontend
rm -rf /data/data/com.termux/files/usr/var/lib/dpkg/lock

echo "[*] Fixing dpkg (if needed)..."
dpkg --configure -a

echo "[*] Updating Termux..."
pkg update -y && pkg upgrade -y

echo "[*] Installing required packages..."
pkg install -y zsh git fastfetch curl
pkg install ncurses-utils
pkg install iproute2
pkg install ruby
gem install lolcat

echo "[*] Cloning zsh plugins..."
mkdir -p ~/.zsh
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting

echo "[*] Creating .zshrc..."
cat > ~/.zshrc << 'EOF'
#Show system info
echo
echo
echo


echo -e "
    ____  ___   _____ __  ____________     __ __ __  _____    _   __
   / __ \/   | / ___// / / / ____/ __ \   / //_// / / /   |  / | / /
  / /_/ / /| | \__ \/ /_/ / __/ / / / /  / ,<  / /_/ / /| | /  |/ /
 / _, _/ ___ |___/ / __  / /___/ /_/ /  / /| |/ __  / ___ |/ /|  /
/_/ |_/_/  |_/____/_/ /_/_____/_____/  /_/ |_/_/ /_/_/  |_/_/ |_/
" | lolcat


echo

#!/bin/bash

# Function to center text
center_text() {
  local termwidth=$(tput cols)
  local text="$1"
  local textlen=$(echo -e "$text" | wc -c)
  local padding=$(( (termwidth - textlen) / 2 ))
  printf "%${padding}s%s%${padding}s\n" "" "$text" ""
}

# Uptime
uptime_info=$(uptime -p | sed 's/up //')
line1="Uptime: $uptime_info"

# Local IP: check rmnet_data2 first, then rmnet_data1
local_ip=""
local_interface=""

local_ip=$(ip -4 addr show rmnet_data2 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -n "$local_ip" ]; then
  local_interface="rmnet_data2"
else
  local_ip=$(ip -4 addr show rmnet_data1 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
  if [ -n "$local_ip" ]; then
    local_interface="rmnet_data1"
  fi
fi

[ -z "$local_ip" ] && local_ip="Not found"
line2="Local IP (${local_interface}): $local_ip"

# Public IP: prioritize wlan1, then wlan0, then rmnet_data3
public_ip=""
public_label=""

# Check for wlan1
public_ip=$(ip -4 addr show wlan1 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -n "$public_ip" ]; then
  public_label="wlan1"
else
  # Check for wlan0 if wlan1 not found
  public_ip=$(ip -4 addr show wlan0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
  if [ -n "$public_ip" ]; then
    public_label="wlan0"
  else
    # Check for rmnet_data3 if neither wlan interface is found
    public_ip=$(ip -4 addr show rmnet_data3 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    if [ -n "$public_ip" ]; then
      public_label="rmnet_data3"
    fi
  fi
fi

[ -z "$public_ip" ] && { public_ip="No Internet"; public_label=""; }

if [ -n "$public_label" ]; then
  line3="Public IP (${public_label}): $public_ip"
else
  line3="Public IP: $public_ip"
fi

# Print centered lines with lolcat
echo ""
center_text "$line1" | lolcat
echo
center_text "$line2" | lolcat
echo
center_text "$line3" | lolcat
echo ""



echo

line="Welcome to R.K.M Terminal!"
width=$(tput cols)
padding=$(( (width - ${#line}) / 2 ))
printf "%*s%s\n" "$padding" "" "$line" | lolcat

echo
echo
echo
echo
setopt autocd
# Load zsh plugins
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Enable up/down arrow key history navigation
autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# Clean and simple prompt with custom name
PROMPT=$'%F{green}→R.K.M%f:%F{blue}%~%f$ '

# Aliases
alias pk="pkg update && pkg upgrade"
alias cls="clear"
alias p="python"
alias sd="cd /sdcard"
alias pj="cd /sdcard/project"
alias ap="apt update && apt upgrade -y"
alias mm="p yt.py"
alias ca="pkg install ca-certificates openssl -y"

EOF

echo "[*] Disabling Termux default message..."
touch ~/.hushlogin   # <--- This line was added here

echo "[*] Setting zsh as the default shell..."
if ! grep -q "zsh" ~/.bashrc; then
    echo 'exec zsh -l' >> ~/.bashrc
    echo 'PS1="→\[\e[32m\]R.K.M\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ " ' >> ~/.bashrc
fi

echo "[✔] Installation complete! Restart Termux or run 'zsh' to use your new custom shell."
