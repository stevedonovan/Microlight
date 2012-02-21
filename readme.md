## A Small but Useful Lua library

The Lua standard library is deliberately kept small, based on the abstract platform defined by the C89 standard. It is intended as a base for further development, so Lua programmers tend to collect small useful functions for their projects.

Microlight is an attempt at 'library golf', by analogy to the popular nerd sport 'code golf'. The idea here is to try capture some of these functions in one place and document them well enough so that it is easier to use them than to write them yourself.

This library is mostly based on Penlight, which started out as a practical exercise in reproducing some core parts of the Python libraries for Lua, but subsequently started collecting modules useful for application development, such as configuration file reading, pretty-printing, and so forth. It is mostly my code, together with David Manura, and is very much a personal selection.  There are nearly two dozen modules and hundreds of functions.

In Lua, anything beyond the core involves 'personal' choice, and this list of functions does not claim to aspire to 'canonical' status.  It's the start of a community process to find the Top Thirty useful functions.

## Strings

THere is no built-in way to show a text representation of a Lua table, which can be frustrating for people first using the interactive prompt. (Please note that globally redefining `tostring` is _not_ a good idea for Lua application development! This trick is intended to make experimation more satisfying.)

   > require 'ml'.import()
   > tostring = tstring
   > = {10,20,name='joe'}
   {10,20,name="joe"}

The Lua string functions are particularly powerful but there are some common functions missing that tend to come up in projects frequently. There is `table.concat` for building a string out of a table, but no `table.split` to break a string into a table.

    >  = split('hello dolly')
    {"hello","dolly"}
    > = split('one,two',',')
    {"one","two"}

The second argument is a _string pattern_ that defaults to spaces.

Although it's not difficult to do [string interpolation]() in Lua, there's no little function to do it directly. So Microlight provides `ml.expand`.

    > = expand("hello $you, from ${me}",{you='dolly',me='joe'})
    hello dolly, from joe

`expand` also knows about `${var}` and may also be given a function, just like `string.gsub`.

Lua string functions match using string patterns, which are a powerful subset of proper regular expressions: they contain 'magic' characters like '.','$' etc which you need to escape before using. `escape` is used when you wish to match a string literally:

    > = ('woo%'):gsub(escape('%'),'hoo')
    "woohoo"   1
    > = split("1.2.3",escape("."))
    {"1","2","3"}

## Files and Paths

Although `access` is available on most platforms, it's not part of the standard, (which is why it's spelt `_access` on Windows). So to test for the existance of a file, you need to attempt to open it. So the `exist` function is easy to write:

    function ml.exists (filename)
        local f = io.open(filename)
        if not f then
            return nil
        else
            f:close()
            return filename
        end
    end

The return value is _not_ a simple true or false; it returns the filename if it exists so we can easily find an existing file out of a group of candidates:

    > = exists 'README' or exists 'readme.txt' or exists 'readme.md'
    "readme.md"

Lua is good at slicing and dicing text, so a common strategy is to read all of a not-so-big file and process the string. This is the job of `readfile`. For instance, this returns the first 128 bytes of the file:

    > txt = readfile('readme.md'):sub(1,128)

Note I said bytes, not characters, since strings can contain any byte sequence. But to be portable you need to say `readfile(name,true)` to ensure that the file is not read as text.

If `readfile` can't open a file, or can't read from it, it will return `nil` and an error message. This is the pattern followed by `io.open` and many other Lua functions; it is considered bad form to raise an error for a _routine_ problem.

Breaking up paths into their components is done with `splitpath` and `splitext`:

    > = splitpath(path)
    "/path/to/dogs" "bonzo.txt"
    > = splitext(path)
    "/path/to/dogs/bonzo"   ".txt"
    > = splitpath 'frodo.txt'
    ""      "frodo.txt"
    > = splitpath '/usr/'
    "/usr"  ""
    > = splitext '/usr/bin/lua'
    "/usr/bin/lua"  ""
    >

These functions return _two_ strings, one of which may be the empty string (rather than `nil`). On Windows, they use both forward- and back-slashes, on Unix only forward slashes.

## Tables

Most of the Microlight functions work on Lua tables. Although these may be _both_ arrays _and_ hashmaps, generally we tend to _use_ them as one or the other. From now on, we'll use array and map as shorthand terms for tables

`import` adds key/value pairs to a map, and `extend` appends an array to an array; they are two complementary ways to add multiple items to a table in a single operation.

    > a = {one=1,two=2}
    > import(a,{three=3,four=4})
    > = a
    {one=1,four=4,three=3,two=2}
    > t = {10,20,30}
    > extend(t,{40,50})
    > = t
    {10,20,30,40,50}

To insert multiple values into a position within an array, use `inject`. It works like `table.insert`, except that the third argument is an array of values. If you do want to overwrite values, then use `true` for the fourth argument:

    > t = {10,20,30,40,50}
    > inject(t,2,{11,12})
    > = t
    {10,11,12,20,30,40,50}
    > inject(t,3,{2,3},true)
    > = t
    {10,11,2,3,30,40,50}

(Please note that the _original_ table is modified by these functions.)

`import` has a few tricks up its sleeve; if the second argument is a string, then it's assumed to be a module name to be passed to `require()`. So this both brings in LuaFileSystem and imports its functions into the global table:

    > import(_G,'lfs')

With a single argument, `import` brings in the `ml` table itself. If the first argument is `nil` then it's assumed to be the global table.

The opposite operation is getting a number of items. There's `sub`, which works just like `string.sub` and is the equivalent of list slicing in Python:

    > numbers = {10,20,30,40,50}
    > = sub(numbers,1,1)
    {10}
    > = sub(numbers,2)
    {20,30,40,50}
    > = sub(numbers,1,-2)
    {10,20,30,40}

`indexby` indexes a table by an array of keys:

    > = indexby(numbers,{1,4})
    {10,40}
    > = indexby({one=1,two=2,three=3},{'three','two'})
    {[3,2}

Here is the old standby `imap`, which makes a _new_ array by applying a function to the original elements:

    > words = {'one','two','three'}
    > = imap(string.upper,words)
    {"ONE","TWO","THREE"}
    > s = {'10','x','20'}
    > ns = imap(tonumber,s)
    > = ns
    {10,false,20}

`imap` must always return an array of the same size - if the function returns `nil`, then we avoid leaving a hole in the array by using `false` as a placeholder.

Another popular function `indexof` does a linear search for a value and returns the 1-based index, or `nil` if not successful:

    > = indexof(numbers,20)
    2
    > = indexof(numbers,234)
    nil

In general, you want to match something more than just equality. `ifind` will return the first value that satisfies the given function.

    > s = {'x','10','20','y'}
    > = ifind(s,tonumber)
    "10"

The standard function `tonumber` returns a non-nil value, so the corresponding value is returned - that is, the string. To get all the values that match, use `ifilter`:

    > = ifilter(numbers,tonumber)
    {"10","20"}

Finally, `delete` removes a _range_ of values from an array, and takes the same arguments as `sub`.

# Sets and Maps

`indexof` is not going to be your tool of choice for really big tables, since it does a linear search. Lookup on Lua hash tables is faster, if we can get the data into the right shape.  `invert` turns a array of values into a table with those values as keys:

    > m = invert(numbers)
    > = m
    {[20]=2,[10]=1,[40]=4,[30]=3,[50]=5}
    > = m[20]
    2
    > = m[30]
    3
    > = m[25]
    nil
    > m = invert(words)
    > = m
    {one=1,three=3,two=2}

So from a array we get a reverse lookup map. This is also exactly what we want from a _set_: fast membership test and unique values.

Sets don't particularly care about the actual value, as long as it evaluates as true or false, so `contains_keys` is _subset_:

    > = contains_keys(m,{one=true,two=true})
    true

 `makemap` takes another argument and makes up a table where the keys come from the first array and the values from the second array:

    > = makemap({'a','b','c'},{1,2,3})
    {a=1,c=3,b=2}

Finally, `collect` makes a array out of an iterator. The second argument can be the number of values to collect, which is useful for iterators that never terminate.

    > s = 'my dog ate your homework'
    > words = collect(s:gmatch '%a+')
    > = words
    {"my","dog","ate","your","homework"}
    > = collect(math.random,3)
    {0.0012512588885159,0.56358531449324,0.19330423902097}
    > lines = collect(io.lines(),4)
    one
    two
    three
    four
    > = lines
    {"one","two","three","four"}

A simple utility to sort standard input looks like this:

    require 'ml'.import()
    lines = collect(io.lines())
    table.sort(lines)
    print(table.concat(lines,'\n'))

# Higher-order Functions

Functions are first-class values in Lua, so functions may manipulate them, often called 'higher-order' functions. Function _composition_ is often useful:

    > printf = compose(io.write,string.format)
    > printf("the answer is %d\n",42)
    the answer is 42

`bind1` and `bind2` specialize functions by creating a version that has one less argument. `bind1` gives a function where the first argument is _bound_ to some value. This can be used to pass methods to functions expecting a plain function. In Lua, `obj:f()` is shorthand for `obj.f(obj,...)`. Just using a dot is not enough, since there is no _implicit binding_ of the self argument. This is precisely what `bind1` can do:

    > ewrite = bind1(io.stderr.write,io.stderr)
    > ewrite 'hello\n'

We want a logging function that writes a message to standard error with a line feed; just bind the second argument to '\n':

    > log = bind2(ewrite,'\n')
    > log 'hello'
    hello

Note that `sub(t,1)` does a simple array copy:

    > copy = bind2(sub,1)
    > t = {1,2,3}
    > = copy(t)
    {1,2,3}

It's easy to make a 'predicate' for detecting empty or blank strings:

    > blank = bind2(string.match,'^%s*$')
    > = blank ''
    ""
    > = blank '  '
    "  "
    > = blank 'oy vey'
    nil

I put 'predicate' in quotes because it's again not classic true/false; Lua actually only developed `false` fairly late in its career. Operationally, this is a fine predicate because `nil` matches as 'false' and any string matches as 'true'.

This pattern generates a whole family of classification functions, e.g. `hex` (using '%x+'), `upcase` ('%u+'), `iden` ('%a[%w_]*') and so forth. You can keep the binding game going (after all, `bind2` is just a function like any other.)

    > matcher = bind1(bind2,string.match)
    > hex = matcher '^%x+$'

Predicates are particularly useful for `ifind` and `ifilter`.  It's now easy to filter out strings from a array that match `blank` or `hex`, for instance.

## Classes

Lua and Javascript have two important things in common; objects are maps, with sugar so that `t.key == t['key']` and there is no built-in class mechanism. This causes a lot of (iniital) unhappiness. It's straightforward to build a class system, and so it is reinvented numerous times in incompatible ways.

`class` works as expected:

    Animal = ml.class()
    Animal.sound = '?'

    function Animal:_init(name)
        self.name = name
    end

    function Animal:speak()
        return self._class.sound..' I am '..self.name
    end

    Cat = class(Animal)
    Cat.sound = 'meow'

    felix = Cat('felix')

    assert(felix:speak() == 'meow I am felix')
    assert(felix._base == Animal)
    assert(Cat.class_of(felix))
    assert(Animal.class_of(felix))


It creates a table (what else?) which will contain the methods; if there's a base class, then that will be copied into the table. This table becomes the metatable of each new instance of that class, with `__index` pointing to the metatable itself. If `obj.key` is not found, then Lua will attempt to look it up in the class. In this way, each object does not have to carry references to all of its methods, which gets inefficient.

The class is callable, and when called it returns a new object; if there is an `_init` method that will be called to do any custom setup; if not then the base class constructor will be called.

All classes have a `_class` field pointing to itself (which is how `Animal.speak` gets its polymorphic behaviour) and a `class_of` function.

## Array Class

Since Lua 5.1, the string functions can be called as methods, e.g. `s:sub(1,2)`. People commonly would like this convenience for tables as well. But Lua tables are building blocks; to build abstract data types you need to specialize your tables. So `ml` provides a `Array` class:

    local Array = ml.class()

    -- A constructor can return a _specific_ object
    function Array:_init(t)
        if not t then return nil end  -- no table, make a new one
        if getmetatable(t)==Array then  -- was already a Array: copy constructor!
            t = ml.sub(t,1)
        end
        return t
    end

    function Array:map(f,...) return Array(ml.imap(f,self,...)) end

Note that if a constructor _does_ return a value, then it becomes the new object. This flexibility is useful if you want to wrap _existing_ objects.

We can't just add `imap`, because the function signature is wrong; the first argument is the function and it returns a plain jane array.

But we can add methods to the class directly if the functions have the right first argument, and don't return anything:

    local C=ml.compose

    ml.import(Array,{
        -- straight from the table library
        concat=table.concat,sort=table.sort,insert=table.insert,
        remove=table.remove,append=table.insert,
        -- straight from ml
        indexof=ml.indexof, find=ml.ifind, extend=ml.extend,
        -- originals return table; these versions make the tables into arrays.
        filter=C(Array,ml.ifilter),
        sub=C(Array,ml.sub),
        indexby=C(Array,ml.indexby),
    })

`ifilter` and `sub` are almost right, but they need to be wrapped so that they return Arrays as expected.

    > words = Array{'frodo','bilbo','sam'}
    > = words:sub(2)
    {"bilbo","sam"}
    > words:sort()
    > = words
    {"bilbo","frodo","sam"}
    > = words:concat ','
    "bilbo,frodo,sam"
    > = words:filter(string.match,'o$'):map(string.upper)
    {"BILBO","FRODO"}

Arrays are easier to use and involve less typing because the table functions are directly available from them. Methods may be _chained_, which (I think) reads better than the usual functional application order from right to left.

    > l = Array.range(10,50,10)
    > = l:indexof(30)
    3
    > = l:indexby {1,3,5}
    {10,30,50}
    > = l:map(function(x) return x + 1 end)
    {11,21,31,41,51}

Lua anonymous functions have a somewhat heavy syntax; three keywords needed to define a short lambda.  It would be cool if the shorthand syntax `|x| x+1` used by Metalua would make into mainstream Lua, but there seems to be widespread resistance to this litle convenience.

## Experiments: String Operator Shortcuts

The `mlx` module contains things which aren't part of the Microlight core. So if you came to see the strict definition of Microlight, then read no further. However, you may find some of these ideas appealing.

Having the basic Lua operators available as functions turns out to be surprisingly useful:

    > mlx = require 'mlx'
    > F = mlx.string_op
    > = F'+'(10,20)
    30
    > = F'{}'(10,20)
    {10,20}
    > = F'[]'({10,20},2)
    20
    > = F'~' ('hello','l+')
    "ll"
    > match = compose('T','~')
    > = match('hello','l+')
    true
    > = match('hello','bye')
    false

All the usual binary operators, plus 'or' and 'and', are available. '{}' wraps up table construction, '~' does `string.match`, and 'T` is when you do want the result to be boolean.

We can ask for these shortcuts to be used in the `ml` functions like so:

    > mlx.string_operators()
    > records = {{name='Joe',age=25},{name='Alice',age=23}}
    > = imap('[]',records,'age')
    25,23
    > = l:map('+',1)
    {11,21,31,41,51}
    > = l:map2('+',{1,2})
    {11,22}
    > zip = bind2(imap2,'{}')
    > = zip(l,{'one','two','three'},{1,2,3})
    {{10,"one"},{20,"two"},{30,"three"}}


That feels better! Note that the commonly-defined `zip` function comes naturally out of making the `imap2` operation table construction.

## Evil Manipulations: Functional Operators

`mlx` contains the following evil incantation:

    debug.setmetatable(print,{__concat=ml.compose,__mul=ml.bind1})

Now, all types Lua may have metatables, but apart from userdata and tables they all _share a single metatable_ per type.  So I can change the behaviour of all functions by picking on poor old `print`. This is evil because I am making a global modification and Libraries Must Not Do That. This is one of the few things that the Lua community does get uptight about; the casual monkey-patching of the Rubyists is frowned upon, and in my humble opinion the Web would now be a faster and more solid experience if Lua had become the hip dynamic server language.

So this modification only happens if you ask for it, and it's not a good idea to use it in modules for the general, trusting public.

    > mlx.function_operators()

The standard disclaimer over, let's see how a little operator magic can help functional operations.

    > printf = io.write .. string.format
    > printf("not bad, %s!\n",'Joe')
    not bad, Joe!

Binding the first argument is the most useful:

    > column = imap * '[]'
    > ages = column(records,'age')
    > = collect(math.random*100,10)
    {1,57,20,81,59,48,36,90,83,75}

`bind2` is common because the first argument of many standard functions is the table or string to be operated on.

    tail = sub/2
    blank = string.match/'^%s*$'

These operators may be built into functional expressions:

    log = (io.stderr.write*io.stderr)/'\n'

(That is, make a error writer by binding the error file object to its write method, and then bind '\n' to its second argument.)

We don't have a `trim` function (and perhaps it should be one of the Top Thirty). But its definition is surprisingly elegant:

    trim = gsub/'^%s*'/''..gsub/'%s*$'/''

It's unwise to push a good idea too far, of course. Functional expressions can get unreadable very quickly.



