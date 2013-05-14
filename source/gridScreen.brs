'
' The main grid/list screen
'

' Grid screen constructor
function GridScreen() as Object

    ' Member vars
    this = {}
    
    this.NEW = 0
    this.HITS = 1
    this.UNWATCHED = 2
    this.WATCHED = 3
    this.SEARCH = 4

    this.NEW_LIST_LENGTH = 5

    this.SEARCH_ITEM = {
        id: "search",
        title: "Search",
        'description: "Search for an artist by name.",
        sdPosterUrl: "pkg:/images/search_hd.png",
        hdPosterUrl: "pkg:/images/search_hd.png"
    }

    this._port = createObject("roMessagePort")
    this._screen = createObject("roGridScreen")
    this._videoScreen = VideoScreen()
    this._searchScreen = SearchScreen()
    this._interstitialScreen = InterstitialScreen() 
    this._wrapper = invalid

    this._feed = []
    this._titles = ["New", "Best of", "Unwatched", "Watched", "Search"]
    this._lists = []
    this._lastSearch = ""
    
    ' Member functions
    this.run = GridScreen_run
    this._watch = _GridScreen_watch
    this._search = _GridScreen_search
    this._initLists = _GridScreen_initLists
    this._beginWrapper = _GridScreen_beginWrapper
    this._endWrapper = _GridScreen_endWrapper

    ' Setup
    this._screen.setMessagePort(this._port)

    this._screen.setGridStyle("four-column-flat-landscape")
    this._screen.setDisplayMode("photo-fit")
    
    ' Always setup at least one list (keeps tooltips from appearing in the wrong place)
    this._screen.setupLists(1)

    this._screen.show()
    this._screen.showMessage("Retrieving...")

    this._feed = fetchFeed()
    this._initLists()

    this._screen.ClearMessage()

    return this

end function

' Run the GridScreen main loop, which functions as the app main loop
function GridScreen_run()

    this = m

    while true
        msg = wait(0, this._port)

        if msg = invalid then
            exit while
        end if

        if msg.isListItemSelected() then
            selected_list = msg.getIndex()
            selected_item = msg.getData()
            contentItem = this._lists[selected_list][selected_item]

            if contentItem.id = "search" then
                this._search()
            else
                this._beginWrapper()
                
                if selected_list = this.SEARCH
                    searchTerm = this._lastSearch
                else
                    searchTerm = ""
                end if

                watchNext:

                watched = this._watch(contentItem, this._titles[selected_list], searchTerm)
                
                if watched and selected_item < this._lists[selected_list].count() - 1 then
                    selected_item = selected_item + 1
                    previousContentItem = contentItem
                    contentItem = this._lists[selected_list][selected_item]
                    
                    playNext = this._interstitialScreen.show(contentItem, previousContentItem)
                    
                    if playNext then
                        goto watchNext
                    end if
                end if
    
                this._endWrapper()
            end if
        else if msg.isRemoteKeyPressed() then
            if msg.getIndex() = 10 then
                this._search()
            end if
        else if msg.isScreenClosed() then
            exit while
        end if
    end while

end function

' Watch a video selected from the grid
function _GridScreen_watch(contentItem, fromList, searchTerm)

    this = m

    watched = this._videoScreen.play(contentItem, fromList, searchTerm)
    lastWatched = contentItem["lastWatched"] 
    setLastWatched(contentItem)

    if watched then
        markAsWatched(contentItem)
    end if

    if lastWatched = invalid then
        ' Remove vid from unwatched list
        for i = 0 to this._lists[this.UNWATCHED].count() - 1
            if this._lists[this.UNWATCHED][i].id = contentItem.id then
                this._lists[this.UNWATCHED].delete(i)
                exit for
            end if
        end for
    else
        ' Remove vid from watched list if it already exists
        for i = 0 to this._lists[this.WATCHED].count() - 1
            if this._lists[this.WATCHED][i].id = contentItem.id then
                this._lists[this.WATCHED].delete(i)
                exit for
            end if
        end for
    end if
    
    ' Add vid to watched list
    this._lists[this.WATCHED].unshift(contentItem)

    this._screen.setContentList(this.UNWATCHED, this._lists[this.UNWATCHED])
    this._screen.setContentList(this.WATCHED, this._lists[this.WATCHED])
    this._screen.setFocusedListItem(this.WATCHED, 0)

    return watched

end function

' Execute a search
function _GridScreen_search()

    this = m

    this._searchScreen.search(this._feed)

    this._lists[this.SEARCH] = this._searchScreen.getMatches()
    this._lists[this.SEARCH].unshift(this.SEARCH_ITEM)

    this._lastSearch = this._searchScreen.getQuery()

    if this._lists[this.SEARCH].count() = 1 then
        this._screen.setListName(this.SEARCH, "Search")
    else
        this._screen.setListName(this.SEARCH, "Search results for " + chr(34) + this._lastSearch + chr(34)) 
    end if
    
    this._screen.setContentList(this.SEARCH, this._lists[this.SEARCH])

    this._searchScreen.close()

    ' No results
    if this._lists[this.SEARCH].count() = 1 then
        this._screen.setFocusedListItem(this.SEARCH, 0)
    ' One result
    else if this._lists[this.SEARCH].count() = 2 then
        contentItem = this._lists[this.SEARCH][1]
        this._beginWrapper()
        this._watch(contentItem, this._titles[this.SEARCH], this._lastSearch)
        this._endWrapper()
    ' Multiple results
    else
        this._screen.setFocusedListItem(this.SEARCH, 1)
    end if

end function

' Initialize the video lists
function _GridScreen_initLists()

    this = m

    for i = 0 to this._titles.count() - 1
        this._lists[i] = []
    end for

    for i = 0 to this._feed.count() - 1
        contentItem = this._feed[i] 
        contentItem["lastWatched"] = getLastWatched(contentItem)

        if contentItem["lastWatched"] = invalid then
            this._lists[this.UNWATCHED].push(contentItem)
        else
            this._lists[this.WATCHED].push(contentItem)
        end if

        if contentItem["greatestHit"] then
            this._lists[this.HITS].push(contentItem)
        end if

        if i < this.NEW_LIST_LENGTH then
            this._lists[this.NEW].push(contentItem)
        end if
    end for
    
    sortBy(this._lists[this.WATCHED], "lastWatched", False)
    this._lists[this.SEARCH] = [this.SEARCH_ITEM]

    month_day = left(this._lists[this.NEW][0].releaseDate, len(this._lists[this.NEW][0].releaseDate) - 6)
    this._titles[this.NEW] = "New (" + month_day + ")"

    this._screen.setupLists(this._titles.count())
    this._screen.setListNames(this._titles)

    for i = 0 to this._lists.count() - 1
        this._screen.setContentList(i, this._lists[i])
        this._screen.setFocusedListItem(i, 0)
    end for

    this._screen.setFocusedListItem(this.NEW, 0)

    this._screen.show()

end function

function _GridScreen_beginWrapper()

    this = m

    this._wrapper = createObject("roScreen")
    this._wrapper.clear(&h141414FF)
    this._wrapper.finish()

end function

function _GridScreen_endWrapper()

    this = m

    this._wrapper = invalid

end function

