
local s3 = require("plugin.s3-lite")
local auth = require("auth-config")

local widget = require("widget")

s3:new({
  key = auth.key,
  secret = auth.secret,
  region = s3.EU_WEST_1
})

--=============================================================================
--# APP
--=============================================================================

local bucket_name = "coronium-bucket-test"

local function uploadBtnCb( e )
  print("uploading object")

  local function onUpload( evt )
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

  --android
  s3.utils.copyFile("card.png.txt", nil, "card.png", system.DocumentsDirectory, true)

  s3:putObject(
    system.DocumentsDirectory,
    "card.png",
    bucket_name,
    "card.png",
    onUpload
  )
end

local function downloadBtnCb( e )
  print("downloading object")

  local function onDownload( evt )
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
    bucket_name,
    "card.png",
    system.DocumentsDirectory,
    "card2.png",
    onDownload
  )
end

local function deleteBtnCb( e )
  print("delete")

  local function onDelete( evt )
    if evt.error then
      print(evt.error, evt.message, evt.status)
    else
      print("object deleted")
    end
  end

  s3:deleteObject(bucket_name, "card.png", onDelete)
end

local function listObjectsCb( e )
  print("listing objects")

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

  s3:listObjects(bucket_name, onListObjects)
end

local function listBucketsCb( e )
  print("listing buckets")

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

  s3:listBuckets(bucket_name, onListBuckets)
end


local xPos = 160

local uploadBtn = widget.newButton({
  x = xPos,
  y = 80,
  label = "upload",
  textOnly = true,
  onRelease = uploadBtnCb
})

local downloadBtn = widget.newButton({
  x = xPos,
  y = 160,
  label = "download",
  textOnly = true,
  onRelease = downloadBtnCb
})

local deleteBtn = widget.newButton({
  x = xPos,
  y = 240,
  label = "delete",
  textOnly = true,
  onRelease = deleteBtnCb
})

local listObjectsBtn = widget.newButton({
  x = xPos,
  y = 320,
  label = "list objects",
  textOnly = true,
  onRelease = listObjectsCb
})

local listBucketsBtn = widget.newButton({
  x = xPos,
  y = 400,
  label = "list buckets",
  textOnly = true,
  onRelease = listBucketsCb
})

