function IptvPlaybackService_Resolve(item as Object) as Object
    target = {
        itemId: Iptv_SafeString(item.id),
        streamUrl: Iptv_SafeString(item.streamUrl),
        mimeType: "",
        headers: {},
        streamFormat: IptvPlaybackService_GuessFormat(item.streamUrl)
    }
    return target
end function

function IptvPlaybackService_GuessFormat(url as Dynamic) as String
    lowered = Iptv_Lower(url)
    if Iptv_Contains(lowered, ".m3u8") then return "hls"
    if Iptv_Contains(lowered, ".mp4") then return "mp4"
    if Iptv_Contains(lowered, ".mp3") then return "mp3"
    return ""
end function
