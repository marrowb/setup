#!/usr/bin/env bash

set -e

skip_system_packages="${1}"

os_type="$(uname -s)"

apt_packages="curl git iproute2 python3-pip ripgrep tmux vim-gtk wl-clipboard vlc flameshot gnome-tweaks build-essential pkg-config autoconf bison clang rustc libssl-dev libreadline-dev zlib1g-dev libyaml-dev libreadline-dev libncurses5-dev libffi-dev libgdbm-dev libjemalloc2 libvips imagemagick libmagickwand-dev mupdf mupdf-tools gir1.2-gda-5.0 gir1.2-gsound-1.0 gir1.2-gtop-2.0 gir1.2-clutter-1.0 redis-tools sqlite3 libsqlite3-0 libpq-dev postgresql-common software-properties-common apt-transport-https gnome-shell-extension-manager pipx tmuxp"

pip_packages="llm ipython pandas numpy scikit-learn datasette matplotlib click gnome-extensions-cli"

apt_packages_optional="gnupg htop inotify-tools jq pass pwgen rsync shellcheck unzip"

brew_packages="diffutils git python ripgrep tmux vim"
brew_packages_optional="gnupg htop jq pass pwgen rsync shellcheck"


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

function setup_gnome_and_apps() {
    printf "\n\Installing additional apps...\n"
    
    # Array to store failed installations
    failed_scripts=()

    # First run system scripts as they may be prerequisites
    for script in "./system"/*.sh; do
        if [ -f "$script" ]; then
            printf "\nRunning %s...\n" "${script}"
            if ! bash "$script"; then
                failed_scripts+=("$script")
                printf "\nWarning: %s failed to execute properly\n" "${script}"
            fi
        fi
    done

    # Then run app installation scripts
    for script in "./apps"/*.sh; do
        if [ -f "$script" ]; then
            printf "\nRunning %s...\n" "${script}"
            if ! bash "$script"; then
                failed_scripts+=("$script")
                printf "\nWarning: %s failed to execute properly\n" "${script}"
            fi
        fi
    done

    # Report failed installations if any
    if [ ${#failed_scripts[@]} -ne 0 ]; then
        printf "\n\nThe following scripts failed to execute properly:\n"
        printf '%s\n' "${failed_scripts[@]}"
        printf "\nPlease check the above scripts and try running them manually.\n"
    else
        printf "\n\nAll installation scripts completed successfully!\n"
    fi
}

function run_nvm_install()  {
    printf "\n\Installing nvm...\n"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    
    # Load nvm immediately for use in this script
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    
    # Install latest LTS version of Node
    nvm install --lts
    nvm use --lts
    
    # Verify installations
    printf "\nNode version: "
    node --version
    printf "NPM version: "
    npm --version
}

function run_pipx_install() {
    printf "\n\Installing python packages...\n"
    for pkg in ${pip_packages}; do
        {
            pipx install "$pkg" --system-site-packages
        } || {
            pip install "$pkg"
        }
    done
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
# Create initial directories and Setup Dotfiles
###############################################################################

printf "\n\nCreating directory structure...\n"

# Create necessary directories
mkdir -p "${HOME}/.config" \
    "${HOME}/.local/bin" \
    "${HOME}/.local/share" \
    "${HOME}/.local/state" \
    "${HOME}/.vim/spell"

printf "\n\nSetting up dotfiles as bare repository...\n"

# Prompt user for dotfiles setup
while true; do
    read -rp "Would you like to setup your dotfiles? (y/n) " yn
    case "${yn}" in
        [Yy]*)
            # Clone bare repository
            git clone --bare https://github.com/marrowb/dotfiles "$HOME"/.cfg

            # Define config function for managing dotfiles
            function config {
               /usr/bin/git --git-dir="$HOME"/.cfg/ --work-tree="$HOME" "$@"
            }

            # Create backup directory
            mkdir -p "$HOME/.config-backup"

            # Initial checkout attempt
            if config checkout; then
                echo "Checked out config."
            else
                echo "Backing up pre-existing dot files."
                config checkout 2>&1 | grep -E "\s+\." | awk {'print $1'} | xargs -I{} mv "$HOME/{}" "$HOME/.config-backup/{}"
            fi

            # Second checkout attempt after potential backups
            config checkout

            # Hide untracked files in dotfiles status
            config config status.showUntrackedFiles no
            
            echo "Dotfiles setup complete!"
            break;;
        [Nn]*)
            echo "Skipping dotfiles setup"
            break;;
        *) echo "Please answer y or n";;
    esac
done

###############################################################################
# Install Node Version Manager
###############################################################################
cat << EOF

-------------------------------------------------------------------------
Would you like to install the Node Version Manager, NodeJs, and Nvm?
-------------------------------------------------------------------------
EOF

while true; do
    read -rp "Run nvm installation scripts? (y/n) " yn
    case "${yn}" in
        [Yy]*)
            run_nvm_install
            break;;
        [Nn]*)
            echo "Not installing nvm"
            break;;
        *) echo "Please answer y or n";;
    esac
done

###############################################################################
# Install Pip Packages
###############################################################################
cat << EOF

-------------------------------------------------------------------------
Would you like to install the pip packages?
-------------------------------------------------------------------------
EOF

while true; do
    read -rp "Run pip install script? (y/n) " yn
    case "${yn}" in
        [Yy]*)
            run_pipx_install
            break;;
        [Nn]*)
            echo "Python packages"
            break;;
        *) echo "Please answer y or n";;
    esac
done

###############################################################################
# Setup Gnome and Install Applications
###############################################################################
cat << EOF

-------------------------------------------------------------------------
Additional installation scripts in apps/ and system/ directories are
available.
These will install various applications and configure system settings.

Would you like to run these additional installation scripts?
EOF

while true; do
    read -rp "Run additional installation scripts? (y/n) " yn
    case "${yn}" in
        [Yy]*)
            setup_gnome_and_apps
            break;;
        [Nn]*)
            echo "Skipping additional installation scripts"
            break;;
        *) echo "Please answer y or n";;
    esac
done


printf "\n\nInstalling tmux plugin manager...\n"
rm -rf "${HOME}/.tmux/plugins/tpm"
git clone --depth 1 https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"

printf "\n\nInstalling tmux plugins...\n"

export TMUX_PLUGIN_MANAGER_PATH="${HOME}/.tmux/plugins"
mkdir -p "${TMUX_PLUGIN_MANAGER_PATH}"
tmux source "${HOME}/.tmux.conf"
"${HOME}/.tmux/plugins/tpm/bin/install_plugins"

###############################################################################
# Install fzf (fuzzy finder on the terminal and used by a Vim plugin)
###############################################################################

rm -rf "${HOME}/.fzf"
git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf" \
  && yes | "${HOME}/.fzf/install" 

###############################################################################
# Install Vim-Plug and plugins
###############################################################################

printf "\n\nInstalling Vim-Plug...\n"
curl -fLo "${HOME}/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

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
