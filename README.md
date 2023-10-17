# pass-crypt-mount
A hastily written shell script for dealing with LUKS drives

```
cm - Crypt Mount 0.7.4
Mount LUKS volumes with GNU pass

Usage: .cm-wrapped [OPTIONS]

Options:
  -h/--help                 Prints help and exits
  -m/--mount=BLOCK_DEVICE   Mount and unlock luks partition
  -u/--umount=LABEL         Unmount and lock luks partition
  -l/--list                 List luks partitions and passwords in store

Examples:
  Mount a LUKS volume

    cm -m /dev/sdg1 vacation-photos

  Unmount a LUKS volume

    cm -u vacation-photos

  List LUKS volumes and pass entries

    cm -l
```
