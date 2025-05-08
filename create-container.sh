#!/bin/bash

# Create a directory for the container
CONTAINER_ROOT="/better-root"

# Check if the container filesystem already exists
if [ ! -d "$CONTAINER_ROOT" ]; then
    echo "Creating container filesystem..."
    sudo apt-get update -y
    sudo apt-get install debootstrap -y
    sudo debootstrap --variant=minbase jammy "$CONTAINER_ROOT"
fi

# Create cgroups
echo "Setting up cgroups..."
sudo mkdir -p /sys/fs/cgroup/memory/mycontainer
sudo mkdir -p /sys/fs/cgroup/cpu/mycontainer

# Set resource limits
echo "Setting resource limits..."
echo 536870912 | sudo tee /sys/fs/cgroup/memory/mycontainer/memory.limit_in_bytes  # 512MB
echo 30000 | sudo tee /sys/fs/cgroup/cpu/mycontainer/cpu.cfs_quota_us  # 30% of one core
echo 100000 | sudo tee /sys/fs/cgroup/cpu/mycontainer/cpu.cfs_period_us

# Start the container
echo "Starting container..."
sudo unshare --mount --uts --ipc --net --pid --fork --user --map-root-user chroot "$CONTAINER_ROOT" /bin/bash -c "mount -t proc none /proc && mount -t sysfs none /sys && mount -t tmpfs none /tmp && /bin/bash" &

# Get the PID of the container process
CONTAINER_PID=$!

# Add the process to the cgroups
echo $CONTAINER_PID | sudo tee /sys/fs/cgroup/memory/mycontainer/cgroup.procs
echo $CONTAINER_PID | sudo tee /sys/fs/cgroup/cpu/mycontainer/cgroup.procs

echo "Container started with PID $CONTAINER_PID"
echo "To enter the container, run: sudo nsenter --target $CONTAINER_PID --mount --uts --ipc --net --pid /bin/bash"
