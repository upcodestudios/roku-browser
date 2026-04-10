function IptvProviderStore_LoadState() as Object
    section = CreateObject("roRegistrySection", "roku-iptv")
    providers = IptvProviderStore_ReadArray(section, "providers")
    selectedProviderId = section.Read("selectedProviderId")
    favorites = IptvProviderStore_ReadArray(section, "favorites")
    recents = IptvProviderStore_ReadArray(section, "recents")
    lastWatched = IptvProviderStore_ReadAssoc(section, "lastWatched")

    return {
        providers: providers,
        selectedProviderId: Iptv_SafeString(selectedProviderId),
        favorites: favorites,
        recents: recents,
        lastWatched: lastWatched
    }
end function

sub IptvProviderStore_SaveState(state as Object)
    section = CreateObject("roRegistrySection", "roku-iptv")
    section.Write("providers", FormatJson(state.providers))
    section.Write("selectedProviderId", Iptv_SafeString(state.selectedProviderId))
    section.Write("favorites", FormatJson(state.favorites))
    section.Write("recents", FormatJson(state.recents))
    section.Write("lastWatched", FormatJson(state.lastWatched))
    section.Flush()
end sub

function IptvProviderStore_UpsertProvider(state as Object, provider as Object) as Object
    nextProviders = []
    replaced = false
    for each item in state.providers
        if Iptv_SafeString(item.id) = Iptv_SafeString(provider.id) then
            nextProviders.Push(provider)
            replaced = true
        else
            nextProviders.Push(item)
        end if
    end for
    if not replaced then nextProviders.Push(provider)
    state.providers = nextProviders
    return state
end function

function IptvProviderStore_SetSelectedProvider(state as Object, providerId as Dynamic) as Object
    state.selectedProviderId = Iptv_SafeString(providerId)
    return state
end function

function IptvProviderStore_RefreshBuiltInProvider(state as Object, providerId as Dynamic) as Object
    targetId = Iptv_SafeString(providerId)
    if targetId <> "iptv-org" then return state

    provider = Iptv_DefaultProviderConfig()
    state = IptvProviderStore_UpsertProvider(state, provider)
    if Iptv_SafeString(state.selectedProviderId) = "iptv-org" then
        state.selectedProviderId = provider.id
    end if
    return state
end function

function IptvProviderStore_ToggleFavorite(state as Object, itemId as Dynamic) as Object
    target = Iptv_SafeString(itemId)
    if Iptv_ArrayContains(state.favorites, target) then
        state.favorites = Iptv_ArrayWithout(state.favorites, target)
    else
        state.favorites.Push(target)
    end if
    return state
end function

function IptvProviderStore_RememberRecent(state as Object, itemId as Dynamic) as Object
    target = Iptv_SafeString(itemId)
    if target = "" then return state

    nextRecents = [target]
    for each existingId in state.recents
        if Iptv_SafeString(existingId) <> target then nextRecents.Push(existingId)
        if nextRecents.Count() >= 20 then exit for
    end for
    state.recents = nextRecents
    return state
end function

function IptvProviderStore_RememberLastWatched(state as Object, providerId as Dynamic, itemId as Dynamic) as Object
    state.lastWatched[Iptv_SafeString(providerId)] = Iptv_SafeString(itemId)
    return state
end function

function IptvProviderStore_ReadArray(section as Object, key as Dynamic) as Object
    raw = section.Read(Iptv_SafeString(key))
    parsed = invalid
    if Iptv_IsNonEmptyString(raw) then parsed = ParseJson(raw)
    if parsed = invalid then return []
    if Type(parsed) <> "roArray" and Type(parsed) <> "Array" then return []
    return parsed
end function

function IptvProviderStore_ReadAssoc(section as Object, key as Dynamic) as Object
    raw = section.Read(Iptv_SafeString(key))
    parsed = invalid
    if Iptv_IsNonEmptyString(raw) then parsed = ParseJson(raw)
    if parsed = invalid then return {}
    if Type(parsed) <> "roAssociativeArray" and Type(parsed) <> "AssociativeArray" then return {}
    return parsed
end function

function IptvProviderStore_GetCatalogCache(providerId as Dynamic) as Dynamic
    filePath = IptvProviderStore_CatalogCachePath(providerId)
    if filePath = "" then return invalid

    fileData = Iptv_ReadTextFile(filePath)
    if not fileData.ok or not Iptv_IsNonEmptyString(fileData.body) then return invalid

    parsed = ParseJson(fileData.body)
    if parsed = invalid then return invalid
    if Type(parsed) <> "roAssociativeArray" and Type(parsed) <> "AssociativeArray" then return invalid
    return parsed
end function

sub IptvProviderStore_SaveCatalogCache(providerId as Dynamic, catalog as Object)
    filePath = IptvProviderStore_CatalogCachePath(providerId)
    if filePath = "" or catalog = invalid then return

    snapshot = IptvProviderStore_BuildCatalogSnapshot(catalog)
    if snapshot = invalid then return
    Iptv_WriteTextFile(filePath, FormatJson(snapshot))
end sub

function IptvProviderStore_BuildCatalogSnapshot(catalog as Object) as Dynamic
    if catalog = invalid then return invalid

    metadata = {}
    if catalog.DoesExist("metadata") and catalog.metadata <> invalid then metadata = catalog.metadata
    metadata.cachedAt = Iptv_NowToken()

    return {
        providerId: Iptv_SafeString(catalog.providerId),
        providerTitle: Iptv_SafeString(catalog.providerTitle),
        channels: catalog.channels,
        groups: catalog.groups,
        guideByChannel: catalog.guideByChannel,
        errors: catalog.errors,
        metadata: metadata
    }
end function

function IptvProviderStore_CatalogCachePath(providerId as Dynamic) as String
    targetId = Iptv_Lower(Iptv_Trim(providerId))
    if targetId = "" then return ""

    safeId = ""
    for i = 1 to Iptv_Len(targetId)
        ch = Iptv_Substring(targetId, i, 1)
        if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") then
            safeId = safeId + ch
        else
            safeId = safeId + "-"
        end if
    end for

    while Iptv_Contains(safeId, "--")
        safeId = Iptv_Replace(safeId, "--", "-")
    end while
    if safeId = "" then safeId = "provider"

    return "tmp:/iptv-catalog-" + safeId + ".json"
end function
