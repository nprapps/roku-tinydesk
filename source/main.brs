'
' Tiny Desk Roku app
'

function Main()

    globals = getGlobalAA()

    globals.analytics = Analytics()

    print "Starting up"
    globals.analytics.startup()

    SetTheme()
    grid = GridScreen()

    print "Running the grid"
    grid.run()

    print "Shutting down"
    globals.analytics.shutdown()

end function

