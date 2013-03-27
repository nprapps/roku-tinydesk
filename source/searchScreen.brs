Function showSearchScreen(feed)

    m.feed = feed

    port = CreateObject("roMessagePort")
    screen = CreateObject("roSearchScreen")
    screen.SetBreadcrumbText("", "Search")
    screen.SetMessagePort(port) 

    screen.SetSearchTermHeaderText("Suggestions:")
    screen.SetSearchButtonText("search")
    screen.SetClearButtonEnabled(false)
    
    screen.Show() 

    searchString = invalid

    while true 
        msg = wait(0, screen.GetMessagePort()) 

        if type(msg) = "roSearchScreenEvent"
            if msg.isScreenClosed()
                exit while
            else if msg.isCleared()
                history.Clear()
            else if msg.isPartialResult()
                searchString = msg.GetMessage()
                screen.SetSearchTerms(getSuggestions(searchString))
            else if msg.isFullResult()
                searchString = msg.GetMessage()

                exit while
            endif
        endif
    endwhile 

    return getMatches(searchString)

End Function

Function getSuggestions(searchString)

    lSearchString = LCase(searchString)
    suggestions = []

    for each feedItem in m.feed
        if instr(LCase(feedItem.Title), lSearchString) > 0 then
            suggestions.Push(feedItem.Title)
        end if
    end for

    return suggestions

End Function

Function getMatches(searchString)

    if searchString = invalid or searchString = "" then
        return []
    end if

    lSearchString = LCase(searchString)
    matches = []

    for each feedItem in m.feed
        if instr(LCase(feedItem.Title), lSearchString) > 0 then
            matches.Push(feedItem)
        end if
    end for

    return matches 


End Function

