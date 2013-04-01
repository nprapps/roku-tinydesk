'
' Tiny Desk Roku app
'

function Main()

    globals = getGlobalAA()

    globals.analytics = Analytics()
    globals.analytics.startup()
    SetTheme()
    GridScreen()
    globals.analytics.shutdown()

end function

