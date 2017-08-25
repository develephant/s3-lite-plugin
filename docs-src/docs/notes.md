# User permissions

The AWS user must have the proper S3 permissons. In particular the following permissions are required for the S3 Lite plugin:

- DeleteObject
- GetObject
- ListAllMyBuckets
- ListBucket
- PutObject
- PutObjectAcl

You can add these when creating a IAM user, or as an S3 policy file.

!!! tip
    For testing, when creating a IAM user, you can use the canned policy _AmazonS3FullAccess_. 

---

# Android file restrictions

When working with Android, make sure you understand the file restrictions. You can find more information in the Corona documentation by [clicking here](https://docs.coronalabs.com/guide/data/readWriteFiles/index.html#android-file-restrictions).

In the documentaion, there is a reference to a __[copyFile](https://docs.coronalabs.com/guide/data/readWriteFiles/index.html#copying-files-to-subfolders)__ method. As a convenience, this method is available in the S3 Lite plugin and can be accessed like so:

```lua
s3.utils.copyFile(srcName, srcPath, dstName, dstPath, overwrite)
```

---

# Slow responses

Depending on network conditions, device, and file size there can be a number of seconds delay between issuing a command to S3, and the actual response.