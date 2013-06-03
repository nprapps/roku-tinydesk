'
' The interstitial screen between videos.
'

' Interstitital screen constructor
function InterstitialScreen() as Object

    ' Member vars
    this = {}

    this.SHOW_TIME = 5000
    
    ' Member functions
    this.show = InterstitialScreen_show

    return this

end function

' Show the interstitial
function InterstitialScreen_show(nextContentItem, previousContentItem)

    this = m

    screen = createObject("roScreen")
    port = createObject("roMessagePort")

    ' For Roku 1 compatability
    ' See: http://sdkdocs.roku.com/display/sdkdoc/ifSetMessagePort
    screen.setPort(port)
    screen.clear(&h141414FF)

    width = screen.getWidth()
    height = screen.getHeight()
    halfWidth = width / 2
    halfHeight = height / 2
    
    fonts = createObject("roFontRegistry")

    lines = []

    if previousContentItem <> invalid then
        lines.push("Just Played")
        lines.push(previousContentItem.title)
        lines.push("")
    end if

    lines.push("Up Next")
    lines.push(nextContentItem.title)

    lines.push("")
    lines.push("")
    lines.push("Press Back or Up to return to the menu")

    for i = 0 to lines.count() - 1
        line = lines[i]
        if line = "Just Played" or line = "Up Next" then
            font = fonts.getDefaultFont(28, true, false)
        else
            font = fonts.getDefaultFont(28, false, false)
        endif
        h = font.getOneLineHeight() + 3
        yOffset = halfHeight - ((h * lines.count()) / 2)
        x = halfWidth - (font.getOneLineWidth(line, width) / 2)
        y = yOffset + (h * i)

        screen.drawText(line, x, y, &hEBEBEBFF, font)
    end for

    screen.finish()

    timer = createObject("roTimespan")
    timer.mark()

    playNext = true

    while timer.totalMilliseconds() < this.SHOW_TIME 
        msg = wait(50, port)

        if type(msg) = "roUniversalControlEvent" then
            button = msg.getInt()

            if button = 0 or button = 2 then
                playNext = false 
                exit while
            end if
        end if
    end while

    screen = invalid

    return playNext

end function

