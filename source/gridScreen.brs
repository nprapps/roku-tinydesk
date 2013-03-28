'
' The main grid/list screen
'

' Grid screen constructor
function GridScreen()

    ' Member vars
    this = {}
    
    this.ALL = 0
    this.RECENT = 1
    this.SEARCH = 2

    this._port = createObject("roMessagePort")
    this._screen = createObject("roGridScreen")

    this._feed = []
    this._titles = ["All", "Recently watched", "Search results"]
    this._lists = []
    this._visibleTitles = [] 
    this._visibleLists = []
    
    ' Member functions
    this._initLists = _GridScreen_initLists
    this._refreshLists = _GridScreen_refreshLists
    this._sortLastWatched = _GridScreen_sortLastWatched

    ' Setup
    this._screen.setMessagePort(this._port)

    this._screen.setBreadcrumbText("", "Press * to search            ")
    this._screen.setGridStyle("flat-landscape")
    this._screen.setDisplayMode("photo-fit")
    
    ' Always setup at least one list (keeps tooltips from appearing in the wrong place)
    this._screen.setupLists(1)

    this._screen.show()
    this._screen.showMessage("Retrieving...")

    this._feed = fetchFeed()
    this._initLists()

    this._screen.ClearMessage()

    while true
        msg = wait(0, this._port)

        if type(msg) = "roGridScreenEvent" then

            if msg.isListItemSelected() then
                selected_list = msg.getIndex()
                selected_item = msg.getData()
                feedItem = this._visibleLists[selected_list][selected_item]

                watched = showVideoScreen(feedItem)
                set_last_watched(feedItem)

                if watched and selected_list <> this.WATCHED then
                    mark_as_watched(feedItem)
                end if

                ' Remove vid from recent list if it already exists
                for i = 0 to this._lists[this.RECENT].count() - 1
                    if this._lists[this.RECENT][i].Id = feedItem.Id then
                        this._lists[this.RECENT].delete(i)
                        exit for
                    end if
                end for
                
                ' Add vid to recent list
                this._lists[this.RECENT].unshift(feedItem)

                this._refreshLists()

                this._screen.setFocusedListItem(this.RECENT, 0)
            else if msg.isRemoteKeyPressed() then
                if msg.getIndex() = 10 then
                    this._lists[this.SEARCH] = showSearchScreen(feed)
                    
                    this._refreshLists()

                    this._screen.setFocusedListItem(this.SEARCH, 0)
                end if
            else if msg.isScreenClosed() then
                exit while
            end if
        end if
    end while

end function

' BubbleSort the feed by last watched
function _GridScreen_sortLastWatched(list)

    swapped = true

    while swapped = true
        swapped = false

        for i = 0 to list.Count() - 1
            if list[i + 1] = invalid then
                exit for
            end if

            if list[i].lastWatched < list[i + 1].lastWatched then
                temp = list[i]
                list[i] = list[i + 1]
                list[i + 1] = temp
                swapped = true
            end if
        end for
    end while

    return list

end function

' Initialize the video lists
function _GridScreen_initLists()

    for i = 0 to m._titles.count() - 1
        m._lists[i] = []
    end for

    for each feedItem in m._feed 
        feedItem.lastWatched = get_last_watched(feedItem)

        if feedItem.lastWatched <> invalid then
            m._lists[m.RECENT].Push(feedItem)
        end if
    end for
    
    m._lists[m.ALL] = m._feed
    m._lists[m.RECENT] = m._sortLastWatched(m._lists[m.RECENT])
    m._lists[m.SEARCH] = []

    m._refreshLists()

    m._screen.Show()

end function

' Render the grid lists, but only those with data
function _GridScreen_refreshLists()

    m._visibleTitles = [m._titles[m.ALL]]
    m._visibleLists = [m._lists[m.ALL]]

    if m._lists[m.RECENT].Count() > 0 then
        m._visibleTitles.Push(m._titles[m.RECENT])
        m._visibleLists.Push(m._lists[m.RECENT])
    end if

    if m._lists[m.SEARCH].Count() > 0 then
        m._visibleTitles.Push(m._titles[m.SEARCH])
        m._visibleLists.Push(m._lists[m.SEARCH])
    end if

    m._screen.SetupLists(m._visibleTitles.Count())
    m._screen.SetListNames(m._visibleTitles)

    for i = 0 to m._visibleLists.Count() - 1
        m._screen.SetContentList(i, m._visibleLists[i])
    end for

    m._screen.Show()

end function

' Set last watch timestamp in the registry
function set_last_watched(feedItem)

    now = createObject("roDateTime").asSeconds().toStr()
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

' Fetch and parse the video feed
function fetchFeed()

    feed = http_get_with_retry("http://apps.npr.org/roku-tinydesk/feed.json")

    return ParseJSON(feed)

end function

