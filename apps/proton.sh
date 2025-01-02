mkdir /tmp/proton
cd /tmp/proton
# Proton VPN
wget https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.6_all.deb
sudo dpkg -i ./protonvpn-stable-release_1.0.6_all.deb && sudo apt update
sudo apt install proton-vpn-gnome-desktop

# Proton Pass
curl -fsSL https://proton.me/download/PassDesktop/linux/x64/ProtonPass.deb
sudo dpkg -i ProtonPass.deb
