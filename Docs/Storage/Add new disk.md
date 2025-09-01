```
apk add parted
```

```
parted /dev/sdb mklabel gpt mkpart primary ext4 0% 100%
```

```
parted /dev/sdb mkpart primary ext4 0% 100%
```

```
mkfs.ext4 /dev/sdb1
```