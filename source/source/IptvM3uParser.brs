function IptvM3uParser_Parse(text as Dynamic, providerId as Dynamic, itemLimit = 0 as Integer) as Object
    result = {
        items: [],
        guideUrl: "",
        errors: [],
        truncated: false,
        linesScanned: 0
    }

    normalized = Iptv_Replace(Iptv_SafeString(text), Chr(13), "")
    lines = Iptv_Split(normalized, Chr(10))
    state = {
        pending: invalid,
        shouldStop: false
    }
    lineNumber = 0

    for each rawLine in lines
        lineNumber = lineNumber + 1
        result.linesScanned = lineNumber
        IptvM3uParser_ProcessLine(rawLine, providerId, lineNumber, result, state, itemLimit)
        if state.shouldStop then exit for
    end for

    if state.pending <> invalid then
        result.errors.Push("Playlist entry is missing a stream URL.")
    end if

    return result
end function

function IptvM3uParser_ParseFile(filePath as Dynamic, providerId as Dynamic, itemLimit = 0 as Integer, statusTarget = invalid as Dynamic, requestId = 0 as Integer) as Object
    fileData = Iptv_ReadBytesFile(filePath)
    if not fileData.ok or fileData.bytes = invalid then
        return {
            items: [],
            guideUrl: "",
            errors: ["Unable to read the downloaded playlist file."],
            truncated: false,
            linesScanned: 0
        }
    end if

    return IptvM3uParser_ParseBytes(fileData.bytes, providerId, itemLimit, statusTarget, requestId)
end function

function IptvM3uParser_ParseBytes(bytes as Object, providerId as Dynamic, itemLimit = 0 as Integer, statusTarget = invalid as Dynamic, requestId = 0 as Integer) as Object
    result = {
        items: [],
        guideUrl: "",
        errors: [],
        truncated: false,
        linesScanned: 0
    }

    if bytes = invalid then
        result.errors.Push("Playlist bytes were unavailable.")
        return result
    end if

    state = {
        pending: invalid,
        shouldStop: false,
        lastPublishedLine: 0,
        lastPublishedChannels: 0,
        lastPartialChannels: 0,
        groupsByName: {},
        groupOrder: []
    }
    lineBytes = CreateObject("roByteArray")
    byteCount = bytes.Count()

    for i = 0 to byteCount - 1
        nextByte = bytes[i]
        if nextByte = 13 then
        else if nextByte = 10 then
            result.linesScanned = result.linesScanned + 1
            IptvM3uParser_ProcessLine(lineBytes.ToAsciiString(), providerId, result.linesScanned, result, state, itemLimit)
            IptvM3uParser_MaybePublishProgress(statusTarget, requestId, providerId, result, state, false)
            IptvM3uParser_MaybePublishPartial(statusTarget, requestId, providerId, result, state, false)
            lineBytes = CreateObject("roByteArray")
            if state.shouldStop then exit for
        else
            lineBytes.Push(nextByte)
        end if
    end for

    if not state.shouldStop and lineBytes.Count() > 0 then
        result.linesScanned = result.linesScanned + 1
        IptvM3uParser_ProcessLine(lineBytes.ToAsciiString(), providerId, result.linesScanned, result, state, itemLimit)
    end if

    IptvM3uParser_MaybePublishProgress(statusTarget, requestId, providerId, result, state, true)
    IptvM3uParser_MaybePublishPartial(statusTarget, requestId, providerId, result, state, true)

    if state.pending <> invalid then
        result.errors.Push("Playlist entry is missing a stream URL.")
    end if

    return result
end function

sub IptvM3uParser_ProcessLine(rawLine as Dynamic, providerId as Dynamic, lineNumber as Integer, result as Object, state as Object, itemLimit as Integer)
    line = Iptv_Trim(rawLine)
    if line = "" then
        return
    else if Iptv_StartsWith(line, "#EXTM3U") then
        attrs = Iptv_ParseQuotedAttributes(Iptv_Substring(line, 8))
        if attrs.DoesExist("x-tvg-url") then result.guideUrl = attrs["x-tvg-url"]
        if result.guideUrl = "" and attrs.DoesExist("url-tvg") then result.guideUrl = attrs["url-tvg"]
        return
    else if Iptv_StartsWith(line, "#EXTINF:") then
        state.pending = IptvM3uParser_ParseInfoLine(line, providerId, lineNumber)
        return
    else if Iptv_StartsWith(line, "#") then
        return
    end if

    if state.pending <> invalid then
        state.pending.streamUrl = line
        result.items.Push(state.pending)
        groupTitle = Iptv_SafeString(state.pending.group)
        if groupTitle = "" then groupTitle = "Ungrouped"
        if not state.groupsByName.DoesExist(groupTitle) then
            state.groupsByName[groupTitle] = true
            state.groupOrder.Push(groupTitle)
        end if
        state.pending = invalid
        if itemLimit > 0 and result.items.Count() >= itemLimit then
            result.truncated = true
            state.shouldStop = true
        end if
    end if
end sub

sub IptvM3uParser_MaybePublishProgress(statusTarget as Dynamic, requestId as Integer, providerId as Dynamic, result as Object, state as Object, force as Boolean)
    if statusTarget = invalid then return

    linesDelta = result.linesScanned - state.lastPublishedLine
    channelCount = result.items.Count()
    channelDelta = channelCount - state.lastPublishedChannels

    if not force and linesDelta < 500 and channelDelta < 25 then return

    state.lastPublishedLine = result.linesScanned
    state.lastPublishedChannels = channelCount
    message = "Parsing playlist: " + result.linesScanned.ToStr() + " lines scanned, " + channelCount.ToStr() + " channels found."
    Iptv_PublishTaskStatus(statusTarget, requestId, providerId, "parsing_playlist_progress", message, result.linesScanned, channelCount)
end sub

sub IptvM3uParser_MaybePublishPartial(statusTarget as Dynamic, requestId as Integer, providerId as Dynamic, result as Object, state as Object, force as Boolean)
    if statusTarget = invalid then return

    channelCount = result.items.Count()
    batchCount = channelCount - state.lastPartialChannels
    if channelCount <= 0 or batchCount <= 0 then return
    publishThreshold = 100
    if state.lastPartialChannels = 0 then publishThreshold = 25
    if not force and batchCount < publishThreshold then return

    batchChannels = []
    for i = state.lastPartialChannels to channelCount - 1
        batchChannels.Push(result.items[i])
    end for

    groups = []
    for each groupTitle in state.groupOrder
        groups.Push(groupTitle)
    end for

    message = "Parsed " + channelCount.ToStr() + " channels so far."
    payload = {
        requestId: requestId,
        providerId: Iptv_SafeString(providerId),
        stage: "parsing_playlist_progress",
        message: message,
        isPartial: true,
        resetCatalog: state.lastPartialChannels = 0,
        batchChannels: batchChannels,
        groups: groups,
        linesScanned: result.linesScanned,
        channelsFound: channelCount
    }
    Iptv_PublishTaskPartial(statusTarget, payload)
    state.lastPartialChannels = channelCount
end sub

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
