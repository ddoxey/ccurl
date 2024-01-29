#!/bin/bash

export CURL="$(which curl)"
export D2U="$(which dos2unix || which cat)"

if [[ -z $CCURL_CACHE ]]
then
    export CCURL_CACHE="${HOME}/.cache/ccurl"
fi

if [[ -z $CCURL_CACHE_TIMEOUT ]]
then
    export CCURL_CACHE_TIMEOUT=31536000  # one year
fi


function ccurl()
{
    local _c _r _z

    if [[ -t 1 ]]
    then
        _c="\033[36;1m"
        _r="\033[31;1m"
        _z="\033[0m"
    fi

    if [[ -z $CURL || ! -x "$CURL" ]]
    then
        echo -e "${_r}curl exectuable not found${_z}" >&2
        return 1
    fi

    local cache="$CCURL_CACHE/$(md5sum <<< "$@" | awk '{print $1}').data"

    if [[ -f $cache ]]
    then
        if [[ "$CCURL_CACHE_TIMEOUT" =~ ^[0-9]+$ ]]
        then
            local now="$(date '+%s')"
            local st_mtime=$now
            eval "$(stat -s "$cache" | awk '{print $10}')"
            local age=$(( $now - $st_mtime ))
            if [[ $age -ge $CCURL_CACHE_TIMEOUT ]]
            then
                rm -f "$cache"
            fi
        elif [[ "$CCURL_CACHE_TIMEOUT" == "auto" ]]
        then
            local url="$(grep -m 1 '^curl[ ]' "$cache" |
                         sed 's|^.*[ ]\([a-z]*://[^ ]*\).*$|\1|'
                        )"
            if [[ -n $url ]]
            then
                local fresh_headers="$CCURL_CACHE/$$.headers"
                if $CURL -L "$url" -D "$fresh_headers" -I >/dev/null 2>&1
                then
                    for header in 'etag' 'last-modifed'
                    do
                        local value="$(grep -m 1 "^${header}:" "$cache")"
                        if ! grep -q "^${value}" "$fresh_headers"
                        then
                            rm -f "$cache"
                            break
                        fi
                    done
                else
                    rm -f "$cache"
                fi
                rm -f "$fresh_headers"
            else
                rm -f "$cache"
            fi
        fi
    fi

    if [[ ! -s "$cache" ]]
    then
        if [[ ! -d "$CCURL_CACHE" ]]
        then
            mkdir -p "$CCURL_CACHE" || return 1
        fi

        if $CURL "$@" -o "${cache}.tmp" -D "${cache}.headers"
        then
            echo "curl $@" > "$cache"
            cat "${cache}.headers" | $D2U >> "$cache"
            if [[ -f "${cache}.tmp" ]]
            then
                local line_n="$((2 + $(wc -l "$cache" | awk '{print $1}')))"
                local content_n="$(wc -l "${cache}.tmp" | awk '{print $1}')"
                echo "RANGE:${line_n},$(( $line_n + $content_n ))" >> "$cache"
                cat "${cache}.tmp" >> "$cache"
                rm -f "${cache}.tmp"
            fi
            echo -e "${_c}created: $cache${_z}"

        elif [[ -s "${cache}.headers" ]]
        then
            echo -e "${_r}$(cat "${cache}.headers")${_z}"
        fi
    fi

    if [[ -s "$cache" ]]
    then
        echo -e "CACHE: ${_r}${cache}${_z}" >&2
        local range=$(awk -F: '/^RANGE:/{print $2; exit}' "$cache")
        if [[ -n $range ]]
        then
            sed -n "${range}p" "$cache"
        else
            cat "$cache"
        fi
    else
        return 1
    fi

    return 0
}


if [[ $(caller | awk '{print $1}') -eq 0 ]]; then ccurl "$@"; fi
