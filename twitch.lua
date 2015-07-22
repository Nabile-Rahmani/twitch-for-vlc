-- Twitch for VLC.

--[[

The MIT License (MIT)

Copyright (c) 2015 Nabile Rahmani

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

--]]

local json = require("dkjson")

function probe()
    if not vlc.access:match("http") then
        return false
    end

    return string.match(vlc.path:match("([^/]+)"), "[%w+.]?twitch.tv")
end

function parse()
    local channel = vlc.path:match("[%w+.]?twitch.tv/([a-z0-9_]+)")

    if string.match(vlc.path, "[%w+.]?twitch.tv/[a-z0-9_]+/./[0-9]+") then
        local videoID = vlc.path:match("[%w+.]?twitch.tv/[a-z0-9_]+/./([0-9]+)")
        local broadcastType = string.match(vlc.path, "[%w+.]?twitch.tv/[a-z0-9_]+/(.)")

        if broadcastType == "v" then
            local url = "https://api.twitch.tv/api/vods/" .. videoID .. "/access_token"
            local data = json.decode(vlc.stream(url):readline(), 1, nil)

            return { { path = "http://usher.twitch.tv/vod/" .. videoID .. ".m3u8?nauth=" .. data.token .. "&nauthsig=" .. data.sig, title = channel .. "'s past broadcast" } }
        else
            local url = "https://api.twitch.tv/api/videos/a" .. videoID
            local data = json.decode(vlc.stream(url):readline(), 1, nil)
            local playlist = { }

            for key, value in pairs(data.chunks.live) do
                table.insert(playlist, { path = value.url, title = channel .. "'s past broadcast (part " .. key .. ")", arturl = data.preview })
            end

            return playlist
        end
    elseif string.match(vlc.path, "[%w+.]?twitch.tv/[a-z0-9_]+") then
        local url = "http://api.twitch.tv/api/channels/" .. channel .. "/access_token"
        local data = json.decode(vlc.stream(url):readline(), 1, nil)

        return { { path = "http://usher.twitch.tv/api/channel/hls/" .. channel .. ".m3u8?token=" .. data.token .. "&sig=" .. data.sig, title = channel .. "'s stream" } }
    end
end
