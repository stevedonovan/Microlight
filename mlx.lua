local ml = require 'ml'

local mlx = {}

--- make a binary comparison function.
-- @param key in structure or array to be compared
-- @param op '<' for less than, '==' for equals, and otherwise a binary function.
-- @return a comparison function
function ml.binop(key,op)
    if op == '<' then
        return function(a,b) return a[key] < b[key] end
    elseif op == '==' then
        return function(a,b) return a[key] == b[key] end
    else
        op = ml.function_arg(op)
        return function(a,b) return op(a[key],b[key]) end
    end
end

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
    ['~'] = function(a,b) return a:match(b) end,
    ['T'] = function(a) return a and true or false end,
}

local _function_arg = ml.function_arg

function mlx.string_op(f)
    if type(f) == 'string' then
        f = ops[f]
    end
    return _function_arg(f)
end

--- enable string operator shortcuts for ml functions.
-- That is, the string '+' means the addition function, etc.
-- '()' is the call operator, '[]' is indexing and '{}' is the table operator.
function mlx.string_operators ()
    ml.function_arg = mlx.string_op
end

------------------------
-- a simple List class.
-- @type List

--- Set class
local Set = {}
setmetatable(Set,{
    __call = function(klass,t)
        if #t > 0 then t = ml.invert(t) end
        setmetatable(t,Set)
        return t
    end
})

-- set union
function Set.__add(s1,s2)
    return Set(ml.import(ml.import({},s1),s2))
end

-- set intersection
function Set.__mul(s1,s2)
    local res = {}
    for k in pairs(s1) do
        if s2[k] then res[k] = true end
    end
    return Set(res)
end

-- subset
function Set.__lt(s1,s2)
    return ml.contains_keys(s2,s1)
end

-- equality
function Set.__eq(s1,s2)
    return ml.equal_keys(s1,s2)
end

-- elements of `s1` not in `s2`
function Set.__sub(s1,s2)
    local res = {}
    for k in pairs(s1) do
        if not s2[k] then res[k] = true end
    end
    return Set(res)
end

function Set:__tostring()
    return '['..ml.List(ml.keys(self)):map(ml.tstring):concat ',' .. ']'
end

Set.__len = ml.count_keys

mlx.Set = Set


return mlx

