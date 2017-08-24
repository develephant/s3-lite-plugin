
local s3 = require("plugin.s3-lite")
local auth = require("auth-config")

local widget = require("widget")

s3:new({
  key = auth.key,
  secret = auth.secret
})

--=============================================================================
--# APP
--=============================================================================

local bucket_name = "coronium-vendor-files"

local upload_idx = 1
local download_idx = 1

local assets = {
  {src="card.png.txt",file="card.png",dest="card.png"},
  {src="bg.jpg.txt",file="bg.jpg",dest="bg.jpg"},
  {src="card.png.txt",file="card2.png",dest="cards/card2.png"},
  {src="bg.jpg.txt",file="bg2.jpg",dest="cards/bg.jpg"},
  {src="ssk.zip",file="ssk.zip",dest="ssk.zip"}
}

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

  --get file queue
  local entry
  if upload_idx <= #assets then
    print(upload_idx)
    entry = assets[upload_idx]
    upload_idx = upload_idx + 1
  end

  --android
  s3.utils.copyFile(
    "assets/"..entry.src, nil, 
    entry.file, system.DocumentsDirectory, 
    true)

  local params = {
    storage = s3.REDUCED_REDUNDANCY
  }

  s3:putObject(
    system.DocumentsDirectory,
    entry.file,
    bucket_name,
    entry.dest,
    onUpload,
    params
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

  --get file queue
  local entry
  if download_idx <= #assets then
    print(download_idx)
    entry = assets[download_idx]
    download_idx = download_idx + 1
  end

  s3:getObject(
    bucket_name,
    entry.dest,
    system.DocumentsDirectory,
    entry.file,
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

  s3:listObjects(bucket_name, onListObjects, params)
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

  s3:listBuckets(onListBuckets)
end


local xPos = 160

local uploadBtn = widget.newButton({
  x = xPos,
  y = 80,
  label = "upload",
  onRelease = uploadBtnCb
})

local downloadBtn = widget.newButton({
  x = xPos,
  y = 160,
  label = "download",
  onRelease = downloadBtnCb
})

local deleteBtn = widget.newButton({
  x = xPos,
  y = 240,
  label = "delete",
  onRelease = deleteBtnCb
})

local listObjectsBtn = widget.newButton({
  x = xPos,
  y = 320,
  label = "list objects",
  onRelease = listObjectsCb
})

local listBucketsBtn = widget.newButton({
  x = xPos,
  y = 400,
  label = "list buckets",
  onRelease = listBucketsCb
})

