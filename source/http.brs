'
' Utility functions for making web requests
'

' Create a URL transfer object
Function createTransfer(port, url)

    xfer = createObject("roUrlTransfer")
    xfer.setPort(port)
    xfer.setUrl(url)
    xfer.enableEncodings(true)

    return xfer

End Function

' Request a URL with automated retries
Function httpGetWithRetry(url, timeout=5000, retries=5) as String

    print "Requesting: " + url

    port = createObject("roMessagePort")
    xfer = createTransfer(port, url)

    response = ""

    ' Always try at least once!
    retries = retries + 1

    while retries > 0
        if xfer.asyncGetToString() then
            event = wait(timeout, port)

            if type(event) = "roUrlEvent"
                response = event.getString()
                exit while        
            elseif event = invalid
                xfer.asyncCancel()
                
                ' Create a new transfer
                xfer = createTransfer(port, url)

                ' Backoff
                timeout = 2 * timeout
            endif
        endif

        retries = retries - 1
    end while
    
    return response 

End Function

