function IptvXtreamClient_LoadLive(provider as Object) as Object
    result = {
        items: [],
        groups: [],
        guideByChannel: {},
        errors: [],
        metadata: {
            moviesSupported: true,
            seriesSupported: true
        }
    }

    base = Iptv_Trim(provider.endpoint)
    if Iptv_EndsWith(base, "/") then base = Iptv_Left(base, Iptv_Len(base) - 1)

    categoryResponse = Iptv_ReadTextSource(IptvXtreamClient_BuildApiUrl(base, provider.username, provider.password, "get_live_categories"))
    streamsResponse = Iptv_ReadTextSource(IptvXtreamClient_BuildApiUrl(base, provider.username, provider.password, "get_live_streams"))

    categories = []
    if categoryResponse.ok then
        parsedCategories = ParseJson(categoryResponse.body)
        if parsedCategories <> invalid then categories = parsedCategories
    else
        result.errors.Push("Unable to load Xtream live categories.")
    end if

    categoryById = {}
    for each category in categories
        categoryId = Iptv_SafeString(category.category_id)
        categoryName = Iptv_SafeString(category.category_name)
        if categoryId <> "" then categoryById[categoryId] = categoryName
    end for

    if not streamsResponse.ok then
        result.errors.Push("Unable to load Xtream live streams.")
        return result
    end if

    parsedStreams = ParseJson(streamsResponse.body)
    if parsedStreams = invalid then
        result.errors.Push("Xtream returned invalid JSON.")
        return result
    end if

    for each stream in parsedStreams
        streamId = Iptv_SafeString(stream.stream_id)
        if streamId = "" then streamId = Iptv_SafeString(stream.num)

        groupTitle = "Ungrouped"
        categoryId = Iptv_SafeString(stream.category_id)
        if categoryById.DoesExist(categoryId) and Iptv_IsNonEmptyString(categoryById[categoryId]) then groupTitle = categoryById[categoryId]

        ext = Iptv_SafeString(stream.container_extension)
        if ext = "" then ext = "m3u8"

        streamUrl = base + "/live/" + Iptv_SafeString(provider.username) + "/" + Iptv_SafeString(provider.password) + "/" + streamId + "." + ext
        item = {
            id: Iptv_SafeString(provider.id) + "::" + streamId,
            kind: "live",
            title: Iptv_SafeString(stream.name),
            logo: Iptv_SafeString(stream.stream_icon),
            group: groupTitle,
            streamUrl: streamUrl,
            providerId: Iptv_SafeString(provider.id),
            metadata: {
                tvgId: Iptv_SafeString(stream.epg_channel_id),
                tvgName: Iptv_SafeString(stream.name),
                sourceType: "xtream",
                streamId: streamId
            }
        }
        result.items.Push(item)
    end for

    return result
end function

function IptvXtreamClient_BuildApiUrl(base as Dynamic, username as Dynamic, password as Dynamic, action as Dynamic) as String
    return Iptv_SafeString(base) + "/player_api.php?username=" + Iptv_SafeString(username) + "&password=" + Iptv_SafeString(password) + "&action=" + Iptv_SafeString(action)
end function
