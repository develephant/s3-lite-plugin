-- #########################################################################
-- # AWS Authentication for Corona
-- # Copyright 2017 C. Byerley (develephant.com)
-- # Licensed under the Apache License, Version 2.0 (the "License");
-- # you may not use this file except in compliance with the License.
-- # You may obtain a copy of the License at: 
-- # http://www.apache.org/licenses/LICENSE-2.0
-- # Unless required by applicable law or agreed to in writing, software
-- # distributed under the License is distributed on an "AS IS" BASIS,
-- # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- # See the License for the specific language governing permissions and
-- # limitations under the License.
-- #########################################################################

local os = require('os')
local crypto = require('crypto')

local urlencode = require("plugin.s3-lite.urlencode")

local m = {}

local function trim( str )
  return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
end

function m:new( options )
    local options = options or {}

    self.opts =  
    {
        aws_key = nil,
        aws_secret = nil,

        aws_service = "iam",
        aws_region = "us-east-1",

        method = "GET",
        host = "iam.amazonaws.com",
        path = "/",
        query = nil,

        payload = "",

        content_type = "text/plain",

        headers = { },

        contentSha = nil, --s3 specific

        log = nil
    }

    --merge options
    for option, value in pairs( options ) do 
        self.opts[option] = value
    end

    self.amz_date = nil
    self.amz_timestamp = nil
    self.path = nil
    self.query_str = nil
    self.canonical_headers = nil
    self.signed_headers = nil
    self.signed_payload = nil
    self.signed_canonical_request = nil
    self.role = nil
    self.string_to_sign = nil
    self.signing_key = nil
    self.signature = nil
    self.authorization = nil

end

function m:log( ... )
    if self.opts.log then
        print( ... )
    end
end

function m:hmac(data, key, raw)
    return crypto.hmac( crypto.sha256, data, key, raw )
end

function m:digest( data )
    return crypto.digest( crypto.sha256, data )
end

function m:gen_date_and_timestamp()
    local gmt_time = os.time(os.date('*t'))
    self.amz_date = os.date('!%Y%m%d', gmt_time)
    self.amz_timestamp = os.date('!%Y%m%dT%H%M%SZ', gmt_time)

    -- testers
    -- self.amz_date = "20130524"
    -- self.amz_timestamp = "20130524T000000Z"
end

function m:gen_default_headers()
    self.opts.headers["Host"] = self.opts.host
    self.opts.headers["X-Amz-Date"] = self.amz_timestamp
end

function m:gen_content_sha_header() --s3
  if self.opts.contentSha then
    self.opts.headers["X-Amz-Content-Sha256"] = string.lower(self:digest(self.opts.contentSha))
  end
end

function m:gen_path()
  local path = self.opts.path or "/"
  self.path = urlencode.path( path )
end

function m:gen_query_string()
    if self.opts.query then
      self.query_str = urlencode.table( self.opts.query )
    else
      self.query_str = ""
    end
    --self:log( self.query_str )
end

function m:gen_canonical_headers()
    local headers = self.opts.headers

    local canonical_headers = {}
    local signed_headers = {}

    for header, value in pairs( headers ) do 
        table.insert(canonical_headers, string.lower(header)..':'..trim(value))
        table.insert(signed_headers, string.lower(header))
    end

    table.sort( canonical_headers )
    table.sort( signed_headers )

    self.canonical_headers = table.concat( canonical_headers, '\n' )

    self.signed_headers = table.concat( signed_headers, ';' )

    --self:log( self.canonical_headers )
    --self:log( self.signed_headers )
end

function m:gen_signed_payload()
    self.signed_payload = string.lower( self:digest( self.opts.payload ) )
    --self:log( self.signed_payload )
end

function m:gen_canonical_request()
    local request = 
    {
        self.opts.method,
        self.path,
        self.query_str,
        self.canonical_headers,
        '', --clean line (required)
        self.signed_headers,
        self.signed_payload
    }

    local canonical_request = table.concat( request, '\n' )

    self:log("== Canonical Request ==============================================")
    self:log( canonical_request )
    self:log("===================================================================")

    self.signed_canonical_request = string.lower( self:digest( canonical_request ) )

    self:log("== Signed Canonical Request =======================================")
    self:log( self.signed_canonical_request )
    self:log("===================================================================")
end

function m:gen_role()
    local role = 
    {
        self.amz_date,
        self.opts.aws_region,
        self.opts.aws_service,
        'aws4_request'
    }

    self.role = table.concat( role, '/' )

    --self:log( self.role )
end

function m:gen_string_to_sign()

    local string_to_sign = 
    {
        "AWS4-HMAC-SHA256",
        self.amz_timestamp,
        self.role,
        self.signed_canonical_request
    }

    self.string_to_sign = table.concat( string_to_sign, '\n' )

    self:log("== String To Sign =================================================")
    self:log( self.string_to_sign )
    self:log("===================================================================")
end

function m:gen_signing_key()
    local secret = 'AWS4'..self.opts.aws_secret

    local key = self:hmac( self.amz_date, secret, true )
    key = self:hmac( self.opts.aws_region, key, true )
    key = self:hmac( self.opts.aws_service, key, true )
    key = self:hmac( 'aws4_request', key, true )

    self.signing_key = key --binary
end

function m:gen_signature()
    self.signature = self:hmac( self.string_to_sign, self.signing_key )
    self:log("== Generated Signature ============================================")
    self:log( self.signature )
    self:log("===================================================================")
end

function m:gen_auth_header()
    self:gen_date_and_timestamp()
    self:gen_default_headers()
    self:gen_content_sha_header() --s3
    self:gen_path()
    self:gen_query_string()
    self:gen_canonical_headers()
    self:gen_signed_payload()
    self:gen_canonical_request()
    self:gen_role()
    self:gen_string_to_sign()
    self:gen_signing_key()
    self:gen_signature()

    self.authorization = 'AWS4-HMAC-SHA256 Credential='..self.opts.aws_key..'/'..self.role..',SignedHeaders='..self.signed_headers..',Signature='..self.signature

    self:log("== Authorization ==================================================")
    self:log( self.authorization )
    self:log("===================================================================")
end

function m:getHeaders()
    self:gen_auth_header()
    local headers = self.opts.headers
    headers["Authorization"] = self.authorization
    table.sort( headers )
    return headers
end


return m