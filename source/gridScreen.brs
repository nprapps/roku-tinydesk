'
' The main grid/list screen
'

' Grid screen constructor
function GridScreen() as Object

    ' Member vars
    this = {}
    
    this.ALL = 0
    this.RECENT = 1
    this.SEARCH = 2

    this._port = createObject("roMessagePort")
    this._screen = createObject("roGridScreen")
    this._videoScreen = VideoScreen()
    this._searchScreen = SearchScreen()

    this._feed = []
    this._titles = ["All", "Recently watched", "Search results"]
    this._lists = []
    this._visibleTitles = [] 
    this._visibleLists = []
    
    ' Member functions
    this._watch = _GridScreen_watch
    this._initLists = _GridScreen_initLists
    this._refreshLists = _GridScreen_refreshLists

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

        if msg.isListItemSelected() then
            selected_list = msg.getIndex()
            selected_item = msg.getData()
            contentItem = this._visibleLists[selected_list][selected_item]

            this._watch(contentItem)
        else if msg.isRemoteKeyPressed() then
            if msg.getIndex() = 10 then
                this._lists[this.SEARCH] = this._searchScreen.search(this._feed)

                if this._lists[this.SEARCH].count() = 1 then
                    contentItem = this._lists[this.SEARCH][0]
                    this._watch(contentItem)
                else
                    this._refreshLists()
                    this._screen.setFocusedListItem(this.SEARCH, 0)
                end if
            end if
        else if msg.isScreenClosed() then
            exit while
        end if
    end while

    return this

end function

' Watch a video selected from the grid
function _GridScreen_watch(contentItem)

    this = m

    watched = this._videoScreen.play(contentItem)
    setLastWatched(contentItem)

    if watched then
        markAsWatched(contentItem)
    end if

    ' Remove vid from recent list if it already exists
    for i = 0 to this._lists[this.RECENT].count() - 1
        if this._lists[this.RECENT][i].id = contentItem.id then
            this._lists[this.RECENT].delete(i)
            exit for
        end if
    end for
    
    ' Add vid to recent list
    this._lists[this.RECENT].unshift(contentItem)

    this._refreshLists()

    this._screen.setFocusedListItem(this.RECENT, 0)

end function

' Initialize the video lists
function _GridScreen_initLists()

    this = m

    for i = 0 to this._titles.count() - 1
        this._lists[i] = []
    end for

    for each contentItem in this._feed 
        contentItem.lastWatched = getLastWatched(contentItem)

        if contentItem.lastWatched <> invalid then
            this._lists[this.RECENT].Push(contentItem)
        end if
    end for
    
    this._lists[this.ALL] = this._feed
    this._lists[this.RECENT] = sortByLastWatched(this._lists[this.RECENT])
    this._lists[this.SEARCH] = []

    this._refreshLists()
    this._screen.setFocusedListItem(this.ALL, 0)

    this._screen.Show()

end function

' Render the grid lists, but only those with data
function _GridScreen_refreshLists()

    this = m

    this._visibleTitles = [this._titles[this.ALL]]
    this._visibleLists = [this._lists[this.ALL]]

    if this._lists[this.RECENT].Count() > 0 then
        this._visibleTitles.Push(this._titles[this.RECENT])
        this._visibleLists.Push(this._lists[this.RECENT])
    end if

    if this._lists[this.SEARCH].Count() > 0 then
        this._visibleTitles.Push(this._titles[this.SEARCH])
        this._visibleLists.Push(this._lists[this.SEARCH])
    end if

    this._screen.setupLists(this._visibleTitles.Count())
    this._screen.setListNames(this._visibleTitles)

    for i = 0 to this._visibleLists.Count() - 1
        this._screen.setContentList(i, this._visibleLists[i])
        this._screen.setFocusedListItem(i, 0)
    end for

    this._screen.Show()

end function

