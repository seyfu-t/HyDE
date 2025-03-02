#!/usr/bin/env bash
#|---/ /+-------------------------------------+---/ /|#
#|--/ /-| Script to apply pre install configs |--/ /-|#
#|-/ /--| Prasanth Rangan                     |-/ /--|#
#|/ /---+-------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

flg_DryRun=${flg_DryRun:-0}

# grub
if pkg_installed grub && [ -f /boot/grub/grub.cfg ]; then
    print_log -sec "bootloader" -stat "detected" "grub..."

    if [ ! -f /etc/default/grub.hyde.bkp ] && [ ! -f /boot/grub/grub.hyde.bkp ]; then
        print_log -g "[bootloader] " -b "configure :: " "grub"
        sudo cp /etc/default/grub /etc/default/grub.hyde.bkp
        sudo cp /boot/grub/grub.cfg /boot/grub/grub.hyde.bkp

        if nvidia_detect; then
            print_log -g "[bootloader] " -b "configure :: " "nvidia detected, adding nvidia_drm.modeset=1 to boot option..."
            gcld=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" "/etc/default/grub" | cut -d'"' -f2 | sed 's/\b nvidia_drm.modeset=.\b//g')
            sudo sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/c\GRUB_CMDLINE_LINUX_DEFAULT=\"${gcld} nvidia_drm.modeset=1\"" /etc/default/grub
        fi

        grubtheme="Retroboot"

        if [ "${grubtheme}" == "None" ]; then
            print_log -g "[bootloader] " -b "skip :: " "grub theme..."
            sudo sed -i "s/^GRUB_THEME=/#GRUB_THEME=/g" /etc/default/grub
        else
            print_log -g "[bootloader] " -b "set :: " "grub theme // ${grubtheme}"
            # shellcheck disable=SC2154
            sudo tar -xzf "${cloneDir}/Source/arcs/Grub_${grubtheme}.tar.gz" -C /usr/share/grub/themes/
            sudo sed -i "/^GRUB_DEFAULT=/c\GRUB_DEFAULT=saved
            /^GRUB_GFXMODE=/c\GRUB_GFXMODE=1280x1024x32,auto
            /^GRUB_THEME=/c\GRUB_THEME=\"/usr/share/grub/themes/${grubtheme}/theme.txt\"
            /^#GRUB_THEME=/c\GRUB_THEME=\"/usr/share/grub/themes/${grubtheme}/theme.txt\"
            /^#GRUB_SAVEDEFAULT=true/c\GRUB_SAVEDEFAULT=true" /etc/default/grub
        fi

        sudo grub-mkconfig -o /boot/grub/grub.cfg
    else
        print_log -y "[bootloader] " -b "exist :: " "grub is already configured..."
    fi
fi

# pacman

if [ -f /etc/pacman.conf ] && [ ! -f /etc/pacman.conf.hyde.bkp ]; then
    print_log -g "[PACMAN] " -b "modify :: " "adding extra spice to pacman..."

    # shellcheck disable=SC2154
    [ "${flg_DryRun}" -eq 1 ] || sudo cp /etc/pacman.conf /etc/pacman.conf.hyde.bkp
    [ "${flg_DryRun}" -eq 1 ] || sudo sed -i "/^#Color/c\Color\nILoveCandy
    /^#VerbosePkgLists/c\VerbosePkgLists
    /^#ParallelDownloads/c\ParallelDownloads = 5" /etc/pacman.conf
    [ "${flg_DryRun}" -eq 1 ] || sudo sed -i '/^#\[multilib\]/,+1 s/^#//' /etc/pacman.conf

    print_log -g "[PACMAN] " -b "update :: " "packages..."
    [ "${flg_DryRun}" -eq 1 ] || sudo pacman -Syyu --noconfirm
    [ "${flg_DryRun}" -eq 1 ] || sudo pacman -Fy
else
    print_log -sec "PACMAN" -stat "skipped" "pacman is already configured..."
fi
