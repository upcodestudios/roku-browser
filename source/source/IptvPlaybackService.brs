function IptvPlaybackService_Resolve(item as Object) as Object
    streamUrl = Iptv_SafeString(item.streamUrl)
    target = {
        itemId: Iptv_SafeString(item.id),
        streamUrl: streamUrl,
        mimeType: "",
        headers: {},
        streamFormat: IptvPlaybackService_GuessFormat(streamUrl),
        resolvedBy: "extension"
    }

    if target.streamFormat = "" and Iptv_StartsWith(Iptv_Lower(streamUrl), "https://") then
        if Iptv_Contains(Iptv_Lower(streamUrl), "/master") or Iptv_Contains(Iptv_Lower(streamUrl), "/playlist") then
            target.streamFormat = "hls"
            target.resolvedBy = "path-hint"
        end if
    end if

    return target
end function

function IptvPlaybackService_GuessFormat(url as Dynamic) as String
    lowered = Iptv_Lower(url)
    if Iptv_Contains(lowered, ".m3u8") then return "hls"
    if Iptv_Contains(lowered, ".mp4") then return "mp4"
    if Iptv_Contains(lowered, ".mp3") then return "mp3"
    return ""
end function
