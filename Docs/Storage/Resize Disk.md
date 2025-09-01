```
apk add parted
```

```
parted /dev/sda
```

```
resizepart 3 100%
```

```
apk add e2fsprogs-extra
```

```
resize2fs /dev/sda3
```