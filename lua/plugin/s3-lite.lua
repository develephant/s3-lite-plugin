local Library = require "CoronaLibrary"

-- Create library
local lib = Library:new{ name='s3-lite', publisherId='com.develephant' }

return setmetatable( lib, { __index = require("plugin.s3-lite.s3") } )
