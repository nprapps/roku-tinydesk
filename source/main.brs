' nprapps Roku app

Sub Main()

    screen = preShowGridScreen()

    if screen=invalid then
        print "unexpected error in preShowGridScreen"
        return
    end if

    showGridScreen(screen)

End Sub

