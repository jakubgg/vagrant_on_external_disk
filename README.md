# Vagrant on External Disk
Bash script(s) that alters Vagrant &amp; VirtualBox environments to allow boxes on external disks.

## Description
Vagrant on External Disk (aka valter - vagrant alter) is a script that allows to easily change Vagrant and Virtual Box environment settings to be able to switch and use Vagrant from (multiple) external disks (e.g. USB) and/or also have an environment on your local disk.

The script adjusts `VAGRANT_HOME` variable and Virtual Box `machinefolder` to achieve that effect.

WIP
It also can check for registered and nonregistered machines and assist you with adding them to your Virtual Box.

## Install
Download or clone this repository to your local machine.
Inside repository there is `valter.sh` script. Make it executable by running in your terminal window:

```
chmod +x ./valter.sh
```

If you would like `valter.sh` to be available systemwide just by typing `valter`, you can link to it from your `/usr/local/bin/` directory.

```
ln path-to-your-downloaded/valter.sh /usr/local/bin/valter
```

**NOTE:** On vanilla OSX directory `/usr/local/bin/` might not be present. You have to create it on your own.

## Usage
Run `valter.sh` with -h or --help flag to get inline help.



## Troubleshooting

## Changelog
v0.1 - First public version
