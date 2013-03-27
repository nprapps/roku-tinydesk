' Setup the grid screen
Function preShowGridScreen() As Object

    port = CreateObject("roMessagePort")
    screen = CreateObject("roGridScreen")
    screen.SetMessagePort(port)

    screen.SetGridStyle("flat-landscape")
    screen.SetDisplayMode("photo-fit")
    
    ' Always setup at least one list (keeps tooltips from appearing in the wrong place)
    screen.SetupLists(1)

    return screen

End Function

' Run the grid screen
Function showGridScreen(screen as Object) as Integer

    m.ALL = 0
    m.RECENT = 1
    m.SEARCH = 2
    m.titles = ["All", "Recently watched", "Search results"]
    m.lists = []

    screen.Show()

    screen.ShowMessage("Retrieving...")

    feed = fetchFeed()
    initLists(screen, feed)

    screen.ClearMessage()

    ' TODO: if there is an unwatched video, play it immediately

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roGridScreenEvent" then
            print "showGridScreen | msg = "; msg.GetMessage() " | index = "; msg.GetIndex()

            if msg.isListItemSelected() then
                selected_list = msg.GetIndex()
                selected_item = msg.GetData()
                feedItem = m.lists[selected_list][selected_item]

                watched = showVideoScreen(feedItem)
                set_last_watched(feedItem)

                if watched and selected_list <> m.WATCHED then
                    mark_as_watched(feedItem)
                end if

                ' Remove vid from recent list if it already exists
                for i = 0 to m.lists[m.RECENT].count() - 1
                    if m.lists[m.RECENT][i].Id = feedItem.Id then
                        m.lists[m.RECENT].delete(i)
                        exit for
                    end if
                end for
                
                ' Add vid to recent list
                m.lists[m.RECENT].unshift(feedItem)

                refreshLists(screen)

                screen.SetFocusedListItem(m.RECENT, 0)
            else if msg.isRemoteKeyPressed() then
                if msg.GetIndex() = 10 then
                    m.lists[m.SEARCH] = showSearchScreen(feed)
                    
                    refreshLists(screen)

                    screen.SetFocusedListItem(m.SEARCH, 0)
                end if
            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while

End Function

' Parse the video feed
function fetchFeed()

    http = NewHttp("http://apps.npr.org/nproku/feed.json")
    feed = http.GetToStringWithRetry()

    return ParseJSON(feed)

end function

' BubbleSort the feed by last watched
Function sortLastWatched(feed)

    swapped = true

    while swapped = true
        swapped = false

        for i = 0 to feed.Count() - 1
            if feed[i + 1] = invalid then
                exit for
            end if

            if feed[i].lastWatched < feed[i + 1].lastWatched then
                temp = feed[i]
                feed[i] = feed[i + 1]
                feed[i + 1] = temp
                swapped = true
            end if
        end for
    end while

    return feed

End Function

' Initialize the video lists
Function initLists(screen, feed)

    for i = 0 to m.titles.count() - 1
        m.lists[i] = []
    end for

    for each feedItem in feed
        feedItem.lastWatched = get_last_watched(feedItem)

        if feedItem.lastWatched <> invalid then
            m.lists[m.RECENT].Push(feedItem)
        end if
    end for
    
    m.lists[m.ALL] = feed
    m.lists[m.RECENT] = sortLastWatched(m.lists[m.RECENT])
    m.lists[m.SEARCH] = []

    refreshLists(screen)

    screen.Show()

End Function

' Render the grid lists, but only those with data
Function refreshLists(screen)

    titles = [m.titles[m.ALL]]
    lists = [m.lists[m.ALL]]

    if m.lists[m.RECENT].count() > 0 then
        titles.Push(m.titles[m.RECENT])
        lists.Push(m.lists[m.RECENT])
    end if

    if m.lists[m.SEARCH].count() > 0 then
        titles.Push(m.titles[m.SEARCH])
        lists.Push(m.lists[m.SEARCH])
    end if

    screen.SetupLists(titles.Count())
    screen.SetListNames(titles)

    for i = 0 to lists.count() - 1
        screen.SetContentList(i, lists[i])
    end for

    screen.Show()

End Function

' Set last watch timestamp in the registry
function set_last_watched(feedItem)

    now = CreateObject("roDateTime").asSeconds().toStr()
    RegWrite(feedItem.Id, now, "recent")

end function

' Get the timestamp the  video was last watched
function get_last_watched(feedItem)

    lastWatched = RegRead(feedItem.Id, "recent")
    
    if lastWatched = invalid
        return invalid
    end if
    
    return lastWatched.toInt()
end function

' Mark a video watched in the registry
function mark_as_watched(feedItem)

    RegWrite(feedItem.Id, "true", "watched")

end function

' Check the registry to see if a feed item has been watched
function is_watched(feedItem)

    read = RegRead(feedItem.Id, "watched")

    return read = "true"

end function

