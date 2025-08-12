#!/usr/bin/env bash
set -euo pipefail

PROFILE_NAME="Elite ghost"
TARGET_USER="${SUDO_USER:-kali}"
USER_HOME=$(eval echo "~$TARGET_USER")

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

echo "[+] Updating system..."
apt update && apt -y full-upgrade

echo "[+] Installing essentials..."
apt install -y zsh tmux git curl wget neovim htop unzip tree jq bat ripgrep fzf xclip \
               python3 python3-pip python3-venv pipx golang build-essential

sudo -u "$TARGET_USER" bash -lc 'pipx ensurepath'

echo "[+] Installing Kali metas..."
apt install -y kali-linux-default kali-tools-top10 kali-tools-web kali-tools-wireless \
               wordlists seclists crunch nmap wireshark burpsuite sqlmap john hydra gobuster \
               feroxbuster smbclient netcat-openbsd nikto hashcat aircrack-ng hcxtools reaver \
               bully mdk4 kismet bettercap bluez bluez-hcidump crackle rfkill rtl-sdr gqrx-sdr \
               kalibrate-rtl rfcat python3-impacket impacket-scripts radare2 apktool binwalk ghidra

echo "[+] Installing ProjectDiscovery + extras..."
sudo -u "$TARGET_USER" bash -lc '
export PATH=$HOME/go/bin:$PATH
pipx install wafw00f
pipx install arjun
pipx install mitmproxy
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/tomnomnom/assetfinder@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/tomnomnom/httprobe@latest
nuclei -update
'

echo "[+] Configuring zsh..."
cat > "$USER_HOME/.zshrc" <<'ZRC'
export EDITOR=nvim
export HISTSIZE=20000
export SAVEHIST=20000
setopt HIST_IGNORE_ALL_DUPS HIST_VERIFY SHARE_HISTORY
autoload -Uz compinit && compinit
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
parse_git_branch(){ git rev-parse --is-inside-work-tree &>/dev/null || return; b=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); [[ -n "$b" ]] && echo " ($b)"; }
PROMPT='%F{cyan}%n@%m%f:%F{green}%~%f%F{yellow}$(parse_git_branch)%f %# '
alias ll='ls -alF'; alias la='ls -A'; alias l='ls -CF'; alias v='nvim'; alias cls='clear'
alias web-recon='subfinder -silent -dL domains.txt | httpx -silent | tee live.txt'
alias app-scan='nuclei -l live.txt -severity high,critical -rl 150 -c 50'
alias wlan-m='sudo airmon-ng start wlan0 && sudo airodump-ng wlan0mon'
ZRC

chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME"
chsh -s /usr/bin/zsh "$TARGET_USER"

echo "[+] All done! Reboot and enjoy your fully loaded ethical hacking machine."
