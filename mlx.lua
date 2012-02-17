local ml = require 'ml'

local mlx = {}

--- enable operator shortcuts for functional operations.
-- `*` will now mean `ml.bind1`, and `..` will mean `ml.compose`
-- Please note that this modifies the metatable for _all_ functions,
-- so it's probably a bad idea to use in modules!
-- For example, `f*a` is the same as `bind1(f,a)`, etc.
function mlx.function_operators ()
    debug.setmetatable(print,{__concat=ml.compose,__mul=ml.bind1,__div=ml.bind2})
    ml.import(getmetatable "", {
        __mul=ml.bind1,__div=ml.bind2
    })
end


local ops = {
    ['()'] = function(fn,...) return fn(...) end,
    ['{}'] = function(...) return {...} end,
    ['[]'] = function(t,k) return t[k] end,
    ['=='] = function(a,b) return a==b end,
    ['~='] = function(a,b) return a~=b end,
    ['<'] = function(a,b) return a<b end,
    ['<='] = function(a,b) return a<=b end,
    ['>'] = function(a,b) return a>b end,
    ['>='] = function(a,b) return a>=b end,
    ['#'] = function(a) return #a end,
    ['+'] = function(a,b) return a+b end,
    ['-'] = function(a,b) return a-b end,
    ['*'] = function(a,b) return a*b end,
    ['/'] = function(a,b) return a/b end,
    ['^'] = function(a,b) return a^b end,
    ['%'] = function(a,b) return a%b end,
    ['..'] = function(a,b) return a..b end,
    ['and'] = function(a,b) return a and b end,
    ['or'] = function(a,b) return a or b end,
    ['~'] = function(a,b) return a:find(b) ~= nil end,
}

--- enable string operator shortcuts for ml functions.
-- That is, the string '+' means the addition function, etc.
-- '()' is the call operator, '[]' is indexing and '{}' is the table operator.
function mlx.string_operators ()
    local _function_arg = ml.function_arg
    ml.function_arg = function(f)
        if type(f) == 'string' then
            f = ops[f]
        end
        return _function_arg(f)
    end
end

------------------------
-- a simple List class.
-- @type List

local List = ml.class()

local C=ml.compose

-- a class is just a table of functions, so we can do wholesale updates!
ml.import(List,{
    -- straight from the table library
    concat=table.concat,sort=table.sort,insert=table.insert,remove=table.remove,append=table.insert,
    -- originals return table; these versions make the tables into lists.
    filter=C(List,ml.ifilter),sub=C(List,ml.sub), indexby=C(List,ml.indexby),
    indexof=ml.indexof, find=ml.ifind, extend=ml.extend
})

-- A constructor can return a _specific_ object
function List:_init(t)
    if t then return t end
end

function List.range (x1,x2,d)
    d = d or 1
    local res,k = {},1
    for x = x1,x2,d do
        res[k] = x
        k = k + 1
    end
    return List(res)
end

-- need to do this to rearrange self/function order

function List:map(f,...) return List(ml.imap(f,self,...)) end
function List:map2(f,other) return List(ml.imap2(f,self,other)) end

function List:__tostring()
    return '{' .. self:map(ml.tstring):concat ',' .. '}'
end

function List.__eq(l1,l2)
    if #l1 ~= #l2 then return false end
    for i = 1,#l1 do
        if t[i] ~= other[i] then return false end
    end
    return true
end

mlx.List = List

return mlx

