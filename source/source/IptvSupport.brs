function Iptv_SafeString(value as Dynamic) as String
    if value = invalid then return ""

    valueType = Type(value)
    if valueType = "String" or valueType = "roString" then return value

    if valueType = "Integer" or valueType = "roInt" or valueType = "roInteger" or valueType = "LongInteger" or valueType = "roLongInteger" then
        return value.ToStr()
    end if

    if valueType = "Float" or valueType = "roFloat" or valueType = "Double" or valueType = "roDouble" then
        return value.ToStr()
    end if

    if valueType = "Boolean" or valueType = "roBoolean" then
        if value then return "true"
        return "false"
    end if

    return FormatJson(value)
end function

function Iptv_BytesFromString(value as Dynamic) as Object
    bytes = CreateObject("roByteArray")
    bytes.FromAsciiString(Iptv_SafeString(value))
    return bytes
end function

function Iptv_Len(value as Dynamic) as Integer
    return Iptv_BytesFromString(value).Count()
end function

function Iptv_IsWhitespaceByte(byteValue as Integer) as Boolean
    return byteValue = 9 or byteValue = 10 or byteValue = 13 or byteValue = 32
end function

function Iptv_Trim(value as Dynamic) as String
    text = Iptv_SafeString(value)
    bytes = Iptv_BytesFromString(text)
    if bytes.Count() = 0 then return ""

    startIndex = 0
    endIndex = bytes.Count() - 1

    while startIndex <= endIndex and Iptv_IsWhitespaceByte(bytes[startIndex])
        startIndex = startIndex + 1
    end while

    while endIndex >= startIndex and Iptv_IsWhitespaceByte(bytes[endIndex])
        endIndex = endIndex - 1
    end while

    if startIndex > endIndex then return ""
    return Iptv_Substring(text, startIndex + 1, endIndex - startIndex + 1)
end function

function Iptv_TransformCase(value as Dynamic, makeUpper as Boolean) as String
    bytes = Iptv_BytesFromString(value)
    result = CreateObject("roByteArray")

    for each byteValue in bytes
        nextByte = byteValue
        if makeUpper then
            if byteValue >= 97 and byteValue <= 122 then nextByte = byteValue - 32
        else
            if byteValue >= 65 and byteValue <= 90 then nextByte = byteValue + 32
        end if
        result.Push(nextByte)
    end for

    return result.ToAsciiString()
end function

function Iptv_Lower(value as Dynamic) as String
    return Iptv_TransformCase(value, false)
end function

function Iptv_Upper(value as Dynamic) as String
    return Iptv_TransformCase(value, true)
end function

function Iptv_Substring(value as Dynamic, startIndex as Integer, charCount = invalid as Dynamic) as String
    text = Iptv_SafeString(value)
    bytes = Iptv_BytesFromString(text)
    total = bytes.Count()
    if total = 0 then return ""

    resolvedStart = startIndex
    if resolvedStart < 1 then resolvedStart = 1
    if resolvedStart > total then return ""

    maxCount = total - resolvedStart + 1
    resolvedCount = maxCount
    if charCount <> invalid then
        resolvedCount = charCount
        if resolvedCount < 0 then resolvedCount = 0
        if resolvedCount > maxCount then resolvedCount = maxCount
    end if

    if resolvedCount <= 0 then return ""

    result = CreateObject("roByteArray")
    lastIndex = resolvedStart + resolvedCount - 2
    for i = resolvedStart - 1 to lastIndex
        result.Push(bytes[i])
    end for
    return result.ToAsciiString()
end function

function Iptv_Left(value as Dynamic, count as Integer) as String
    if count <= 0 then return ""
    return Iptv_Substring(value, 1, count)
end function

function Iptv_Right(value as Dynamic, count as Integer) as String
    total = Iptv_Len(value)
    if count <= 0 then return ""
    if count >= total then return Iptv_SafeString(value)
    return Iptv_Substring(value, total - count + 1, count)
end function

function Iptv_Instr(startIndex as Integer, value as Dynamic, needle as Dynamic) as Integer
    haystack = Iptv_BytesFromString(value)
    pattern = Iptv_BytesFromString(needle)
    hayCount = haystack.Count()
    patternCount = pattern.Count()

    resolvedStart = startIndex
    if resolvedStart < 1 then resolvedStart = 1

    if patternCount = 0 then return resolvedStart
    if hayCount = 0 or resolvedStart > hayCount then return 0
    if patternCount > hayCount then return 0

    lastStart = hayCount - patternCount
    for i = resolvedStart - 1 to lastStart
        matched = true
        for j = 0 to patternCount - 1
            if haystack[i + j] <> pattern[j] then
                matched = false
                exit for
            end if
        end for
        if matched then return i + 1
    end for

    return 0
end function

function Iptv_StartsWith(value as Dynamic, prefix as Dynamic) as Boolean
    text = Iptv_SafeString(value)
    lead = Iptv_SafeString(prefix)
    if Iptv_Len(lead) > Iptv_Len(text) then return false
    return Iptv_Left(text, Iptv_Len(lead)) = lead
end function

function Iptv_EndsWith(value as Dynamic, suffix as Dynamic) as Boolean
    text = Iptv_SafeString(value)
    tail = Iptv_SafeString(suffix)
    if Iptv_Len(tail) > Iptv_Len(text) then return false
    return Iptv_Right(text, Iptv_Len(tail)) = tail
end function

function Iptv_Contains(value as Dynamic, needle as Dynamic) as Boolean
    return Iptv_Instr(1, value, needle) > 0
end function

function Iptv_Replace(value as Dynamic, needle as Dynamic, replacement as Dynamic) as String
    source = Iptv_SafeString(value)
    target = Iptv_SafeString(needle)
    substitute = Iptv_SafeString(replacement)
    if target = "" then return source

    result = ""
    searchFrom = 1
    targetLen = Iptv_Len(target)

    while true
        matchIndex = Iptv_Instr(searchFrom, source, target)
        if matchIndex = 0 then
            result = result + Iptv_Substring(source, searchFrom)
            exit while
        end if

        result = result + Iptv_Substring(source, searchFrom, matchIndex - searchFrom)
        result = result + substitute
        searchFrom = matchIndex + targetLen
    end while

    return result
end function

function Iptv_Split(value as Dynamic, delimiter as Dynamic) as Object
    source = Iptv_SafeString(value)
    separator = Iptv_SafeString(delimiter)
    if separator = "" then return [source]

    parts = []
    searchFrom = 1
    separatorLen = Iptv_Len(separator)

    while true
        matchIndex = Iptv_Instr(searchFrom, source, separator)
        if matchIndex = 0 then
            parts.Push(Iptv_Substring(source, searchFrom))
            exit while
        end if

        parts.Push(Iptv_Substring(source, searchFrom, matchIndex - searchFrom))
        searchFrom = matchIndex + separatorLen
    end while

    return parts
end function

function Iptv_IsNonEmptyString(value as Dynamic) as Boolean
    return Iptv_Trim(value) <> ""
end function

function Iptv_HostLabel(value as Dynamic) as String
    text = Iptv_SafeString(value)
    if Iptv_StartsWith(text, "pkg:/") then return "Sample Feed"

    schemeIdx = Iptv_Instr(1, text, "://")
    if schemeIdx = 0 then return text
    startAt = schemeIdx + 3
    slashIdx = Iptv_Instr(startAt, text, "/")
    if slashIdx = 0 then return Iptv_Substring(text, startAt)
    return Iptv_Substring(text, startAt, slashIdx - startAt)
end function

function Iptv_ParseHeaderArray(headers as Dynamic) as Object
    result = {}
    if headers = invalid then return result

    headerType = Type(headers)
    if headerType = "roArray" or headerType = "Array" then
        for each entry in headers
            if Type(entry) = "roString" or Type(entry) = "String" then
                colonIdx = Iptv_Instr(1, entry, ":")
                if colonIdx > 0 then
                    result[Iptv_Lower(Iptv_Left(entry, colonIdx - 1))] = Iptv_Trim(Iptv_Substring(entry, colonIdx + 1))
                end if
            else if Type(entry) = "roAssociativeArray" or Type(entry) = "AssociativeArray" then
                if entry.DoesExist("name") and entry.DoesExist("value") then
                    result[Iptv_Lower(entry.name)] = Iptv_SafeString(entry.value)
                end if
            end if
        end for
    end if

    return result
end function

sub Iptv_PublishTaskStatus(statusTarget as Dynamic, requestId as Integer, providerId as Dynamic, stage as Dynamic, message as Dynamic, linesScanned = invalid as Dynamic, channelsFound = invalid as Dynamic)
    if statusTarget = invalid then return

    payload = {
        requestId: requestId,
        providerId: Iptv_SafeString(providerId),
        stage: Iptv_SafeString(stage),
        message: Iptv_SafeString(message)
    }

    if linesScanned <> invalid then payload.linesScanned = linesScanned
    if channelsFound <> invalid then payload.channelsFound = channelsFound
    statusTarget.status = payload
end sub

sub Iptv_PublishTaskPartial(statusTarget as Dynamic, payload as Object)
    if statusTarget = invalid or payload = invalid then return
    statusTarget.partialResponse = payload
end sub

function Iptv_BuildTempTextPath(source as Dynamic, requestId = 0 as Integer) as String
    hostLabel = Iptv_Lower(Iptv_HostLabel(source))
    if hostLabel = "" then hostLabel = "playlist"

    safeLabel = ""
    for i = 1 to Iptv_Len(hostLabel)
        ch = Iptv_Substring(hostLabel, i, 1)
        if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") then
            safeLabel = safeLabel + ch
        else
            safeLabel = safeLabel + "-"
        end if
    end for

    while Iptv_Contains(safeLabel, "--")
        safeLabel = Iptv_Replace(safeLabel, "--", "-")
    end while
    safeLabel = Iptv_Trim(safeLabel)
    if safeLabel = "" then safeLabel = "playlist"

    return "tmp:/iptv-" + requestId.ToStr() + "-" + safeLabel + ".txt"
end function

function Iptv_ReadBytesFile(path as Dynamic, maxBytes = 0 as Integer) as Object
    result = {
        ok: false,
        bytes: invalid,
        sizeBytes: 0,
        error: ""
    }

    filePath = Iptv_Trim(path)
    if filePath = "" then
        result.error = "Empty file path."
        return result
    end if

    bytes = CreateObject("roByteArray")
    if bytes = invalid or not bytes.ReadFile(filePath) then
        result.error = "Unable to read file."
        return result
    end if

    result.sizeBytes = bytes.Count()
    if maxBytes > 0 and result.sizeBytes > maxBytes then
        result.error = "Downloaded file exceeded the size limit."
        return result
    end if

    result.ok = true
    result.bytes = bytes
    return result
end function

function Iptv_ReadTextFile(path as Dynamic) as Object
    result = {
        ok: false,
        body: "",
        error: ""
    }

    fileData = Iptv_ReadBytesFile(path)
    if not fileData.ok or fileData.bytes = invalid then
        result.error = fileData.error
        return result
    end if

    result.body = fileData.bytes.ToAsciiString()
    result.ok = true
    return result
end function

function Iptv_WriteTextFile(path as Dynamic, text as Dynamic) as Boolean
    filePath = Iptv_Trim(path)
    if filePath = "" then return false

    bytes = CreateObject("roByteArray")
    bytes.FromAsciiString(Iptv_SafeString(text))
    return bytes.WriteFile(filePath)
end function

function Iptv_DownloadTextSourceToTempFile(source as Dynamic, headers = invalid as Dynamic, timeoutMs = 15000 as Integer, requestId = 0 as Integer, maxBytes = 0 as Integer) as Object
    target = Iptv_Trim(source)
    result = {
        ok: false,
        statusCode: 0,
        filePath: "",
        headers: {},
        error: "",
        sizeBytes: 0,
        stage: "playlist_failed"
    }

    if target = "" then
        result.error = "Empty source."
        return result
    end if

    if Iptv_StartsWith(target, "pkg:/") then
        result.filePath = target
        result.ok = true
        result.statusCode = 200
        result.stage = "playlist_downloaded"
        return result
    end if

    tempPath = Iptv_BuildTempTextPath(target, requestId)
    port = CreateObject("roMessagePort")
    transfer = CreateObject("roUrlTransfer")
    transfer.SetPort(port)
    transfer.SetUrl(target)
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.AddHeader("User-Agent", "roku-iptv-prototype/0.1")

    if headers <> invalid then
        for each key in headers
            transfer.AddHeader(key, Iptv_SafeString(headers[key]))
        end for
    end if

    if not transfer.AsyncGetToFile(tempPath) then
        result.error = "Unable to start the playlist request."
        return result
    end if

    msg = wait(timeoutMs, port)
    if msg = invalid then
        result.error = "Playlist request timed out."
        result.stage = "playlist_timed_out"
        return result
    end if

    fileData = Iptv_ReadBytesFile(tempPath, maxBytes)
    if not fileData.ok then
        result.error = fileData.error
        if maxBytes > 0 and fileData.sizeBytes > maxBytes then
            result.stage = "playlist_too_large"
        end if
        return result
    end if

    result.ok = true
    result.statusCode = 200
    result.filePath = tempPath
    result.sizeBytes = fileData.sizeBytes
    result.stage = "playlist_downloaded"
    return result
end function

function Iptv_ReadTextSource(source as Dynamic, headers = invalid as Dynamic, timeoutMs = 15000 as Integer) as Object
    target = Iptv_Trim(source)
    result = {
        ok: false,
        statusCode: 0,
        body: "",
        headers: {},
        error: ""
    }

    if target = "" then
        result.error = "Empty source."
        return result
    end if

    if Iptv_StartsWith(target, "pkg:/") then
        result.body = ReadAsciiFile(target)
        if result.body = invalid or result.body = "" then
            result.error = "Unable to read packaged file."
            return result
        end if
        result.ok = true
        result.statusCode = 200
        return result
    end if

    download = Iptv_DownloadTextSourceToTempFile(target, headers, timeoutMs, 0, 0)
    result.statusCode = download.statusCode
    result.headers = download.headers
    if not download.ok then
        result.error = download.error
        return result
    end if

    fileData = Iptv_ReadBytesFile(download.filePath)
    if not fileData.ok or fileData.bytes = invalid then
        result.error = fileData.error
        return result
    end if

    result.body = fileData.bytes.ToAsciiString()
    if result.body <> invalid and Iptv_IsNonEmptyString(result.body) then
        result.ok = true
    else
        result.error = "Request failed."
    end if

    return result
end function

function Iptv_ParseQuotedAttributes(text as Dynamic) as Object
    result = {}
    raw = Iptv_SafeString(text)
    cursor = 1

    while cursor <= Iptv_Len(raw)
        while cursor <= Iptv_Len(raw)
            ch = Iptv_Substring(raw, cursor, 1)
            if ch = " " or ch = Chr(9) or ch = Chr(10) or ch = Chr(13) or ch = "," then
                cursor = cursor + 1
            else
                exit while
            end if
        end while

        if cursor > Iptv_Len(raw) then exit while

        keyStart = cursor
        while cursor <= Iptv_Len(raw)
            ch = Iptv_Substring(raw, cursor, 1)
            if ch = "=" or ch = " " or ch = Chr(9) or ch = Chr(10) or ch = Chr(13) or ch = "," then exit while
            cursor = cursor + 1
        end while

        key = Iptv_Lower(Iptv_Substring(raw, keyStart, cursor - keyStart))
        if key = "" then exit while

        while cursor <= Iptv_Len(raw) and Iptv_Substring(raw, cursor, 1) <> "="
            ch = Iptv_Substring(raw, cursor, 1)
            if ch <> " " and ch <> Chr(9) and ch <> Chr(10) and ch <> Chr(13) and ch <> "," then exit while
            cursor = cursor + 1
        end while

        value = ""
        if cursor <= Iptv_Len(raw) and Iptv_Substring(raw, cursor, 1) = "=" then
            cursor = cursor + 1
            while cursor <= Iptv_Len(raw)
                ch = Iptv_Substring(raw, cursor, 1)
                if ch = " " or ch = Chr(9) or ch = Chr(10) or ch = Chr(13) then
                    cursor = cursor + 1
                else
                    exit while
                end if
            end while

            if cursor <= Iptv_Len(raw) then
                quote = Iptv_Substring(raw, cursor, 1)
                if quote = Chr(34) or quote = "'" then
                    cursor = cursor + 1
                    valueStart = cursor
                    while cursor <= Iptv_Len(raw) and Iptv_Substring(raw, cursor, 1) <> quote
                        cursor = cursor + 1
                    end while
                    value = Iptv_Substring(raw, valueStart, cursor - valueStart)
                    cursor = cursor + 1
                else
                    valueStart = cursor
                    while cursor <= Iptv_Len(raw)
                        ch = Iptv_Substring(raw, cursor, 1)
                        if ch = " " or ch = Chr(9) or ch = Chr(10) or ch = Chr(13) or ch = "," then exit while
                        cursor = cursor + 1
                    end while
                    value = Iptv_Substring(raw, valueStart, cursor - valueStart)
                end if
            end if
        end if

        result[key] = value
    end while

    return result
end function

function Iptv_DefaultProviderConfig() as Object
    return {
        id: "iptv-org",
        kind: "default",
        title: "IPTV-org",
        endpoint: "https://iptv-org.github.io/iptv/index.m3u",
        username: "",
        password: "",
        guideUrl: "",
        enabled: true,
        options: {
            largeFeed: true,
            initialChannelLimit: 0,
            deferGuide: true,
            requestTimeoutMs: 15000
        }
    }
end function

function Iptv_SampleProviderConfig() as Object
    return {
        id: "sample-feed",
        kind: "default",
        title: "Sample Feed",
        endpoint: "pkg:/data/default-feed.m3u",
        username: "",
        password: "",
        guideUrl: "pkg:/data/default-guide.xml",
        enabled: true,
        options: {
            largeFeed: false,
            initialChannelLimit: 0,
            deferGuide: false,
            requestTimeoutMs: 15000
        }
    }
end function

function Iptv_NewProviderConfig(kind as Dynamic, title as Dynamic, endpoint as Dynamic, username = "" as Dynamic, password = "" as Dynamic, guideUrl = "" as Dynamic) as Object
    baseTitle = Iptv_Trim(title)
    if baseTitle = "" then baseTitle = Iptv_HostLabel(endpoint)
    if baseTitle = "" then baseTitle = "Custom Provider"

    slug = Iptv_Lower(baseTitle)
    slug = Iptv_Replace(slug, " ", "-")
    slug = Iptv_Replace(slug, ".", "-")
    slug = Iptv_Replace(slug, ":", "-")
    slug = Iptv_Replace(slug, "/", "-")

    return {
        id: slug + "-" + Iptv_NowToken(),
        kind: Iptv_Lower(kind),
        title: baseTitle,
        endpoint: Iptv_Trim(endpoint),
        username: Iptv_Trim(username),
        password: Iptv_SafeString(password),
        guideUrl: Iptv_Trim(guideUrl),
        enabled: true,
        options: {
            largeFeed: false,
            initialChannelLimit: 0,
            deferGuide: false,
            requestTimeoutMs: 15000
        }
    }
end function

function Iptv_GetProviderOptions(provider as Object) as Object
    options = {
        largeFeed: false,
        initialChannelLimit: 0,
        deferGuide: false,
        requestTimeoutMs: 15000
    }

    if provider = invalid or not provider.DoesExist("options") or provider.options = invalid then return options

    rawOptions = provider.options
    if rawOptions.DoesExist("largeFeed") then options.largeFeed = Iptv_IsTruthy(rawOptions.largeFeed)
    if rawOptions.DoesExist("initialChannelLimit") then options.initialChannelLimit = Val(Iptv_SafeString(rawOptions.initialChannelLimit))
    if rawOptions.DoesExist("deferGuide") then options.deferGuide = Iptv_IsTruthy(rawOptions.deferGuide)
    if rawOptions.DoesExist("requestTimeoutMs") then
        timeoutValue = Val(Iptv_SafeString(rawOptions.requestTimeoutMs))
        if timeoutValue > 0 then options.requestTimeoutMs = timeoutValue
    end if

    return options
end function

function Iptv_IsTruthy(value as Dynamic) as Boolean
    if value = true then return true
    lowered = Iptv_Lower(value)
    return lowered = "true" or lowered = "1" or lowered = "yes"
end function

function Iptv_NowToken() as String
    dt = CreateObject("roDateTime")
    dt.ToLocalTime()
    return dt.AsSeconds().ToStr()
end function

function Iptv_ArrayContains(items as Object, value as Dynamic) as Boolean
    needle = Iptv_SafeString(value)
    for each item in items
        if Iptv_SafeString(item) = needle then return true
    end for
    return false
end function

function Iptv_ArrayWithout(items as Object, value as Dynamic) as Object
    result = []
    needle = Iptv_SafeString(value)
    for each item in items
        if Iptv_SafeString(item) <> needle then result.Push(item)
    end for
    return result
end function

function Iptv_FormatClock(raw as Dynamic) as String
    text = Iptv_SafeString(raw)
    if Iptv_Len(text) < 12 then return ""
    hourPart = Iptv_Substring(text, 9, 2)
    minutePart = Iptv_Substring(text, 11, 2)
    return hourPart + ":" + minutePart
end function

function Iptv_Truncate(value as Dynamic, maxLen as Integer) as String
    text = Iptv_SafeString(value)
    if maxLen <= 0 then return ""
    if Iptv_Len(text) <= maxLen then return text
    if maxLen <= 3 then return Iptv_Left(text, maxLen)
    return Iptv_Left(text, maxLen - 3) + "..."
end function

function Iptv_DecodeEntities(value as Dynamic) as String
    text = Iptv_SafeString(value)
    text = Iptv_Replace(text, "&amp;", "&")
    text = Iptv_Replace(text, "&lt;", "<")
    text = Iptv_Replace(text, "&gt;", ">")
    text = Iptv_Replace(text, "&quot;", Chr(34))
    text = Iptv_Replace(text, "&apos;", "'")
    text = Iptv_Replace(text, "&#39;", "'")
    text = Iptv_Replace(text, "&nbsp;", " ")
    return text
end function

function Iptv_StripTags(value as Dynamic) as String
    regex = CreateObject("roRegex", "<[^>]+>", "")
    stripped = regex.ReplaceAll(Iptv_SafeString(value), " ")
    stripped = Iptv_Replace(stripped, Chr(10), " ")
    while Iptv_Instr(1, stripped, "  ") > 0
        stripped = Iptv_Replace(stripped, "  ", " ")
    end while
    return Iptv_Trim(Iptv_DecodeEntities(stripped))
end function

function Iptv_NewRowNode(title as Dynamic, meta as Dynamic, key = "" as Dynamic, badge = "" as Dynamic) as Object
    node = CreateObject("roSGNode", "ContentNode")
    node.AddFields({
        title: Iptv_SafeString(title),
        meta: Iptv_SafeString(meta),
        key: Iptv_SafeString(key),
        badge: Iptv_SafeString(badge)
    })
    return node
end function

function Iptv_NewListContent(rows as Object) as Object
    root = CreateObject("roSGNode", "ContentNode")
    for each row in rows
        badge = ""
        if row.DoesExist("badge") then badge = row.badge
        key = ""
        if row.DoesExist("key") then key = row.key
        root.AppendChild(Iptv_NewRowNode(row.title, row.meta, key, badge))
    end for
    return root
end function

function Iptv_EmptyCatalogResponse(message as Dynamic) as Object
    return {
        providerId: "",
        providerTitle: "",
        channels: [],
        groups: [],
        guideByChannel: {},
        errors: [Iptv_SafeString(message)],
        metadata: {}
    }
end function

function Iptv_FindProviderById(providers as Object, providerId as Dynamic) as Dynamic
    target = Iptv_SafeString(providerId)
    for each provider in providers
        if Iptv_SafeString(provider.id) = target then return provider
    end for
    return invalid
end function
