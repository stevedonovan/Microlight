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



