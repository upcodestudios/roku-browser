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
