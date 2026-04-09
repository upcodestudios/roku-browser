function IptvCatalogService_LoadProvider(provider as Object) as Object
    result = {
        providerId: Iptv_SafeString(provider.id),
        providerTitle: Iptv_SafeString(provider.title),
        channels: [],
        groups: [],
        guideByChannel: {},
        errors: [],
        metadata: {
            sourceKind: Iptv_SafeString(provider.kind),
            supportsMovies: false,
            supportsSeries: false
        }
    }

    if Iptv_Lower(provider.kind) = "xtream" then
        xtream = IptvXtreamClient_LoadLive(provider)
        result.channels = xtream.items
        result.guideByChannel = xtream.guideByChannel
        result.errors = xtream.errors
        result.metadata.supportsMovies = true
        result.metadata.supportsSeries = true
    else
        playlistResponse = Iptv_ReadTextSource(provider.endpoint)
        if not playlistResponse.ok then
            result.errors.Push(IptvCatalogService_FormatSourceError("playlist", playlistResponse))
            return result
        end if

        parsedPlaylist = IptvM3uParser_Parse(playlistResponse.body, provider.id)
        result.channels = parsedPlaylist.items
        for each parseError in parsedPlaylist.errors
            result.errors.Push(parseError)
        end for

        if result.channels.Count() = 0 then
            result.errors.Push("Playlist contained no live channels.")
        end if

        guideUrl = Iptv_SafeString(provider.guideUrl)
        if guideUrl = "" then guideUrl = Iptv_SafeString(parsedPlaylist.guideUrl)

        if guideUrl <> "" then
            guideResponse = Iptv_ReadTextSource(guideUrl)
            if guideResponse.ok then
                parsedGuide = IptvXmltvParser_Parse(guideResponse.body)
                result.guideByChannel = IptvCatalogService_AttachGuide(result.channels, parsedGuide)
            else
                result.errors.Push(IptvCatalogService_FormatSourceError("guide", guideResponse))
            end if
        else
            result.errors.Push("No guide URL was found for this provider.")
        end if
    end if

    result.groups = IptvCatalogService_CollectGroups(result.channels)
    IptvCatalogService_AnnotateChannels(result.channels, result.guideByChannel)
    return result
end function

function IptvCatalogService_FormatSourceError(sourceName as Dynamic, response as Object) as String
    label = Iptv_SafeString(sourceName)
    if label = "" then label = "source"

    if response <> invalid then
        if Iptv_IsNonEmptyString(response.error) then
            return "Unable to load " + label + ": " + Iptv_SafeString(response.error)
        end if
        if response.DoesExist("statusCode") and response.statusCode > 0 then
            return "Unable to load " + label + ": HTTP " + response.statusCode.ToStr()
        end if
    end if

    return "Unable to load " + label + "."
end function

function IptvCatalogService_AttachGuide(channels as Object, parsedGuide as Object) as Object
    guideByChannel = {}
    for each channel in channels
        guideItems = []
        tvgId = ""
        tvgName = Iptv_SafeString(channel.title)
        if channel.metadata.DoesExist("tvgId") then tvgId = Iptv_SafeString(channel.metadata.tvgId)
        if channel.metadata.DoesExist("tvgName") and Iptv_IsNonEmptyString(channel.metadata.tvgName) then tvgName = Iptv_SafeString(channel.metadata.tvgName)

        if tvgId <> "" and parsedGuide.programsByChannel.DoesExist(tvgId) then
            guideItems = parsedGuide.programsByChannel[tvgId]
        else
            lookupKey = Iptv_Lower(tvgName)
            if parsedGuide.channelIdByName.DoesExist(lookupKey) then
                channelId = parsedGuide.channelIdByName[lookupKey]
                if parsedGuide.programsByChannel.DoesExist(channelId) then guideItems = parsedGuide.programsByChannel[channelId]
            end if
        end if

        guideByChannel[channel.id] = guideItems
    end for
    return guideByChannel
end function

function IptvCatalogService_CollectGroups(channels as Object) as Object
    groups = []
    for each channel in channels
        groupTitle = Iptv_SafeString(channel.group)
        if groupTitle = "" then groupTitle = "Ungrouped"
        if not Iptv_ArrayContains(groups, groupTitle) then groups.Push(groupTitle)
    end for
    return groups
end function

sub IptvCatalogService_AnnotateChannels(channels as Object, guideByChannel as Object)
    for each channel in channels
        nowTitle = "Guide unavailable"
        if guideByChannel.DoesExist(channel.id) then
            programs = guideByChannel[channel.id]
            if programs.Count() > 0 then nowTitle = Iptv_SafeString(programs[0].title)
        end if
        channel.metadata.nowTitle = nowTitle
    end for
end sub
