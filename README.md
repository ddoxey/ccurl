# ccurl
Caching Bash wrapper for curl

## Motivation
Prevent fetching the same content multiple times by caching the fetched content locally. 
All arguments passed to `ccurl` are passed directly to the underlying `curl` call.

## Install
```
git clone git@github.com:ddoxey/ccurl.git
ln -s "$(pwd)/ccurl/ccurl.sh" "${HOME}/bin/ccurl"
```
(Or something to that effect.)

## Usage
`ccurl https://www.ucsd.edu/`

NOTE: The first line of content will be emitted to stderr and will be "CACHE: " prefixing the full path to the cache file. To capture this in a calling Bash script, the usage might look something like the following.
```
#!/bin/bash

source "${HOME}/bin/ccurl"

cache=$(ccurl https://www.ucsd.edu/ 2>&1 >/dev/null | sed 's/^CACHE: //')

grep '<title>' "$cache"
```
Yes, it's not lost on the author that this is a little on the awkward side. However, all of the arguments passed to `ccurl` are forwarded directly to `curl` and it didn't seem worth the additional work to make `ccurl` specific arguments that would need to be filtered out. (Perhaps another function that only emits the filename would be good. Maybe later.)

## Environment Variables
```
export CCACHE_CACHE="${HOME}/.cache/ccurl"  # default
export CCACHE_CACHE_TIMEOUT=31536000  # 1 year default
```
`ccurl` will attempt to create the `$CCACHE_CACHE` directory if it doesn't exist.
When cached content reaches `$CCACHE_CACHE_TIMEOUT` seconds old it will be overwritten with fresh content on the next call.
If `$CCACHE_CACHE_TIMEOUT` is set to "auto" then a fresh set of headers is fetched and the `etag` and `last-modified` headers are compared with cache and the cache will be cleared if there is a mismatch.
