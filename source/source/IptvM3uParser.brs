function IptvM3uParser_Parse(text as Dynamic, providerId as Dynamic) as Object
    result = {
        items: [],
        guideUrl: "",
        errors: []
    }

    normalized = Iptv_Replace(Iptv_SafeString(text), Chr(13), "")
    lines = Iptv_Split(normalized, Chr(10))
    pending = invalid
    lineNumber = 0

    for each rawLine in lines
        lineNumber = lineNumber + 1
        line = Iptv_Trim(rawLine)
        if line = "" then
        else if Iptv_StartsWith(line, "#EXTM3U") then
            attrs = Iptv_ParseQuotedAttributes(Iptv_Substring(line, 8))
            if attrs.DoesExist("x-tvg-url") then result.guideUrl = attrs["x-tvg-url"]
            if result.guideUrl = "" and attrs.DoesExist("url-tvg") then result.guideUrl = attrs["url-tvg"]
        else if Iptv_StartsWith(line, "#EXTINF:") then
            pending = IptvM3uParser_ParseInfoLine(line, providerId, lineNumber)
        else if Iptv_StartsWith(line, "#") then
        else
            if pending <> invalid then
                pending.streamUrl = line
                result.items.Push(pending)
                pending = invalid
            end if
        end if
    end for

    if pending <> invalid then
        result.errors.Push("Playlist entry is missing a stream URL.")
    end if

    return result
end function

function IptvM3uParser_ParseInfoLine(line as Dynamic, providerId as Dynamic, lineNumber as Integer) as Object
    infoBody = Iptv_Substring(Iptv_SafeString(line), 9)
    commaIdx = 0
    for i = Iptv_Len(infoBody) to 1 step -1
        if Iptv_Substring(infoBody, i, 1) = "," then
            commaIdx = i
            exit for
        end if
    end for

    metaPart = infoBody
    title = "Channel " + lineNumber.ToStr()
    if commaIdx > 0 then
        metaPart = Iptv_Left(infoBody, commaIdx - 1)
        title = Iptv_Trim(Iptv_Substring(infoBody, commaIdx + 1))
    end if

    attrs = Iptv_ParseQuotedAttributes(metaPart)
    groupTitle = "Ungrouped"
    if attrs.DoesExist("group-title") and Iptv_IsNonEmptyString(attrs["group-title"]) then groupTitle = attrs["group-title"]

    tvgId = ""
    tvgName = title
    logo = ""
    if attrs.DoesExist("tvg-id") then tvgId = attrs["tvg-id"]
    if attrs.DoesExist("tvg-name") and Iptv_IsNonEmptyString(attrs["tvg-name"]) then tvgName = attrs["tvg-name"]
    if attrs.DoesExist("tvg-logo") then logo = attrs["tvg-logo"]

    itemId = Iptv_SafeString(providerId) + "::" + lineNumber.ToStr()
    if Iptv_IsNonEmptyString(tvgId) then itemId = Iptv_SafeString(providerId) + "::" + tvgId

    return {
        id: itemId,
        kind: "live",
        title: title,
        logo: logo,
        group: groupTitle,
        streamUrl: "",
        providerId: Iptv_SafeString(providerId),
        metadata: {
            tvgId: tvgId,
            tvgName: tvgName,
            sourceType: "m3u"
        }
    }
end function
