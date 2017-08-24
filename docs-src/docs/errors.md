If an error occurs, all listener events contain up to three keys with the error information.

|Key|Description|
|---|-----------|
|error|An string based error code.|
|message|A human readable error message.|
|status|The numerical status code returned from the network request.|

!!! note
    The __message__ and __status__ keys can possibly be _nil_.

__Example Listener__

```lua
local function onResponse( evt )
  if evt.error then
    print(evt.error, evt.message, evt.status)
  else
    --no errors
  end
end
```