#!/usr/bin/env bash

set -e

skip_system_packages="${1}"

os_type="$(uname -s)"

apt_packages="curl git iproute2 python3-pip ripgrep tmux vim-gtk wl-clipboard vlc flameshot gnome-tweaks build-essential pkg-config autoconf bison clang rustc libssl-dev libreadline-dev zlib1g-dev libyaml-dev libreadline-dev libncurses5-dev libffi-dev libgdbm-dev libjemalloc2 libvips imagemagick libmagickwand-dev mupdf mupdf-tools gir1.2-gda-5.0 gir1.2-gsound-1.0 gir1.2-gtop-2.0 gir1.2-clutter-1.0 redis-tools sqlite3 libsqlite3-0 libpq-dev postgresql-common software-properties-common apt-transport-https"

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
    printf "\n\Installing additoinal apps...\n"

    # First run system scripts as they may be prerequisites
    for script in "./system"/*.sh; do
        if [ -f "$script" ]; then
            printf "\nRunning %s...\n" "${script}"
            bash "$script"
        fi
    done

    # Then run app installation scripts
    for script in "./apps"/*.sh; do
        if [ -f "$script" ]; then
            printf "\nRunning %s...\n" "${script}"
            bash "$script"
        fi
    done
}

function run_npv_install()  {
    printf "\n\Installing npv...\n"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    source "$HOME"/.bashrc 
    nvm install node
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
# Clone Dotfiles
###############################################################################
cat << EOF

-------------------------------------------------------------------------
Would you like to clone Brandon's dotfiles?
-------------------------------------------------------------------------
EOF
while true; do
    read -rp "Clone brandon's dotfiles? (y/n) " yn
    case "${yn}" in
        [Yy]*)
            git clone https://github.com/marrowb/dotfiles
            break;;
        [Nn]*)
            echo "Not installing dotfiles"
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
    read -rp "Run NPV installation scripts? (y/n) " yn
    case "${yn}" in
        [Yy]*)
            run_npv_install
            break;;
        [Nn]*)
            echo "Not installing npv"
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


###############################################################################
# Clone Dotfiles and Setup Bare Repository
###############################################################################
# Taken from: https://www.atlassian.com/git/tutorials/dotfiles
#
# git clone --bare https://github.com/marrowb/dotfiles "$HOME"/.cfg
# function config {
#    /usr/bin/git --git-dir="$HOME"/.cfg/ --work-tree="$HOME" "$@"
# }
# mkdir -p .config-backup
# config checkout
# if [ $? = 0 ]; then
#   echo "Checked out config.";
#   else
#     echo "Backing up pre-existing dot files.";
#     config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
# fi;
# config checkout
# config config status.showUntrackedFiles no

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
