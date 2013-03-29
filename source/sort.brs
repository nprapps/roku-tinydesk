'
' Generic sort algorithms.
'

' Sort a list
function sort(list, ascending=True) 

    swapped = true

    while swapped = true
        swapped = false

        for i = 0 to list.Count() - 1
            if list[i + 1] = invalid then
                exit for
            end if
            
            if (ascending and list[i] > list[i + 1]) or (not ascending and list[i] < list[i + 1]) then
                temp = list[i]
                list[i] = list[i + 1]
                list[i + 1] = temp
                swapped = true
            end if
        end for
    end while

    return list

end function

' Sort a list of objects by some common property
function sortBy(list, property, ascending=True) 

    swapped = true

    while swapped = true
        swapped = false

        for i = 0 to list.Count() - 1
            if list[i + 1] = invalid then
                exit for
            end if
            
            if (ascending and list[i][property] > list[i + 1][property]) or (not ascending and list[i][property] < list[i + 1][property]) then
                temp = list[i]
                list[i] = list[i + 1]
                list[i + 1] = temp
                swapped = true
            end if
        end for
    end while

    return list

end function

