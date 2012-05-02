local ml = require 'ml'
local A = ml.Array
unpack = unpack or table.unpack

ml.import(_G,ml)

t = {one={two=2},10,20,{1,2}}

assert(tstring(t) == "{10,20,{1,2},one={two=2}}")

local charmap = string.char(unpack(range(0,255)))
assert(("aa"..charmap.."bb"):match(escape(charmap)) == charmap)


assert(split('hello','')[1] == 'hello')

a123 = A{'one','two','three'}
assert(split('one,two,three',',') == a123)

assert(split('one,,two',',') == A{'one','','two'})

-- trailing delimiter ignored!
assert(split('one,two,three,',',') == a123)

-- delimiter is a Lua pattern (use escape if necessary!)
-- splitting tokens separated by commas and/or spaces
assert(split('one, two,three  ','[,%s]+') == a123)
assert(split('one two  three  ','[,%s]+') == a123)


t = {10,20,30,40}

assert(sub (t,1,2) == A{10,20})

assert(indexof(t,20) == 2)

-- indexof may have an optional specialized equality function
idx = indexof({'one','two','three'},'TWO',function(s1,s2)
    return s1:upper()==s2:upper()
  end
)
assert (idx == 2)

-- generalization of table indexing
assert(indexby(t,{1,4}) == A{10,40})

assert(range(1,4) == A{1,2,3,4})

extend(t,{50,60})

assert(sub(t,4) == A{40,50,60})

m = makemap(t)

assert(m[50]==5 and m[20]==2)

assert(count(m) == #t)

tt = keys(m)

-- this isn't necessarily true because there is no guaranteed key order
--assert(tt==A(t))

-- this only compares keys, so the actual values don't matter
assert(issubset({a=1,b=2,c=3},{a='hello'}))

ta = A(t)

removerange(t,2,3)
assert(ta == A{10,40,50,60})

-- insert some values at the start
-- (insertvalues in general can be expensive when actually inserting)
insertvalues(t,1,{2,5})
assert(ta == A{2,5,10,40,50,60})

-- copy some values without inserting (overwrite)
insertvalues(t,2,{11,12,13},true)
assert(ta == A{2,11,12,13,50,60})

-- make a new array containing all the even numbers
-- the filter method is equivalent to ml.ifilter
a2 = ta:filter(function(x) return x % 2 == 0 end)

assert(a2 == A{2,12,50,60})

-- make a new array by mapping the square function over its elements
-- the map method is equivalent to ml.imap
a3 = range(1,4):map(function(x) return x*x end)

assert(a3 == A{1,4,9,16})

-- the result of a map must have the same size as the input,
-- and must be a valid sequence, so `nil` becomes `false`
t = {'1','foo','10'}
res = imap(tonumber,t)
assert(res==A{1,false,10})

-- Array objects understand concatenation!
assert(A{1,2}..A{3,4} == range(1,4))

a = range(1,10)

assert(a:sub(2,4) == A{2,3,4})

-- arrays are callable, using the sub method
assert(a(2,4) == A{2,3,4})

-- sub works like string.sub, so this works (potential for confusion with
-- indexing here)
assert(a(8) == A{8,9,10})
assert(a(8,-2) == A{8,9})

----- functional helpers

assert( bind1(string.match,'hello')('^hell') == 'hell')

isdigits = bind2(string.match,'^%d+$')
assert( isdigits '23105')
assert( not isdigits '23x5' )

local k = 0

f = memoize(function(s)
    k = k + 1
    return s:upper()
end)

assert(f'one' == 'ONE')
assert(f'one' == 'ONE')
assert(k == 1)













