'
' Generic sort algorithms.
'

' Sort a list (insertion sort)
function sort(list, ascending=True)

    for i = 1 to list.count() - 1
        value = list[i]
        j = i - 1

        while j >= 0
            if (ascending and list[j] < value) or (not ascending and list[j] > value) then 
                exit while
            end if

            list[j + 1] = list[j]
            j = j - 1
        end while

        list[j + 1] = value
    next

end function

' Sort a list of associative arrays by a key's value (insertion sort)
function sortBy(list, property, ascending=True)

    for i = 1 to list.count() - 1
        value = list[i]
        j = i - 1

        while j >= 0
            if (ascending and list[j][property] < value[property]) or (not ascending and list[j][property] > value[property]) then 
                exit while
            end if

            list[j + 1] = list[j]
            j = j - 1
        end while

        list[j + 1] = value
    next

end function

