
# Setup

To use the S3 Lite plugin, you will need to _require_ it:

```lua
local s3 = require("plugin.s3-lite")
```

---

## new

Creates a new S3 Lite object instance.

```lua
s3:new(config_tbl)
```

__Config Table Keys__

|Name|Description|Type|Required|
|----|-----------|----|--------|
|aws_key|The AWS key for the account.|_String_|__Y__|
|aws_secret|The AWS secret key for the account.|_String_|__Y__|
|log|Output logging info to the console.|_Boolean_|__N__|

__Usage__

```lua
s3:new({
  aws_key = "aws-key-1234",
  aws_secret = "aws-secret-abcd",
  log = true
})
```

!!! note
    The AWS user must have the proper S3 permissions set up through the AWS IAM console.

---

## listBuckets

List S3 buckets that are owned by the AWS user.

```lua
s3:listBuckets(listener)
```

__Parameters__

|Name|Description|Type|Required|
|----|-----------|----|--------|
|listener|An event listener to receive the results.|_Function_|__Y__|

__Usage__

```lua
local function onResponse( evt )
  if evt.error then
    print( evt.error )
  else
    print( evt.result )
  end
end

s3:listBuckets(onResponse)
```

---

## createBucket

Create a new bucket to be owned by the AWS user.

```lua
s3:createBucket(bucket_name, listener[, params])
```

__Parameters__

|Name|Description|Type|Required|
|----|-----------|----|--------|
|bucket_name|The name of the bucket to create.|_String_|__Y__|
|listener|An event listener to receive the results.|_Function_|__Y__|
|params|Optional parameters for the bucket creation.|_Table_|__N__|

__Usage__

```lua
local function onResponse( evt )
  if evt.error then
    print( evt.error )
  else
    print( evt.result )
  end
end

s3:createBucket("my-bucket", onResponse)
```

__Bucket Parameters Keys__

|Key|Description|Type|Default|
|---|-----------|----|-------|
|region|An S3 region code.|[_Enum_](enums/#regions)|s3.US_EAST_1|
|acl|A canned ACL code.|[_Enum_](enums/#canned-acl)|s3.BUCKET_OWNER_FULL_CONTROL|

!!! note
    Once the __acl__ is set, you can only change it through the AWS S3 console.

__Usage__

```lua
local function onResponse( evt )
  if evt.error then
    print( evt.error )
  else
    print( evt.result )
  end
end

local params = {
  acl = s3.PUBLIC
}

s3:createBucket("my-bucket", onResponse, params)
```

---

## deleteBucket

Delete a bucket owned by the AWS user.

```lua
s3:deleteBucket(bucket_name, listener)
```

!!! warning "AWS Constraint"
    You can only delete empty buckets. To delete a bucket in any other region than 'us-east-1' you must provide a [policy file](http://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements.html) through the web admin on AWS.

__Parameters__

|Name|Description|Type|Required|
|----|-----------|----|--------|
|bucket_name|The name of the bucket to delete.|_String_|__Y__|
|listener|An event listener to receive the results.|_Function_|__Y__|

__Usage__

```lua
local function onResponse( evt )
  if evt.error then
    print( evt.error )
  else
    print( evt.result )
  end
end

s3:deleteBucket("my-bucket", onResponse)
```

---

## listObjects

List objects contained in a bucket owned by the AWS user.

```lua
s3:listObjects(bucket_name, listener[, params])
```

__Parameters__

|Name|Description|Type|Required|
|----|-----------|----|--------|
|bucket_name|The name of the bucket to list.|_String_|__Y__|
|listener|An event listener to receive the results.|_Function_|__Y__|

__Usage__

```lua
local function onResponse( evt )
  if evt.error then
    print( evt.error )
  else
    print( evt.result )
  end
end

s3:listObjects("my-bucket", onResponse)
```

__List Objects Parameters Keys__

|Key|Description|Type|Default|
|---|-----------|----|-------|
|maxKeys|Sets the maximum number of keys returned.|_Number_|1000|
|prefix|Return keys that begin with the specified prefix.|_String_|nil|
|startAfter|Return key names after a specific object key.|_String_|nil|
|nextToken|Token to get the next set of results, if any. See __Paging__ below.|_String_|nil|

__Usage__

```lua
local function onResponse( evt )
  if evt.error then
    print( evt.error )
  else
    print( evt.result )
  end
end

local params = {
  maxKeys = 20
}

s3:listObjects("my-bucket", onResponse, params)
```

__Paging__

---

## putObject

Upload a file to a bucket owned by the AWS user.

```lua
s3:putObject(src_dir, src_file, bucket_name, dest_file, listener[, params])
```

__Parameters__

|Name|Description|Type|Required|
|----|-----------|----|--------|
|src_dir|The source directory where the file resides.|_String_|__Y__|
|src_file|The source file name with extension.|_String_|__Y__|
|bucket_name|The name of the destination bucket.|_String_|__Y__|
|dest_file|The destination object name with extenstion.|_String_|__Y__|
|listener|An event listener to receive the results.|_Function_|__Y__|
|params|Optional parameters for the put operation.|_Table_|__N__|

__Usage__

```lua
local function onResponse( evt )
  if evt.error then
    print( evt.error )
  else
    print( evt.result )
  end
end

s3:putObject(
  system.DocumentsDirectory,
  "image.png",
  "my-bucket",
  "my-image.png",
  onResponse
)
```

__Put Object Parameters Keys__

|Key|Description|Type|Default|
|---|-----------|----|-------|
|acl|A canned ACL code.|[_Enum_](enums/#canned-acl)|s3.PRIVATE|
|storage|The storage class for the uploaded file.|[_Enum_](enums/#storage-class)|s3.STANDARD|

__Usage__

```lua
local function onResponse( evt )
  if evt.error then
    print( evt.error )
  else
    print( evt.result )
  end
end

local params = {
  storage = s3.REDUCED_REDUNDANCY
}

s3:createBucket("my-bucket", onResponse, params)
```

---

## getObject

Download a file from a bucket owned by the AWS user.

```lua
s3:getObject(bucket_name, file_path, dest_dir, dest_file, listener)
```

__Parameters__

|Name|Description|Type|Required|
|----|-----------|----|--------|
|bucket_name|The name of the source bucket.|_String_|__Y__|
|file_path|The object file path with extension.|_String_|__Y__|
|dest_dir|The destination directory.|_String_|__Y__|
|dest_file|The destination file name with extenstion.|_String_|__Y__|
|listener|An event listener to receive the results.|_Function_|__Y__|

__Usage__

```lua
local function onResponse( evt )
  if evt.error then
    print( evt.error )
  else
    print( evt.result )
  end
end

s3:getObject(
  "my-bucket", 
  "image.png", 
  system.DocumentsDirectory,
  "my-image.png",
  onResponse
)
```

---

## deleteObject

Delete a file from a bucket owned by the AWS user.

```lua
s3:deleteObject(bucket_name, file_path, listener)
```

__Parameters__

|Name|Description|Type|Required|
|----|-----------|----|--------|
|bucket_name|The name of the source bucket.|_String_|__Y__|
|file_path|The object file path with extension.|_String_|__Y__|
|listener|An event listener to receive the results.|_Function_|__Y__|

__Usage__

```lua
local function onResponse( evt )
  if evt.error then
    print( evt.error )
  else
    print( evt.result )
  end
end

s3:deleteObject("my-bucket", "image.png", listener)
```