ubuntu_release="$(lsb_release -c | cut -f2)"
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/"${ubuntu_release}".gpg | sudo apt-key add -
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/"${ubuntu_release}".list | sudo tee /etc/apt/sources.list.d/tailscale.list

sudo apt-get update
sudo apt-get install tailscale

sudo tailscale up

