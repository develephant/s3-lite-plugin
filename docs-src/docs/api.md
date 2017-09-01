
# Setup

To use the S3 Lite plugin, you will need to __require__ it:

```lua
local s3 = require("plugin.s3-lite")
```

---

## new

Create and initialize a new S3 Lite instance.

```lua
s3:new(config_tbl)
```

__Config Table Keys__

|Name|Description|Type|Default|Required|
|----|-----------|----|-------|--------|
|key|The AWS key for the account.|_String_|nil|__Y__|
|secret|The AWS secret key for the account.|_String_|nil|__Y__|
|region|The region where the S3 bucket resides.|_[Const](constants/#regions)_|s3.US_EAST_1|__N__|

__Usage__

```lua
s3:new({
  key = "aws-key-1234",
  secret = "aws-secret-abcd",
  region = s3.EU_WEST_1
})
```

!!! note
    The AWS user must have the proper S3 [permissions](notes/#user-permissions) set up through the AWS IAM console.

---

## listBuckets

List S3 buckets that are owned by the AWS user. Returns a table array with bucket names. If no buckets exist, the array will be empty.

```lua
s3:listBuckets(listener)
```

__Parameters__

|Name|Description|Type|Required|
|----|-----------|----|--------|
|listener|An event listener to receive the results.|_Function_|__Y__|

__Usage__

```lua
local function onListBuckets( evt )
  if evt.error then
    print(evt.error, evt.message, evt.status)
  else
    local buckets = evt.buckets
    for i=1, #buckets do
      print(buckets[i])
    end
  end
end

s3:listBuckets(onListBuckets)
```

!!! note
    Bucket creation and deletion must be managed through the AWS S3 web console.

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
local function onListObjects( evt )
  if evt.error then
    print(evt.error, evt.message, evt.status)
  else
    local objects = evt.objects

    for i=1, #objects do
      print(objects[i].key, objects[i].size)
    end
  end
end

s3:listObjects("my-bucket", onListObjects)
```

__List Objects Parameters Keys__

|Key|Description|Type|Default|
|---|-----------|----|-------|
|maxKeys|Sets the maximum number of keys returned.|_Number_|1000|
|prefix|Return keys that begin with the specified prefix. See [Prefixes](prefixes).|_String_|nil|
|startAfter|Return key names after a specific object key. See __Start-After__ below.|_String_|nil|
|nextToken|Token to get the next set of results, if any. See __Paging__ below.|_String_|nil|

__Usage__

```lua
local function onListObjects( evt )
  if evt.error then
    print(evt.error, evt.message, evt.status)
  else
    local objects = evt.objects

    for i=1, #objects do
      print(objects[i].key, objects[i].size)
    end
  end
end

local params = {
  maxKeys = 20
}

s3:listObjects("my-bucket", onListObjects, params)
```

__Paging__

If the bucket contains more than 1000 objects, or you have set the __maxKeys__ to a number less than the total amount of objects in the bucket, you will receive a token in the response that you can use to get the next batch of results.

To check if more results are available, check for the __nextToken__ key in the response event:

```lua
local token

local function onListObjects( evt )
  if evt.error then
    print(evt.error)
  else

    --check for more results
    if evt.nextToken then
      --store the token however you'd like
      token = evt.nextToken
    end

    --print out the current object list results
    for i=1, #evt.objects do
      print(evt.objects[i].key)
    end

  end
end

local params = {
  maxKeys = 20
}

s3:listObjects("my-bucket", onListObjects, params)
```

You then call the __listObjects__ method again, passing the token in the __params__ to get the next batch:

```lua
-- listener function goes here
-- ...

local params = {
  maxKeys = 20,
  nextToken = token
}

s3:listObjects("my-bucket", onListObjects, params)
```

__Start-After__

To list objects after a specific object key, add the object key to the __startAfter__ params key:

```lua
local params = {
  startAfter = "image001.png"
}
```

---

## putObject

Upload a file to a bucket owned by the AWS user.

```lua
s3:putObject(base_dir, file_path, bucket_name, object_key, listener[, params])
```

__Parameters__

|Name|Description|Type|Required|
|----|-----------|----|--------|
|base_dir|The system base directory.|_[Const](constants/#base-directories)_|__Y__|
|file_path|The source file path with extension.|_String_|__Y__|
|bucket_name|The name of the destination bucket.|_String_|__Y__|
|object_key|The destination object key with extension.|_String_|__Y__|
|listener|An event listener to receive the results.|_Function_|__Y__|
|params|Optional parameters for the put operation.|_Table_|__N__|

__Usage__

```lua
local function onPutObject( evt )
  if evt.error then
    print(evt.error, evt.message, evt.status)
  else
    if evt.progress then
      print(evt.progress)
    else
      print("object upload complete")
    end
  end
end

s3:putObject(
  system.DocumentsDirectory,
  "image.png",
  "my-bucket",
  "my-image.png",
  onPutObject
)
```

__Put Object Parameters Keys__

|Key|Description|Type|Default|
|---|-----------|----|-------|
|acl|A canned ACL code.|_[Const](constants/#canned-acl)_|s3.PRIVATE|
|storage|The storage class for the uploaded file.|_[Const](constants/#storage-class)_|s3.STANDARD|

__Usage__

```lua
local function onPutObject( evt )
  if evt.error then
    print(evt.error, evt.message, evt.status)
  else
    if evt.progress then
      print(evt.progress)
    else
      print("object upload complete")
    end
  end
end

local params = {
  storage = s3.REDUCED_REDUNDANCY
}

s3:putObject("my-bucket", onPutObject, params)
```

__Upload Progress__

By default the __putObject__ listener event returns a __progress__ key with the current upload progress as a decimal value between 0 and 1 that you can use to create progress bars, etc.

If you don't care about the progress, you can write the listener function like so:

```lua
local function onPutObject( evt )
  if evt.error then
    print(evt.error, evt.message, evt.status)
  else
    if not evt.progress then
      print("object upload complete")
    end
  end
end
```

---

## getObject

Download a file from a bucket owned by the AWS user.

```lua
s3:getObject(bucket_name, object_key, base_dir, dest_path, listener)
```

__Parameters__

|Name|Description|Type|Required|
|----|-----------|----|--------|
|bucket_name|The name of the source bucket.|_String_|__Y__|
|object_key|The object key with extension.|_String_|__Y__|
|base_dir|The system base directory.|_[Const](constants/#base-directories)_|__Y__|
|dest_path|The destination file path with extenstion.|_String_|__Y__|
|listener|An event listener to receive the results.|_Function_|__Y__|

__Usage__

```lua
local function onGetObject( evt )
  if evt.error then
    print(evt.error, evt.message, evt.status)
  else
    if evt.progress then
      print(evt.progress)
    else
      print("object download complete")
    end
  end
end

s3:getObject(
  "my-bucket", 
  "image.png", 
  system.DocumentsDirectory,
  "my-image.png",
  onGetObject
)
```

__Download Progress__

By default the __getObject__ listener event returns a __progress__ key with the current download progress as a decimal value between 0 and 1 that you can use to create progress bars, etc.

If you don't care about the progress, you can write the listener function like so:

```lua
local function onGetObject( evt )
  if evt.error then
    print(evt.error, evt.message, evt.status)
  else
    if not evt.progress then
      print("object download complete")
    end
  end
end
```

---

## deleteObject

Delete a file from a bucket owned by the AWS user.

```lua
s3:deleteObject(bucket_name, object_key, listener)
```

__Parameters__

|Name|Description|Type|Required|
|----|-----------|----|--------|
|bucket_name|The name of the source bucket.|_String_|__Y__|
|object_key|The object file key with extension.|_String_|__Y__|
|listener|An event listener to receive the results.|_Function_|__Y__|

__Usage__

```lua
local function onDeleteObject( evt )
  if evt.error then
    print(evt.error, evt.message, evt.status)
  else
    print("object deleted")
  end
end

s3:deleteObject("my-bucket", "image.png", onDeleteObject)
```

!!! note
    If the bucket object does not exist, this method will fail silently without an error.