
local AWSAuth = require("plugin.s3-lite.awsauth")
local urlencode = require("plugin.s3-lite.urlencode")

local request = {
  aws_key = nil,
  aws_secret = nil,

  method = nil,
  path = "/",
  query = nil,
  host = nil,
  headers = {},
  service = nil,
  region = nil,
  payload = "",

  contentSha = nil,

  log = nil
}

function request:new( params )
  self.aws_key = params.aws_key
  self.aws_secret = params.aws_secret

  self.log = params.log

  return self
end

function request:setMethod( method )
  self.method = method
end

function request:setPath( path )
  if path then
    self.path = "/"..path
  else
    self.path = "/"
  end
end

function request:setQuery( query_tbl )
  self.query = query_tbl or nil
end

function request:setHost( host )
  self.host = host
end

function request:setHeaders( headers_tbl )
  self.headers = headers_tbl or {}
end

function request:setService( service )
  self.service = service
end

function request:setRegion( region )
  self.region = region
end

function request:setPayload( payload )
  self.payload = payload or ""
end
--method,path,query,host,headers,service,region,payload,contentSha
--s3 specific
function request:setContentSha( content )
  self.contentSha = content or ""
end

function request:send( content, listener )

  local params = {
    aws_key = self.aws_key,
    aws_secret = self.aws_secret,

    aws_service = self.service,
    aws_region = self.region,

    host = self.host,
    method = self.method,
    path = self.path,

    query = self.query,

    headers = self.headers,
    payload = self.payload,

    contentSha = self.contentSha,

    log = self.log
  }

  AWSAuth:new( params )

  local auth_headers = AWSAuth:getHeaders()

  --make network request
  local url = "https://"..self.host..self.path
  if self.query then
    local query_str = urlencode.table( self.query )
    --local query_str = table.concat(self.query, "&")
    url = url.."?"..query_str
  end
  
  local req_params = {
    headers = auth_headers,
    body = content or self.payload
  }

  network.request(url, self.method, listener, req_params)

end

function request:upload( content, listener )

  local params = {
    aws_key = self.aws_key,
    aws_secret = self.aws_secret,

    aws_service = self.service,
    aws_region = self.region,

    host = self.host,
    method = self.method,
    path = self.path,

    headers = self.headers,
    payload = self.payload,

    contentSha = self.contentSha,

    log = self.log
  }

  AWSAuth:new( params )

  local auth_headers = AWSAuth:getHeaders()

  --make upload request

  local url = "https://"..self.host..self.path

  local req_params = {
    headers = auth_headers,
    body = content,
    bodyType = "binary",
    progress = "upload"
  } 

  network.request(url, self.method, listener, req_params)

end

function request:download( dest_file, dest_path, listener )

  local params = {
    aws_key = self.aws_key,
    aws_secret = self.aws_secret,

    aws_service = self.service,
    aws_region = self.region,

    host = self.host,
    method = self.method,
    path = self.path,

    headers = self.headers,
    payload = self.payload,

    contentSha = self.contentSha,

    log = self.log
  }

  AWSAuth:new( params )

  local auth_headers = AWSAuth:getHeaders()

  --make download request

  local url = "https://"..self.host..self.path

  local req_params = {
    headers = auth_headers,
    body = self.payload,
    response = {
      filename = dest_file,
      baseDirectory = dest_path
    },
    progress = "download"
  } 

  network.request(url, self.method, listener, req_params)

end

return request