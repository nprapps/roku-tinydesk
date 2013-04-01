'
' Miscellaneous functions that don't fit anywhere else.
'

' Iterate over a list of associative arrays and return a list of all values for a given property
function pluck(list, property)

    output = []

    for each item in list
        output.push(item[property])
    end for

    return output

end function
