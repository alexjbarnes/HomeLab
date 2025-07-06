# Docker Volume Users & Groups

## The Problem
- Docker volumes created as `root:root` by default
- Non-root containers (e.g., `user: "1000:1000"`) can't write to root-owned volumes

## The Solution
```bash
# Create shared group
sudo addgroup -g 2000 media

# Change directory to use shared group
sudo chgrp -R media /mnt/media
sudo chmod -R g+w /mnt/media

# Configure container to use shared group
user: "1000:2000"  # user_id:group_id
```

Both root and non-root containers can now write to the same directory via the shared group.
