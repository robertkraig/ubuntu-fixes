# Fix: Docker and Containers Running Silently at Boot

## Problem

Docker is enabled at boot by default. Any containers with `restart: always` or
`restart: unless-stopped` policies start automatically, even ones you've forgotten
about (e.g. an old Airflow stack). These draw significant power: Docker daemon +
containerd + container processes can add 3–5W at idle.

Additionally the `docker0` bridge network interface persists even after stopping
the daemon and carries active traffic from orphaned containers.

## Fix

1. Disable Docker autostart (start it manually only when needed)
2. Clear `restart: always` policies from all existing containers
3. Add shell aliases for easy on/off toggling

## Install

```bash
./install.sh
```

This adds `docker-start` and `docker-stop` aliases to your `.zshrc` / `.bashrc`
and disables Docker autostart. Run once with Docker running to also clear all
container restart policies.

## Usage after install

```bash
docker-start   # start Docker + containerd when you need it
docker-stop    # shut everything down
```

## Cleanup orphaned interfaces

If Docker bridge interfaces persist after stopping:
```bash
sudo ip link delete docker0
# For docker-compose networks (br-xxxxxxxxxx):
sudo ip link delete br-XXXXXXXX
```
