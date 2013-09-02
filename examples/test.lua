local ml = require 'ml'
local A = ml.Array
unpack = unpack or table.unpack

ml.import(_G,ml)

local teq = Array.__eq

function asserteq (v1,v2)
    local t1,t2 = type(v1),type(v2)
    local check = false
    if t1 == t2 then
        if t1 ~= 'table' then check = v1 == v2
        else check = teq(t1,t2)
        end
    end
    if not check then
        error("assertion failed\nA "..tstring(v1).."\nB "..tstring(v2),2)
    end
end

t = {one={two=2},10,20,{1,2}}

assert(tstring(t) == "{10,20,{1,2},one={two=2}}")

local charmap = string.char(unpack(range(0,255)))
assert(("aa"..charmap.."bb"):match(escape(charmap)) == charmap)


assert(split('hello','')[1] == 'hello')

local a123 = {'one','two','three'}

asserteq(split('one,two,three',','),a123)

asserteq(split('one,,two',','),{'one','','two'})

-- trailing delimiter ignored!
asserteq(split('one,two,three,',','),a123)

-- delimiter is a Lua pattern (use escape if necessary!)
-- splitting tokens separated by commas and/or spaces
asserteq(split('one, two,three  ','[,%s]+'),a123)
asserteq(split('one two  three  ','[,%s]+'),a123)

--- paths
-- note that forward slashes also work on Windows
local P = '/users/steve/bonzo.dog'

local path,name = ml.splitpath(P)

asserteq(path,'/users/steve')
asserteq(name,'bonzo.dog')

local basename,ext = ml.splitext(P)

asserteq(basename,'/users/steve/bonzo')
asserteq(ext,'.dog')


t = {10,20,30,40}

asserteq(sub(t,1,2),{10,20})

asserteq(indexof(t,20),2)

-- indexof may have an optional specialized equality function
idx = indexof({'one','two','three'},'TWO',function(s1,s2)
    return s1:upper()==s2:upper()
  end
)
asserteq (idx,2)

-- generalization of table indexing
asserteq(indexby(t,{1,4}),{10,40})

-- generating a range of numbers (Array.range does this but returns an Array)
asserteq(range(1,4),{1,2,3,4})

-- append extra elements to t
extend(t,{50,60},{70,80})

asserteq(sub(t,4),{40,50,60,70,80})

m = makemap(t)

assert(m[50]==5 and m[20]==2)

assert(count(m) == #t)

tt = keys(m)

-- this isn't necessarily true because there is no guaranteed key order
--assert(tt==A(t))

-- this only compares keys, so the actual values don't matter
assert(issubset({a=1,b=2,c=3},{a='hello'}))


removerange(t,2,3)
asserteq(t,{10,40,50,60})

-- insert some values at the start
-- (insertvalues in general can be expensive when actually inserting)
insertvalues(t,1,{2,5})
asserteq(t,{2,5,10,40,50,60})

-- copy some values without inserting (overwrite)
insertvalues(t,2,{11,12,13},true)
asserteq(t,{2,11,12,13,50,60})

-- make a new array containing all the even numbers
-- the filter method is equivalent to ml.ifilter
ta = A(t)
a2 = ta:filter(function(x) return x % 2 == 0 end)

asserteq(a2,A{2,12,50,60})

ta = A{10,2,5,4,9}
ta:sort()
asserteq(ta,A{2,4,5,9,10})

-- make a new array by mapping the square function over its elements
-- the map method is equivalent to ml.imap
a3 = Array.range(1,4):map(function(x) return x*x end)

asserteq(a3,A{1,4,9,16})

-- the result of a map must have the same size as the input,
-- and must be a valid sequence, so `nil` becomes `false`
t = {'1','foo','10'}
res = imap(tonumber,t)
asserteq(res,{1,false,10})

-- Array objects understand concatenation!
asserteq(A{1,2}..A{3,4},Array.range(1,4))

a = Array.range(1,10)

assert(a:sub(2,4) == A{2,3,4})

t = {one=1,two=2}
k = keys(t)
-- no guarantee of order!
assert(teq(k,{'one','two'}) or teq(k,{'two','one'}))

-- ml does not give us a corresponding values() function, but
-- collect2nd does the job
v = collect2nd(pairs(t))
assert(teq(v,{1,2}) or teq(v,{2,1}))

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

-- string lambdas ---
-- Contain up to three placeholders: X,Y and Z

local a = A{1,2,3,4}

local plus1 = a:map 'X+1'

assert (plus1 == A{2,3,4,5})

-- can use extra placeholder to match extra arg...
assert(a:map('X+Y',1), plus1)

val = A{'ml','test','util'}:map('X..Y','.lua'):filter(exists)
assert(val == A{'ml.lua'})

--- classes ------

C = class()

--- conventional name for constructor --
function C:_init (name)
    self.name = name
end

-- can define metamethods as well as plain methods
function C:__tostring ()
    return 'name '..self.name
end

function C:__eq (other)
    return self.name == other.name
end

c = C('Jones')
assert(tostring(c) == 'name Jones')

-- inherited classes inherit constructors and metamethods
D = class(C)

d = C('Jane')
assert(tostring(d) == 'name Jane')
assert(d == C 'Jane')

-- if you do have a constructor, call the base constructor explicitly
E = class(D)

function E:_init (name,nick)
    self:super(name)
    self.nick = nick
end

-- call methods of base class explicitly
-- (you can also use `self._class`)

function E:__tostring ()
    return D.__tostring(self)..' nick '..self.nick
end

asserteq(tostring(E('Jones','jj')),'name Jones nick jj')

--- Subclassing Array

Strings = class(Array)

-- can always use the functional helpers to make new methods
-- bind2 is useful with methods

Strings.match = bind2(Strings.filter,string.match)

a = Strings{'one','two','three'}
asserteq(a:match 'e$',{'one','three'})

---  for numerical operations

NA = class(Array)

local function mapm(a1,op,a2)
  local M = type(a2)=='table' and Array.map2 or Array.map
  return M(a1,op,a2)
end

--- elementwise arithmetric operations
function NA.__unm(a) return a:map '-X' end
function NA.__pow(a,s) return a:map 'X^Y' end
function NA.__add(a1,a2) return mapm(a1,'X+Y',a2) end
function NA.__sub(a1,a2) return mapm(a1,'X-Y',a2) end
function NA.__div(a1,a2) return mapm(a1,'X/Y',a2) end
function NA.__mul(a1,a2) return mapm(a2,'X*Y',a1) end

function NA:minmax ()
    local min,max = math.huge,-math.huge
    for i = 1,#self do
        local val = self[i]
        if val > max then max = val end
        if val < min then min = val end
    end
    return min,max
end

function NA:sum ()
    local res = 0
    for i = 1,#self do
        res = res + self[i]
    end
    return res
end

function NA:normalize ()
    return self:transform('X/Y',self:sum())
end

NA:mappers {
    tostring = tostring,
    format = string.format
}

asserteq(NA{10,20}:tostring(),{'10','20'})

asserteq(NA{1,2.2,10}:format '%5.1f',{"  1.0","  2.2"," 10.0"})

--- arithmetric --

asserteq(NA{1,2,3} + NA{10,20,30}, NA{11,21,31})

-- note 2nd arg may be a scalar
asserteq(NA{1,2,3}+1, NA{2,3,4})

asserteq(NA{10,20}/2, NA{5,10})

-- except for * where the 1st arg can be a scalar...
asserteq(2*NA{1,2,3},NA{2,4,6})

asserteq(-NA{1,2},NA{-1,-2})

-- subclasses of Array have covariant methods, so that e.g. sub
-- is returning an actual NA object.
local mi,ma = NA{1,6,11,2,20}:sub(1,3):minmax()
assert(mi == 1 and ma == 11)


-- properties

local props = require 'ml_properties'

P = class()

function P:update (k,v)
    last_set = k
end

-- any explicit setters will be called on construction
function P:set_name (name)

    self.myname = name
end

function P:get_name ()
    last_get = 'name'
    return self.myname
end

-- have to call this after any setters or getters are defined...
props(P,{
    __update = P.update; -- will be called after setting _props
    enabled = true,
    visible = false,
    name = 'foo',
})

p = P()

asserteq (p,{myname="foo",_enabled=true,_visible=false})

assert(p.enabled==true and p.visible==false)

p.visible = true
asserteq(last_set,'visible')

p.name = 'boo'

assert (p.name == 'boo' and last_get == 'name')












