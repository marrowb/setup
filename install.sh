#!/usr/bin/env bash

set -e

skip_system_packages="${1}"

os_type="$(uname -s)"

apt_packages="curl git iproute2 python3-pip ripgrep tmux vim-gtk wl-clipboard postgres vlc flameshot gnome-tweak-tool build-essential pkg-config autoconf bison clang rustc libssl-dev libreadline-dev zlib1g-dev libyaml-dev libreadline-dev libncurses5-dev libffi-dev libgdbm-dev libjemalloc2 libvips imagemagick libmagickwand-dev mupdf mupdf-tools gir1.2-gda-5.0 gir1.2-gsound-1.0 gir1.2-gtop-2.0 gir1.2-clutter-1.0 redis-tools sqlite3 libsqlite3-0 libpq-dev postgresql-client postgresql-client-common software-properties-common"

apt_packages_optional="gnupg htop inotify-tools jq pass pwgen rsync shellcheck unzip"

brew_packages="diffutils git python ripgrep tmux vim"
brew_packages_optional="gnupg htop jq pass pwgen rsync shellcheck"


# Plugins that need to be added
# 2. `docker`
# 3. `docker-compose`
#
# 4. `ffmpeg`
#
# 7. `neovim`
#
# 8. `npm`
# 9. `node`
# # Download and install nvm:
# curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
#
# # Download and install Node.js:
# nvm install 23
#
# # Verify the Node.js version:
# node -v # Should print "v22.12.0".
# nvm current # Should print "v22.12.0".
#
# # Verify npm version:
# npm -v # Should print "10.9.0".

#
# uv
# 10. `python3`
# 11. `pip`
#
# 19. `zotero`
#
# 21. `tarsnap`
#
# 22. `pavucontrol`
#
# 23. `pgadmin`
#
# 25. `gpg`
#
# 32. `rust`
#
# 34. `obsidian`
#
# 35. `pandas`
# 36. `scikit-learn`
# 37. `sqlite-utils`
#
# bitwarden cli
# npm install -g @bitwarden/cli
# 
# libreoffice
#
# lazygit
#
# tailscale
#
# App Image Launcher
# sudo add-apt-repository ppa:appimagelauncher-team/stable
# sudo apt update
# sudo apt install appimagelauncher
#
###############################################################################
# Detect OS and distro type
###############################################################################

function no_system_packages() {
cat << EOF
System package installation isn't supported with your OS / distro.

Please install any dependent packages on your own. You can view the list at:

    https://github.com/nickjj/dotfiles/blob/master/install

Then re-run the script and explicitly skip installing system packages:

    bash <(curl -sS https://raw.githubusercontent.com/nickjj/dotfiles/master/install) --skip-system-packages
EOF

exit 1
}

case "${os_type}" in
    Linux*)
        os_type="Linux"

        if [ !  -f "/etc/debian_version" ]; then
           [ -z "${skip_system_packages}" ] && no_system_packages
        fi

        ;;
    Darwin*) os_type="macOS";;
    *)
        os_type="Other"

        [ -z "${skip_system_packages}" ] && no_system_packages

        ;;
esac

###############################################################################
# Install packages using your OS' package manager
###############################################################################

function apt_install_packages {
    # shellcheck disable=SC2086
    sudo apt-get update && sudo apt-get install -y ${apt_packages} ${apt_packages_optional}
}


function brew_install_self {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

function brew_install_packages {
    [ -x "$(command -v brew > /dev/null 2>&1)" ] && brew_install_self

    # Ensure brew's paths are available for this script
    eval "$(/opt/homebrew/bin/brew shellenv)"

    # shellcheck disable=SC2086
    brew install ${brew_packages} ${brew_packages_optional}
}

function display_packages {
    if [ "${os_type}" == "Linux" ]; then
        echo "${apt_packages} ${apt_packages_optional}"
    else
        echo "${brew_packages} ${brew_packages_optional}"
    fi
}

if [ -z "${skip_system_packages}" ]; then
cat << EOF

If you choose yes, all of the system packages below will be installed:

$(display_packages)

If you choose no, the above packages will not be installed and this script
will exit. This gives you a chance to edit the list of packages if you don't
agree with any of the decisions.

The packages listed after zsh are technically optional but are quite useful.
Keep in mind if you don't install pwgen you won't be able to generate random
passwords using a custom alias that's included in these dotfiles.

EOF
    while true; do
        read -rp "Do you want to install the above packages? (y/n) " yn
        case "${yn}" in
            [Yy]*)
                if [ "${os_type}" == "Linux" ]; then
                    apt_install_packages
                else
                    brew_install_packages
                fi

                break;;
            [Nn]*) exit 0;;
            *) echo "Please answer y or n";;
        esac
    done
else
    echo "System package installation was skipped!"
fi

###############################################################################
# Clone dotfiles
###############################################################################

read -rep $'\nWhere do you want to clone these dotfiles to [~/dotfiles]? ' clone_path
clone_path="${clone_path:-"${HOME}/dotfiles"}"

# Ensure path doesn't exist.
while [ -e "${clone_path}" ]; do
    read -rep $'\nPath exists, try again? (y) ' y
    case "${y}" in
        [Yy]*)

            break;;
        *) echo "Please answer y or CTRL+c the script to abort everything";;
    esac
done

echo

# This is used to locally develop the install script.
if [ "${DEBUG}" == "1" ]; then
    cp -R "${PWD}/." "${clone_path}"
else
    git clone https://github.com/nickjj/dotfiles "${clone_path}"
fi

###############################################################################
# Create initial directories
###############################################################################

mkdir -p "${HOME}/.local/bin" "${HOME}/.local/share" \
    "${HOME}/.local/state" "${HOME}/.vim/spell"

###############################################################################
# Personalize git user
###############################################################################

cp "${clone_path}/.gitconfig.user" "${HOME}/.gitconfig.user"

###############################################################################
# Install Plug (Vim plugin manager)
###############################################################################

curl -fLo "${HOME}/.vim/autoload/plug.vim" --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

###############################################################################
# Install tpm (tmux plugin manager)
###############################################################################

rm -rf "${HOME}/.tmux/plugins/tpm"
git clone --depth 1 https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"

###############################################################################
# Install fzf (fuzzy finder on the terminal and used by a Vim plugin)
###############################################################################

rm -rf "${HOME}/.local/share/fzf"
git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.local/share/fzf" \
  && yes | "${HOME}/.local/share/fzf/install" --bin --no-update-rc

###############################################################################
# Carefully create symlinks
###############################################################################

cat << EOF

-------------------------------------------------------------------------------

ln -fs "${clone_path}/.gitconfig" "${HOME}/.gitconfig"
ln -fs "${clone_path}/.vimrc" "${HOME}/.vimrc"
ln -fs "${clone_path}/.vim/spell/en.utf-8.add" "${HOME}/.vim/spell/en.utf-8.add"
ln -fs "${clone_path}/.tmux.conf" "${HOME}/.tmux.conf"
ln -fs "${clone_path}/.local/bin/"* "${HOME}/.local/bin/"

# And if you happen to be using WSL:
sudo ln -fs "${clone_path}/etc/wsl.conf" /etc/wsl.conf

-------------------------------------------------------------------------------

A potentially dangerous action is about to happen. The above files are going to
get forcefully symlinked.

What does that mean?

Any config files you have on the right hand side of the paths are going to get
overwritten with the files that come with my dotfiles (left side).

If you care about your original config files now would be the time to back
them up. They will ALL be overwritten if you say yes to the prompt below.
EOF

while true; do
  read -rep $'\nReady to continue and apply the symlinks? (y) ' y
  case "${y}" in
      [Yy]*)

          break;;
      *) echo "Please answer y or CTRL+c the script to abort everything";;
  esac
done

ln -fs "ln -fs "${clone_path}/.gitconfig" "${HOME}/.gitconfig" \
    && ln -fs "${clone_path}/.vimrc" "${HOME}/.vimrc" \
    && ln -fs "${clone_path}/.vim/spell/en.utf-8.add" "${HOME}/.vim/spell/en.utf-8.add" \
    && ln -fs "${clone_path}/.tmux.conf" "${HOME}/.tmux.conf" \
    && ln -fs "${clone_path}/.local/bin/"* "${HOME}/.local/bin/"

if grep -qE "(Microsoft|microsoft|WSL)" /proc/version &>/dev/null; then
    sudo ln -fs "${clone_path}/etc/wsl.conf" /etc/wsl.conf
fi

###############################################################################

###############################################################################
# Install tmux plugins
###############################################################################

printf "\n\nInstalling tmux plugins...\n"

export TMUX_PLUGIN_MANAGER_PATH="${HOME}/.tmux/plugins"
"${HOME}/.tmux/plugins/tpm/bin/install_plugins"

###############################################################################
# Install Vim plugins
###############################################################################

printf "\n\nInstalling Vim plugins...\n"

vim -E +PlugInstall +qall || true

###############################################################################
# Done!
###############################################################################

cat << EOF
Everything was installed successfully!

Check out the README file on GitHub to do 1 quick thing manually:

https://github.com/nickjj/dotfiles#did-you-install-everything-successfully

You can safely close this terminal.

The next time you open your terminal zsh will be ready to go!
EOF

exit 0
