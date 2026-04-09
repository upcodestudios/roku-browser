function IptvXmltvParser_Parse(text as Dynamic) as Object
    result = {
        programsByChannel: {},
        channelIdByName: {}
    }

    source = Iptv_SafeString(text)
    IptvXmltvParser_ReadChannels(source, result)
    IptvXmltvParser_ReadProgrammes(source, result)
    return result
end function

sub IptvXmltvParser_ReadChannels(source as String, result as Object)
    cursor = 1
    while true
        startIdx = Iptv_Instr(cursor, source, "<channel")
        if startIdx = 0 then exit while

        openEnd = Iptv_Instr(startIdx, source, ">")
        closeIdx = Iptv_Instr(openEnd, source, "</channel>")
        if openEnd = 0 or closeIdx = 0 then exit while

        attrsText = Iptv_Substring(source, startIdx + 8, openEnd - startIdx - 8)
        attrs = Iptv_ParseQuotedAttributes(attrsText)
        channelId = ""
        if attrs.DoesExist("id") then channelId = attrs["id"]

        body = Iptv_Substring(source, openEnd + 1, closeIdx - openEnd - 1)
        displayName = IptvXmltvParser_ExtractTag(body, "display-name")
        if Iptv_IsNonEmptyString(channelId) and Iptv_IsNonEmptyString(displayName) then
            result.channelIdByName[Iptv_Lower(displayName)] = channelId
        end if

        cursor = closeIdx + 10
    end while
end sub

sub IptvXmltvParser_ReadProgrammes(source as String, result as Object)
    cursor = 1
    while true
        startIdx = Iptv_Instr(cursor, source, "<programme")
        if startIdx = 0 then exit while

        openEnd = Iptv_Instr(startIdx, source, ">")
        closeIdx = Iptv_Instr(openEnd, source, "</programme>")
        if openEnd = 0 or closeIdx = 0 then exit while

        attrsText = Iptv_Substring(source, startIdx + 10, openEnd - startIdx - 10)
        attrs = Iptv_ParseQuotedAttributes(attrsText)
        channelId = ""
        if attrs.DoesExist("channel") then channelId = attrs["channel"]

        body = Iptv_Substring(source, openEnd + 1, closeIdx - openEnd - 1)
        if Iptv_IsNonEmptyString(channelId) then
            program = {
                channelId: channelId,
                title: IptvXmltvParser_ExtractTag(body, "title"),
                startTime: "",
                endTime: "",
                description: IptvXmltvParser_ExtractTag(body, "desc")
            }
            if attrs.DoesExist("start") then program.startTime = attrs["start"]
            if attrs.DoesExist("stop") then program.endTime = attrs["stop"]

            if not result.programsByChannel.DoesExist(channelId) then result.programsByChannel[channelId] = []
            result.programsByChannel[channelId].Push(program)
        end if

        cursor = closeIdx + 12
    end while
end sub

function IptvXmltvParser_ExtractTag(body as Dynamic, tagName as Dynamic) as String
    source = Iptv_SafeString(body)
    openIdx = Iptv_Instr(1, source, "<" + Iptv_SafeString(tagName))
    if openIdx = 0 then return ""
    startOfValue = Iptv_Instr(openIdx, source, ">")
    if startOfValue = 0 then return ""
    closeIdx = Iptv_Instr(startOfValue, source, "</" + Iptv_SafeString(tagName) + ">")
    if closeIdx = 0 then return ""
    return Iptv_StripTags(Iptv_Substring(source, startOfValue + 1, closeIdx - startOfValue - 1))
end function
