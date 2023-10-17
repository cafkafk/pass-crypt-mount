#!/usr/bin/env fish
#
# A hastily written shell script for dealing with LUKS drives
# Copyright (C) 2023  Christina E. Sørensen
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# TODO: create uuid validator function
# TODO: cleanup

set --local cm_version "0.7.4"

# get the program name from the file name
set --local pname "$(basename (status -f))"

set --local options h/help 'm/mount=' 'u/unmount=' l/list

argparse $options -- $argv

function luks_open -a block_device uuid label
    # TODO: validate uuid

    # test if $block_device is actually a block device
    if builtin test -b $block_device
        echo -e "$(pass show disk/luks/uuid/$uuid)\n" | sudo cryptsetup open $block_device $label
        return 0
    else
        return 1
    end
end

function luks_close -a label
    # TODO: validate uuid

    # test if $block_device is actually a block device
    if builtin test -b $block_device
        sudo cryptsetup close /dev/mapper/$label
        return 0
    else
        return 1
    end
end

function get_uuid -a block_device
    # test if $block_device is actually a block device
    if builtin test -b $block_device
        # find and set uuid of block device
        echo $(sudo blkid | rg $block_device | rg '[0-9a-fA-F]{8}\\b-[0-9a-fA-F]{4}\\b-[0-9a-fA-F]{4}\\b-[0-9a-fA-F]{4}\\b-[0-9a-fA-F]{12}' -o)
        return 0
    else
        return 1
    end
end

function udisksctl_unmount -a label
    udisksctl unmount -b "/dev/mapper/$label"
    return $status
end

function udisksctl_mount -a label
    udisksctl mount -b "/dev/mapper/$label"
    return $status
end

if set --query _flag_help
    printf "cm - Crypt Mount $cm_version\n"
    printf "Mount LUKS volumes with GNU pass\n\n"
    printf "Usage: $pname [OPTIONS]\n\n"
    printf "Options:\n"
    printf "  -h/--help                 Prints help and exits\n"
    printf "  -m/--mount=BLOCK_DEVICE   Mount and unlock luks partition\n"
    printf "  -u/--umount=LABEL         Unmount and lock luks partition\n"
    printf "  -l/--list                 List luks partitions and passwords in store\n\n"
    printf "Examples:\n"
    printf "  Mount a LUKS volume\n\n"
    printf "    cm -m /dev/sdg1 vacation-photos\n\n"
    printf "  Unmount a LUKS volume\n\n"
    printf "    cm -u vacation-photos\n\n"
    printf "  List LUKS volumes and pass entries\n\n"
    printf "    cm -l\n\n"
    return 0
end

if set --query _flag_mount
    set uuid $(get_uuid $_flag_mount)
    if builtin test $status -eq 0
        printf "[*] got uuid of $_flag_mount: $uuid\n"
    else
        echo "Usage: $pname -m <block-device>"
        return 1
    end

    set dec $(luks_open $_flag_mount $uuid $argv[1])
    if builtin test $status -eq 0
        #echo $dec
        #echo "successfully decrypted"
        printf "[*] successfully opened luks volume $_flag_mount\n"
    else
        echo "Usage: $pname -m <block-device>"
        return 1
    end

    set mount_message $(udisksctl_mount $argv[1])
    if builtin test $status -eq 0
        printf "[*] "
        echo $mount_message
    else
        printf "[-] "
        echo $mount_message
        echo "Usage: $pname -m <block-device>"
        return 1
    end

    return 0
end

if set --query _flag_unmount
    set mount_message $(udisksctl_unmount $_flag_unmount)
    if builtin test $status -eq 0
        printf "[*] "
        echo $mount_message
    else
        printf "[-] "
        echo $mount_message
        return 1
    end

    set dec $(luks_close $_flag_unmount)
    if builtin test $status -eq 0
        printf "[*] "
        echo "successfully closed luks volume"
    else
        echo "Usage: $pname -m <block-device>"
        return 1
    end


    return 0
end

if set --query _flag_list
    echo -e "### Pass ###"
    pass show disk/luks/uuid

    echo -e "\n### Disk ###"
    # BUG: output is broken if you have multiple luks partitions on one disk
    lsblk --output NAME,FSTYPE,UUID,MOUNTPOINT | rg --color=never -B 1 crypto_LUKS
    return 0
end
