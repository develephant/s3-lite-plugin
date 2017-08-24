
local request = require("plugin.s3-lite.awsrequest")
local xml = require("plugin.s3-lite.xmlSimple").newParser()
local mimes = require("plugin.s3-lite.mimes")

local io = require("io")

local s3 = {
  aws_key = nil,
  aws_secret = nil,
  aws_region = nil,
  aws_service = "s3",
  aws_host = "amazonaws.com",

  log = nil
}

--#############################################################################
--# Enums
--#############################################################################
-- Storage Class
s3.STANDARD = "STANDARD"
s3.REDUCED_REDUNDANCY = "REDUCED_REDUNDANCY"

-- Canned ACL
s3.PRIVATE = "private"
s3.PUBLIC_READ = "public-read"
s3.PUBLIC_READ_WRITE = "public-read-write"
s3.AWS_EXEC_READ = "aws-exec-read"
s3.AUTHENTICATED_READ = "authenticated-read"
s3.BUCKET_OWNER_READ = "bucket-owner-read"
s3.BUCKET_OWNER_FULL_CONTROL = "bucket-owner-full-control"

-- Regions
s3.US_EAST_1 = "us-east-1"
s3.US_EAST_2 = "us-east-2"
s3.US_WEST_1 = "us-west-1"
s3.US_WEST_2 = "us-west-2"
s3.CA_CENTRAL_1 = "ca-central-1"
s3.EU_WEST_1 = "eu-west-1"
s3.EU_WEST_2 = "eu-west-2"
s3.EU_CENTRAL_1 = "eu-central-1"
s3.AP_SOUTH_1 = "ap-south-1"
s3.AP_SOUTHEAST_1 = "ap-southeast-1"
s3.AP_SOUTHEAST_2 = "ap-southeast-2"
s3.AP_NORTHEAST_1 = "ap-northeast-1"
s3.AP_NORTHEAST_2 = "ap-northeast-2"
s3.SA_EAST_1 = "sa-east-1"

--#############################################################################
--# Init
--#############################################################################
function s3:new( config )
  self.aws_key = config.key
  self.aws_secret = config.secret
  self.aws_region = config.region or s3.US_EAST_1
end

--#############################################################################
--# Privates
--#############################################################################
function s3:_getAuthCreds()
  return {
    aws_key = self.aws_key,
    aws_secret = self.aws_secret,
    log = self.log
  }
end

function s3:_getHTTPDate()
  local gmt_time = os.time(os.date('*t'))
  return os.date('!%a, %d %b %Y %X GMT', gmt_time)
end

function s3:_getHostEndpoint( bucket_name )
  if self.aws_region == s3.US_EAST_1 then
    return bucket_name..".s3."..self.aws_host
  else
    return bucket_name..".s3-"..self.aws_region.."."..self.aws_host
  end
end

--#############################################################################
--# XML Parsing
--#############################################################################
function s3:get_error_msg( xml_txt )
  local xmlDoc = xml:ParseXmlText( xml_txt )
  if xmlDoc.Error then
    local code, message
    error = xmlDoc.Error.Code:value()
    message = xmlDoc.Error.Message:value()
    return { error = error, message = message }
  end

  return nil
end

function s3:get_bucket_list( xml_txt )
  local xmlDoc = xml:ParseXmlText( xml_txt )
  if xmlDoc.ListAllMyBucketsResult then
    if xmlDoc.ListAllMyBucketsResult.Buckets.Bucket then
      local buckets = xmlDoc.ListAllMyBucketsResult.Buckets.Bucket
      local bucket_list = {}
      for i=1, #buckets do
        table.insert(bucket_list, buckets[i].Name:value())
      end
      return bucket_list
    else
      return {}
    end
  end

  return nil
end

function s3:get_objects_list( xml_txt )
  local xmlDoc = xml:ParseXmlText( xml_txt )
  if xmlDoc.ListBucketResult then
    if xmlDoc.ListBucketResult.Contents then
      --continuation-token
      local next_token = nil
      if xmlDoc.ListBucketResult.NextContinuationToken then
        next_token = tostring(xmlDoc.ListBucketResult.NextContinuationToken:value())
      end

      --objects
      local keyCount = tonumber(xmlDoc.ListBucketResult.KeyCount:value())
      if (keyCount > 0) and (keyCount < 2) then
        local object = xmlDoc.ListBucketResult.Contents
        return { {key = object.Key:value(), size = object.Size:value()} }, next_token
      else
        local objects = xmlDoc.ListBucketResult.Contents
        local object_list = {}
        for i=1, keyCount do
          table.insert(object_list, {
            key = objects[i].Key:value(),
            size = objects[i].Size:value()
          })
        end
        return object_list, next_token
      end
    else
      return {}
    end
  end

  return nil
end

--#############################################################################
--# Bucket Config
--DISABLED
--#############################################################################
-- local function gen_bucket_location( region )
--   return string.format('<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><LocationConstraint>%s</LocationConstraint></CreateBucketConfiguration >', region)
-- end

--#############################################################################
--# List Buckets
--#############################################################################
function s3:listBuckets( listener )

  local req = request:new(self:_getAuthCreds())

  req:setMethod("GET")
  req:setService(self.aws_service)
  req:setRegion("us-east-1")
  req:setHost("s3.amazonaws.com")
  req:setHeaders(nil)
  req:setPath(nil)
  req:setQuery(nil)
  req:setPayload(nil)
  req:setContentSha(nil)

  local function onResult( evt )
    if evt.isError then
      return listener( { error = evt.response } )
    else

      local status = evt.status

      --check for s3 error
      local error_res = self:get_error_msg(evt.response)
      if error_res then
        return listener({
          error = error_res.error,
          message = error_res.message,
          status = status
        })
      end

      --check for bucket list
      local bucketList = self:get_bucket_list(evt.response)
      if not bucketList then
        return listener({
          error = "BucketListFailed",
          message = "Could not parse bucket list",
          status = status
        })
      end

      return listener( { buckets = bucketList } )
    end
  end

  req:send( nil, onResult )

end

--#############################################################################
--# Bucket Check
--#############################################################################
function s3:_isBucketAvailable( bucket_name, listener )
  local req = request:new(self:_getAuthCreds())
  local http_date = self:_getHTTPDate()

  req:setMethod("HEAD")
  req:setService(self.aws_service)
  req:setRegion(self.aws_region)
  req:setHost(self:_getHostEndpoint(bucket_name))
  req:setPath(nil)
  req:setQuery(nil)
  req:setPayload(nil)
  req:setHeaders({["Date"] = http_date})
  req:setContentSha(nil)

  local function onResult( evt )
    if evt.isError then
      return listener({ error = evt.response })
    else

      local status = tonumber(evt.status)

      if status == 200 then
        return listener({})
      elseif status == 301 then
        return listener({ 
          error = "RegionIncorrect", 
          message = "The specified region is incorrect",
          status = status 
        })
      elseif status == 404 then
        return listener({ 
          error = "NotFound", 
          message = "Bucket does not exist",
          status = status 
        })
      elseif status == 403 then
        return listener({ 
          error = "AccessDenied", 
          message = "Bucket access is forbidden",
          status = status 
        })
      else
        return listener({ 
          error = "InfoFailed", 
          message = "Could not obtain bucket meta",
          status = status 
        })
      end

    end
  end

  req:send( nil, onResult )
end

--#############################################################################
--# List Objects
--#############################################################################
function s3:listObjects( bucket_name, listener, params )

  local req = request:new(self:_getAuthCreds())

  --build query string
  local query_tbl = {}
  --list-type
  query_tbl["list-type"] = 2
  --continuation token
  if params and params.nextToken then
    query_tbl["continuation-token"] = params.nextToken
  end
  --max-keys
  if params and params.maxKeys then
    query_tbl["max-keys"] = params.maxKeys
  end
  --prefix
  if params and params.prefix then
    query_tbl["prefix"] = params.prefix
  end
  --start-after
  if params and params.startAfter then
    query_tbl["start-after"] = params.startAfter
  end

  req:setMethod("GET")
  req:setService(self.aws_service)
  req:setRegion(self.aws_region)
  req:setHost(self:_getHostEndpoint(bucket_name))
  req:setHeaders(nil)
  req:setPath(nil)
  req:setQuery(query_tbl)
  req:setPayload(nil)
  req:setContentSha(nil)

  local function onResult( evt )
    if evt.isError then
      return listener( { error = evt.response } )
    else

      local status = tonumber(evt.status)

      if status == 301 then
        return listener({ 
          error = "RegionIncorrect", 
          message = "The specified region is incorrect",
          status = status 
        })
      end

      --check for s3 error
      local error_res = self:get_error_msg(evt.response)
      if error_res then
        return listener({
          error = error_res.error,
          message = error_res.message,
          status = status
        })
      end

      --check for object list
      local objectsList, nextToken = self:get_objects_list(evt.response)
      if not objectsList then
        return listener({
          error = "ObjectsListFailed",
          message = "Could not parse object list for bucket",
          status = status
        })
      end

      return listener( { objects = objectsList, nextToken = nextToken } )
    end
  end

  req:send( nil, onResult )

end

--#############################################################################
--# Get Object
--#############################################################################
function s3:getObject( bucket_name, object_path, dest_path, dest_file, listener )

  local req = request:new(self:_getAuthCreds())

  req:setMethod("GET")
  req:setService(self.aws_service)
  req:setRegion(self.aws_region)
  req:setHost(self:_getHostEndpoint(bucket_name))
  req:setHeaders(nil)
  req:setPath(object_path)
  req:setQuery(nil)
  req:setPayload(nil)
  req:setContentSha(nil)

  local function onResult( evt )
    if evt.isError then
      return listener( { error = evt.response } )
    else

      if evt.phase == "progress" then

        local per_value = string.format("%.2f", (evt.bytesTransferred / evt.bytesEstimated))
        return listener({ progress = per_value })

      elseif evt.phase == "ended" then

        local status = tonumber(evt.status)

        if status == 301 then
          return listener({ 
            error = "RegionIncorrect", 
            message = "The specified region is incorrect",
            status = status 
          })
        end

        --check for s3 error
        if evt.responseType == "text" then
          local error_res = self:get_error_msg(evt.response)
          if error_res then
            return listener({
              error = error_res.error,
              message = error_res.message,
              status = status
            })
          end
        end

        return listener({}) --all done

      end
    end
  end

  req:download( dest_file, dest_path, onResult )
end

--#############################################################################
--# Put Object
--#############################################################################
function s3:_putObject(src_path, src_file, bucket_name, object_path, listener, params)

  local http_date = self:_getHTTPDate()
  local mime_type = mimes.findMimeType(src_file)

  --get content
  local file_path = system.pathForFile(src_file, src_path)

  local fd, err = io.open(file_path, 'rb')

  if not fd then
    return listener({ 
      error = "FileError",
      message = err })
  end
  
  local content = fd:read("*a")
  local len = #content
  fd:close()

  --set up headers
  local headers = {
    ["Content-Length"] = len,
    ["Content-Type"] = mime_type,
    ["Date"] = http_date    
  }

  --check params
  if params and params.storage then
    headers["x-amz-storage-class"] = params.storage
  end

  if params and params.acl then
    headers["x-amz-acl"] = params.acl
  end

  local req = request:new(self:_getAuthCreds())

  req:setMethod("PUT")
  req:setService(self.aws_service)
  req:setRegion(self.aws_region)
  req:setHost(self:_getHostEndpoint(bucket_name))
  req:setPath(object_path)
  req:setQuery(nil)
  req:setPayload(content)
  req:setHeaders(headers)
  req:setContentSha(content)

  local function onResult( evt )
    if evt.isError then
      return listener( { error = evt.response } )
    else

      if evt.phase == "progress" then

        local per_value = string.format("%.2f", (evt.bytesTransferred / evt.bytesEstimated))
        return listener({ progress = per_value })      

      elseif evt.phase == "ended" then

        local status = evt.status

        --check for s3 error
        local error_res = self:get_error_msg(evt.response)
        if error_res then
          return listener({
            error = error_res.error,
            message = error_res.message,
            status = status
          })
        end

        return listener({})

      end
    end
  end

  req:upload( content, onResult )
end

--bucket check
function s3:putObject(src_path, src_file, bucket_name, object_path, listener, params)
  local function onBucketAvailable( evt )
    if evt.error then
      return listener({
        error = evt.error, 
        message = evt.message, 
        status = evt.status
      })
    else
      --all clear
      self:_putObject(src_path, src_file, bucket_name, object_path, listener, params)
    end
  end

  self:_isBucketAvailable(bucket_name, onBucketAvailable)
end

--#############################################################################
--# Delete Object
--#############################################################################
function s3:deleteObject( bucket_name, object_path, listener )

  local req = request:new(self:_getAuthCreds())
  local http_date = self:_getHTTPDate()

  req:setMethod("DELETE")
  req:setService(self.aws_service)
  req:setRegion(self.aws_region)
  req:setHost(self:_getHostEndpoint(bucket_name))
  req:setHeaders(nil)
  req:setPath(object_path)
  req:setQuery(nil)
  req:setPayload(nil)
  req:setContentSha(nil)

  local function onResult( evt )
    if evt.isError then
      return listener( { error = evt.response } )
    else

      local status = tonumber(evt.status)

      if status == 301 then
        return listener({ 
          error = "RegionIncorrect", 
          message = "The specified region is incorrect",
          status = status 
        })
      end

      --check for s3 error
      local error_res = self:get_error_msg(evt.response)
      if error_res then
        return listener({
          error = error_res.error,
          message = error_res.message,
          status = status
        })
      end

      return listener({})
    end
  end

  req:send( nil, onResult )
end

--#############################################################################
--# Utils
--#############################################################################
local function _doesFileExist( fname, path )
 
    local results = false
 
    -- Path for the file
    local filePath = system.pathForFile( fname, path )
 
    if ( filePath ) then
        local file, errorString = io.open( filePath, "r" )
 
        if not file then
            -- Error occurred; output the cause
            print( "File error: " .. errorString )
        else
            -- File exists!
            --print( "File found: " .. fname )
            results = true
            -- Close the file handle
            file:close()
        end
    end
 
    return results
end

local function _copyFile( srcName, srcPath, dstName, dstPath, overwrite )
 
    local results = false
 
    local fileExists = _doesFileExist( srcName, srcPath )
    if ( fileExists == false ) then
        return nil  -- nil = Source file not found
    end
 
    -- Check to see if destination file already exists
    if not ( overwrite ) then
        if ( _doesFileExist( dstName, dstPath ) ) then
            return 1  -- 1 = File already exists (don't overwrite)
        end
    end
 
    -- Copy the source file to the destination file
    local rFilePath = system.pathForFile( srcName, srcPath )
    local wFilePath = system.pathForFile( dstName, dstPath )
 
    local rfh = io.open( rFilePath, "rb" )
    local wfh, errorString = io.open( wFilePath, "wb" )
 
    if not ( wfh ) then
        -- Error occurred; output the cause
        print( "File error: " .. errorString )
        return false
    else
        -- Read the file and write to the destination directory
        local data = rfh:read( "*a" )
        if not ( data ) then
            print( "Read error!" )
            return false
        else
            if not ( wfh:write( data ) ) then
                print( "Write error!" )
                return false
            end
        end
    end
 
    results = 2  -- 2 = File copied successfully!
 
    -- Close file handles
    rfh:close()
    wfh:close()
 
    return results
end

--Utils object
s3.utils = {
  copyFile = _copyFile
}

--#############################################################################
--# Create Bucket
--# DISABLED
--#############################################################################
-- function s3:createBucket( bucket_name, listener, params )

--   local req = request:new(self:_getAuthCreds())
--   local http_date = self:_getHTTPDate()

--   local location_config = ""
--   if params and params.region then
--     if params.region ~= "us-east-1" then
--       location_config = gen_bucket_location( params.region )
--     end
--   end

--   local acl = "bucket-owner-full-control"
--   if params and params.acl then
--     acl = params.acl
--   end

--   req:setService(self.aws_service)

--   req:setMethod("PUT")
--   req:setHost(self.aws_host)
--   req:setRegion(self.aws_region)

--   req:setPath(bucket_name)

--   req:setHeaders({
--     ["Content-Length"] = #location_config,
--     ["Content-Type"] = "text/plain; charset=UTF-8",
--     ["Date"] = http_date,
--     ["x-amz-acl"] = acl
--   })

--   req:setPayload(location_config)

--   req:setContentSha(location_config)

--   local function onResult( evt )
--     if evt.isError then
--       return listener( { error = evt.response } )
--     else

--       local status = evt.status

--       --check for s3 error
--       local error_res = self:get_error_msg(evt.response)
--       if error_res then
--         return listener({
--           error = error_res.error,
--           message = error_res.message,
--           status = status
--         })
--       end

--       return listener({})
--     end
--   end

--   req:send( location_config, onResult )  
-- end

--#############################################################################
--# Delete Bucket
--# DISABLED
--#############################################################################
-- function s3:deleteBucket( bucket_name, listener )
--   local req = request:new(self:_getAuthCreds())
--   local http_date = self:_getHTTPDate()

--   req:setService(self.aws_service)

--   req:setMethod("DELETE")
--   req:setHost(bucket_name..'.'..self.aws_host)
--   req:setRegion(self.aws_region)

--   req:setContentSha("")

--   local function onResult( evt )
--     if evt.isError then
--       return listener( { error = evt.response } )
--     else

--       local status = evt.status

--       --check for s3 error
--       local error_res = self:get_error_msg(evt.response)
--       if error_res then
--         return listener({
--           error = error_res.error,
--           message = error_res.message,
--           status = status
--         })
--       end

--       return listener({})
--     end
--   end

--   req:send( nil, onResult )
-- end

return s3