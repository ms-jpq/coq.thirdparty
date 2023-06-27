local init = {
  "halt",
  "logout",
  "poweroff",
  "reboot",
  "restart",
  "shutdown",
  "systemd"
}

local exec = {
  ".",
  "nohup",
  "source",
  "su",
  "sudo"
}

local sys = {
  "chpasswd",
  "chroot",
  "exportfs",
  "groupadd",
  "groupdel",
  "groupmod",
  "kill",
  "killall",
  "mount",
  "pkill",
  "useradd",
  "userdel",
  "usermod"
}

local fs = {
  "chattr",
  "chgrp",
  "chmod",
  "chown",
  "cp",
  "dd",
  "fsck",
  "install",
  "ln",
  "mkdir",
  "mknod",
  "mktemp",
  "mmv",
  "mv",
  "rename",
  "rm",
  "rmdir",
  "rsync",
  "scp",
  "setfacl",
  "sgdisk",
  "touch",
  "wipefs"
}

local mkfs = {
  "mkfs.bfs",
  "mkfs.btrfs",
  "mkfs.cramfs",
  "mkfs.ext2",
  "mkfs.ext3",
  "mkfs.ext4",
  "mkfs.fat",
  "mkfs.minix",
  "mkfs.msdos",
  "mkfs.ntfs",
  "mkfs.vfat",
  "mkfs.xfs",
  "mkfs"
}

local misc = {
  "curl",
  "emacs",
  "htop",
  "lsof",
  "man",
  "nano",
  "nvim",
  "open",
  "screen",
  "sl",
  "sleep",
  "start",
  "tee",
  "tmux",
  "top",
  "vi",
  "vim",
  "wget",
  "xdg-open",
  "yes"
}

return vim.tbl_flatten {init, exec, sys, fs, mkfs, misc}
