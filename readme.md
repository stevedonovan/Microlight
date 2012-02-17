## A Small but Useful Lua library

Microlight is an attempt at 'library golf', by analogy to the popular nerd sport 'code golf'.  The Lua standard library is deliberately kept small, and is intended as a base for further development. So Lua programmers tend to keep personal libraries of small useful functions for their projects. The idea here is to try capture some of these functions in one place and document them well enough so that it is easier to use them than to write them yourself.

This library is mostly based on Penlight, which started out as a practical exercise in reproducing some core parts of the Python libraries for Lua, but subsequently started collecting modules useful for application development, such as configuration file reading, pretty-printing, and so forth. It is mostly my code, together with David Manura, and is very much a personal selection.  There are nearly two dozen modules and hundreds of functions.

In Lua, anything beyond the core involves 'personal' choice, and this list of functions does not claim to aspire to 'canonical' status.  It's the start of a community process to find the Top Thirty useful functions that are needed.

## Strings

The Lua string functions are particularly powerful but there are some common functions missing that tend to come up in projects frequently. There is `table.concat` for building a string out of a table, but no `table.split` to break a string into a table.

    > require 'ml'.import()
    > tdump(split('hello dolly'))
    {[1]="hello",[2]="dolly"}

Although it's not difficult to do [string interpolation]() in Lua, there's no little function to do it directly. So Microlight provides `ml.expand`.

    > = expand("hello $you, from ${me}",{you='dolly',me='joe'})
    hello dolly, from joe

`expand` also knows about `${var}` and may also be given a function, just like `string.gsub`.

(escape)

## Tables

Most of the Microlight functions work on Lua tables. Although these may be _both_ arrays _and_ hashmaps, generally we tend to _use_ them as one or the other.


`import` adds key/value pairs to a map, and `extend` appends a list to a list;

    > a = {one=1,two=2}
    > import(a,{three=3,four=4})
    > tdump(a)
    {["one"]=1,["four"]=4,["three"]=3,["two"]=2}
    > t = {10,20,30}
    > extend(t,{40,50})
    > tdump(t)
    {[1]=10,[2]=20,[3]=30,[4]=40,[5]=50}

Please note that the original table is modified by these functions.

These functions are convenient for adding multiple items to a table.

The opposite operation is indexing a table by a list of keys:

    > D = tdump
    > t = {10,20,30,40}
    > D(indexby(t,{1,4}))
    {[1]=10,[2]=40}
    > D(indexby({one=1,two=2,three=3},{'three','two'}))
    {[1]=3,[2]=2}

Here is the old standby `imap`, which makes a _new_ list by applying a function to the original

    > s = {'10','x','20'}
    > ns = imap(tonumber,s)
    > tdump(ns)
    {[1]=10,[2]=false,[3]=20}

`imap` must always return an list of the same size - if the function returns `nil`, then we avoid leaving a hole in the array by using `false` as a placeholder.

Another function that tends to get rewritten a lot is `indexof`:

    > t = {10,20,30}
    > = indexof(t,20)
    2
    > = indexof(t,234)
    nil

In general, you want to match something more than just equality. `ifind` will return the first value that satisfies the given function.

    > t = {'x','10','20','y'}
    > = ifind(t,tonumber)
    10

`tonumber` returns a non-nil value at the second value, so that is returned. To get all the values that match, use `ifilter`:

    > tdump(ifilter(t,tonumber))
    {[1]=10,[2]=20}


