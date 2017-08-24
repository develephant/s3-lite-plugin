# Virtual File System

While you can create a "folder" in the AWS S3 console, these are actually just a visual representation of a virtual file system.

You can create these directory hierarchies by prefixing the object key when using the __putObject__ API method:

```lua
s3:putObject(
  system.DocumentsDirectory,
  "image.jpg",
  "my-bucket",
  "images/image.jpg", -- virtual directory is 'images'
  listener
)
```

You can also create deeper structures:

```lua
s3:putObject(
  system.DocumentsDirectory,
  "image.jpg",
  "my-bucket",
  "images/indoors/002/image.jpg", -- nested directory structure
  listener
)
```

# Listing Virtual Directories

You can specifically list objects in these structures when using the __listObjects__ API method, by passing a __prefix__ key to the params table:

```lua
local params = {
  prefix = "images" -- list objects in the images 'directory'
}

s3:listObjects(
  "my-bucket",
  listener,
  params
)
```

For the deeper structure:

```lua
local params = {
  prefix = "images/indoors/002"
}

s3:listObjects(
  "my-bucket",
  listener,
  params
)
```

# Filtering by Prefix

You can use the __prefix__ key to filter the objects in a directory, for example to return all object that start with a capital 'E':

```lua
local params = {
  prefix = "E"
}

s3:listObjects(
  "my-bucket",
  listener,
  params
)
```

