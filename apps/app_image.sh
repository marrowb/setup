sudo add-apt-repository ppa:appimagelauncher-team/stable
sudo apt install appimagelauncher

mkdir /tmp/app-images
sudo mkdir "${HOME}/Applications"
cd /tmp/app-images

curl -s https://api.github.com/repos/neovim/neovim/releases/latest | jq -r '.assets[] | select(.name | endswith(".appimage")) | .browser_download_url' | xargs curl -O
sudo mv ./nvim.appimage /usr/local/bin/nvim

curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | jq -r '.assets[] | select(.name | endswith(".AppImage") and (contains("arm") | not)) | .browser_download_url' | xargs curl -O
sudo mv ./* "${HOME}"/Applications
cd -
