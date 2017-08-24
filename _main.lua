-- 
-- Abstract: s3-lite Library Plugin Test Project
-- 
-- Sample code is MIT licensed, see http://www.coronalabs.com/links/code/license
-- Copyright (C) 2015 Corona Labs Inc. All Rights Reserved.
--
------------------------------------------------------------

-- Load plugin library
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

local function uploadBtnCb( evt )
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

local function downloadBtnCb( evt )
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

local function deleteBtnCb( evt )
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

local function listObjectsCb( evt )
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

local function listBucketsCb( evt )
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


-- local function onUploadResponse( evt )
--   if evt.error then
--     print(evt.error, evt.message, evt.status)
--   else
--     if evt.progress then
--       print(evt.progress)
--     else
--       print("file uploaded")
--     end
--   end
-- end

-- local function uploadFile(file, object_key)

--   s3.utils.copyFile( "assets/"..file..".txt", nil, file, system.DocumentsDirectory, true )
--   s3:putObject(system.DocumentsDirectory, file, "coronium-bucket-eu", object_key, onUploadResponse)

-- end


-- local function uploadBtnListener( evt )
--   uploadFile("card.png", "cards/card.png")
-- end

-- local function uploadBtn2Listener( evt )
--   uploadFile("bg.jpg", "bg2.jpg")
-- end

-- uploadBtn:addEventListener( "tap", uploadBtnListener )
-- uploadBtn2:addEventListener( "tap", uploadBtn2Listener )

--=============================================================================
--# TESTS
--=============================================================================

--#############################################################################
--# Bucket Listing
--#############################################################################
-- local function onBucketList( evt )
--   if evt.error then
--     print(evt.error, evt.message, evt.status)
--   else
--     local buckets = evt.buckets
--     for i=1, #buckets do
--       print(buckets[i])
--     end
--     print("done")
--   end
-- end

-- s3:listBuckets( onBucketList )

--#############################################################################
--# Object Listing
--#############################################################################
-- local function onObjectList( evt )
--   if evt.error then
--     print(evt.error, evt.message, evt.status)
--   else
--     local objects = evt.objects
    
--     if evt.nextToken then
--       print(evt.nextToken)
--     end

--     for i=1, #objects do
--       print(objects[i].key, objects[i].size)
--     end
--   end
-- end

-- local params = {
--   prefix = "cards"
-- }

-- s3:listObjects( "coronium-bucket-eu", onObjectList, params )

--#############################################################################
--# Put Object
--#############################################################################
-- local function onPutObject( evt )
--   if evt.error then
--     print(evt.error, evt.message, evt.status)
--   else
--     if evt.progress then
--       print(evt.progress)
--     else
--       print("object upload complete")
--     end
--   end
-- end

-- local params = {
--   storage = s3.REDUCED_REDUNDANCY
-- }

-- s3:putObject(system.DocumentsDirectory, "bg.jpg", "coronium-tester", "images:bg2.jpg", onPutObject, params)

--#############################################################################
--# Get Object
--#############################################################################
-- local function onGetObject( evt )
--   if evt.error then
--     print(evt.error, evt.message, evt.status)
--   else
--     if evt.progress then
--       print(evt.progress)
--     else
--       print("object download complete")
--     end
--   end
-- end

-- s3:getObject("coronium-bucket-eu", "cards/card.png", system.DocumentsDirectory, "card3.png", onGetObject)

--#############################################################################
--# Delete Object
--#############################################################################
-- local function onDeleteObject( evt )
--   if evt.error then
--     print(evt.error, evt.message, evt.status)
--   else
--     print("object deleted")
--   end
-- end

-- s3:deleteObject("coronium-bucket-eu", "cards/card.png", onDeleteObject)
