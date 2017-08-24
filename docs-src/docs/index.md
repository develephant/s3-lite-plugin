![logo](imgs/logo256.png)

# Amazon S3 Lite

___Secure file transfers for your [Corona](https://coronalabs.com) games and applications using [Amazon S3](https://aws.amazon.com/s3/).___

## Get The Plugin

If you don't already have it, get the __S3 Lite__ plugin from the __[Corona Marketplace](https://marketplace.coronalabs.com/plugin/s3-lite)__.


## Adding The Plugin

Add the plugin by adding an entry to the __plugins__ table of __build.settings__ file:

```
settings =
{
    plugins =
    {
        ["plugin.s3-lite"] =
        {
            publisherId = "com.develephant"
        },
    },
}
```