local init = {
  "halt",
  "poweroff",
  "reboot",
  "shutdown"
}

local sudo = {
  "su",
  "sudo"
}

local fs = {
  "dd",
  "cp",
  "mv",
  "rm",
  "rsync",
  "scp"
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

return vim.tbl_flatten {init, sudo, fs, mkfs}
