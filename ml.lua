-----------------
-- Microlight - a very compact Lua utilities module
--
-- Steve Donovan, 2012; License MIT
-- @module ml

local ml = {}
local Array

---------------------------------------------------
-- String utilties.
-- @section string
---------------------------------------------------

--- split a string into a array of strings separated by a delimiter.
-- @param s The input string
-- @param re A Lua string pattern; defaults to '%s+'
-- @param n optional maximum number of splits
-- @return a array
function ml.split(s,re,n)
    local find,sub,append = string.find, string.sub, table.insert
    local i1,ls = 1,{}
    if not re then re = '%s+' end
    if re == '' then return {s} end
    while true do
        local i2,i3 = find(s,re,i1)
        if not i2 then
            local last = sub(s,i1)
            if last ~= '' then append(ls,last) end
            if #ls == 1 and ls[1] == '' then
                return Array{}
            else
                return Array(ls)
            end
        end
        append(ls,sub(s,i1,i2-1))
        if n and #ls == n then
            ls[#ls] = sub(s,i1)
            return Array(ls)
        end
        i1 = i3+1
    end
end

ml.lua51 = _VERSION:match '5%.1$'

--- escape any 'magic' characters in a string
-- @param s The input string
-- @return an escaped string
function ml.escape(s)
    local res = s:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1')
    if ml.lua51 then
        res = res:gsub('%z','%%z')
    end
    return res
end

--- expand a string containing any ${var} or $var.
-- However, you should pick _either one_ consistently!
-- @param s the string
-- @param subst either a table or a function (as in `string.gsub`)
-- @return expanded string
function ml.expand (s,subst)
    local res,k = s:gsub('%${([%w_]+)}',subst)
    if k > 0 then return res end
    return (res:gsub('%$([%w_]+)',subst))
end

--- return the contents of a file as a string
-- @param filename The file path
-- @param is_bin open in binary mode, default false
-- @return file contents
function ml.readfile(filename,is_bin)
    local mode = is_bin and 'b' or ''
    local f,err = io.open(filename,'r'..mode)
    if not f then return nil,err end
    local res,err = f:read('*a')
    f:close()
    if not res then return nil,err end
    return res
end

---------------------------------------------------
-- File and Path functions
-- @section file
---------------------------------------------------

--- Does a file exist?
-- @param filename a file path
-- @return the file path, otherwise nil
-- @usage exists 'readme' or exists 'readme.txt' or exists 'readme.md'
function ml.exists (filename)
    local f = io.open(filename)
    if not f then
        return nil
    else
        f:close()
        return filename
    end
end

local sep, other_sep = package.config:sub(1,1),'/'


--- split a file path.
-- if there's no directory part, the first value will be the empty string
-- @param P A file path
-- @return the directory part
-- @return the file part
function ml.splitpath(P)
    local i = #P
    local ch = P:sub(i,i)
    while i > 0 and ch ~= sep and ch ~= other_sep do
        i = i - 1
        ch = P:sub(i,i)
    end
    if i == 0 then
        return '',P
    else
        return P:sub(1,i-1), P:sub(i+1)
    end
end

--- given a path, return the root part and the extension part.
-- if there's no extension part, the second value will be empty
-- @param P A file path
-- @return the name part
-- @return the extension
function ml.splitext(P)
    local i = #P
    local ch = P:sub(i,i)
    while i > 0 and ch ~= '.' do
        if ch == sep or ch == other_sep then
            return P,''
        end
        i = i - 1
        ch = P:sub(i,i)
    end
    if i == 0 then
        return P,''
    else
        return P:sub(1,i-1),P:sub(i)
    end
end

---------------------------------------------------
-- Extended table functions.
-- 'array' here is shorthand for 'array-like table'; these functions
-- only operate over the numeric `1..#t` range of a table and are
-- particularly efficient for this purpose.
-- @section table
---------------------------------------------------

local tostring = tostring -- so we can globally override tostring!

local function quote (v)
    if type(v) == 'string' then
        return ('%q'):format(v)
    else
        return tostring(v)
    end
end

local lua_keyword = {
    ["and"] = true, ["break"] = true,  ["do"] = true,
    ["else"] = true, ["elseif"] = true, ["end"] = true,
    ["false"] = true, ["for"] = true, ["function"] = true,
    ["if"] = true, ["in"] = true,  ["local"] = true, ["nil"] = true,
    ["not"] = true, ["or"] = true, ["repeat"] = true,
    ["return"] = true, ["then"] = true, ["true"] = true,
    ["until"] = true,  ["while"] = true, ["goto"] = true,
}

local function is_iden (key)
    return key:match '^[%a_][%w_]*$' and not lua_keyword[key]
end


local tbuff
function tbuff (t,buff,k,start_indent,indent)
    local start_indent2, indent2
    if start_indent then
        start_indent2 = indent
        indent2 = indent .. indent
    end
    local function append (v)
        if not v then return end
        buff[k] = v
        k = k + 1
    end
    local function put_item(value)
        if type(value) == 'table' then
            if not buff.tables[value] then
                buff.tables[value] = true
                k = tbuff(value,buff,k,start_indent2,indent2)
            else
                append("<cycle>")
            end
        else
            value = quote(value)
            append(value)
        end
        append ","
        if start_indent then append '\n' end
    end
    append "{"
    if start_indent then append '\n' end
    -- array part -------
    local array = {}
    for i,value in ipairs(t) do
        append(indent)
        put_item(value)
        array[i] = true
    end
    -- 'map' part ------
    for key,value in pairs(t) do if not array[key] then
        append(indent)
        -- non-identifiers need ["key"]
        if type(key)~='string' or not is_iden(key) then
            if type(key)=='table' then
                key = ml.tstring(key)
            else
                key = quote(key)
            end
            key = "["..key.."]"
        end
        append(key..'=')
        put_item(value)
    end end
    -- removing trailing comma is done for prettiness, but this implementation
    -- is not pretty at all!
    local last = start_indent and buff[k-2] or buff[k-1]
    if start_indent then
        if last == '{' then -- empty table
            k = k - 1
        else
            if last == ',' then -- get rid of trailing comma
                k = k - 2
                append '\n'
            end
            append(start_indent)
        end
    elseif last == "," then -- get rid of trailing comma
        k = k - 1
    end
    append "}"
    return k
end

--- return a string representation of a Lua value.
-- Cycles are detected, and the result can be optionally indented nicely.
-- @param t the table
-- @param how (optional) a table with fields `spacing' and 'indent', or a string corresponding
-- to `indent`.
-- @return a string
function ml.tstring (t,how)
    if type(t) == 'table' and not (getmetatable(t) and getmetatable(t).__tostring) then
        local buff = {tables={[t]=true}}
        how = how or {}
        if type(how) == 'string' then how = {indent = how} end
        pcall(tbuff,t,buff,1,how.spacing or how.indent,how.indent)
        return table.concat(buff)
    else
        return quote(t)
    end
end

--- map a function over a array.
-- The output must always be the same length as the input, so
-- any `nil` values are mapped to `false`.
-- @param f a function of one or more arguments
-- @param t the array
-- @param ... any extra arguments to the function
-- @return a array with elements `f(t[i],...)`
function ml.imap(f,t,...)
    f = ml.function_arg(f)
    local res = {}
    for i = 1,#t do
        res[i] = f(t[i],...) or false
    end
    return Array(res)
end

--- map a function over two arrays.
-- The output must always be the same length as the input, so
-- any `nil` values are mapped to `false`.
-- @param f a function of two or more arguments
-- @param t1 first array
-- @param t2 second array
-- @param ... any extra arguments to the function
-- @return a array with elements `f(t1[i],t2[i],...)`
function ml.imap2(f,t1,t2,...)
    f = ml.function_arg(f)
    local res = {}
    local n = math.min(#t1,#t2)
    for i = 1,n do
        res[i] = f(t1[i],t2[i],...) or false
    end
    return Array(res)
end

local function truth (x)
    return x and true or false
end

--- filter a array using a predicate.
-- If `pred` is absent, then we provide a default which
-- filters out any `false` values.
-- @param t a table
-- @param pred the predicate function
-- @param ... any extra arguments to the predicate
-- @return a array such that `pred(t[i])` is true
function ml.ifilter(t,pred,...)
    local res,k = {},1
    pred = ml.function_arg(pred or truth)
    for i = 1,#t do
        if pred(t[i],...) then
            res[k] = t[i]
            k = k + 1
        end
    end
    return Array(res)
end

--- find an item in a array using a predicate.
-- @param t the array
-- @param pred a function of at least one argument
-- @param ... any extra arguments
-- @return the item value
function ml.ifind(t,pred,...)
    pred = ml.function_arg(pred)
    for i = 1,#t do
        if pred(t[i],...) then
            return t[i]
        end
    end
end

--- return the index of an item in a array.
-- @param t the array
-- @param value item value
-- @param cmp optional comparison function (default is `v==value`)
-- @return index, otherwise `nil`
function ml.indexof (t,value,cmp)
    if cmp then
        cmp = ml.function_arg(cmp)
    end
    for i = 1,#t do
        local v = t[i]
        if cmp and cmp(v,value) or v == value then
            return i
        end
    end
end

local function upper (t,i2)
    if not i2 or i2 > #t then
        return #t
    elseif i2 < 0 then
        return #t + i2 + 1
    else
        return i2
    end
end

--- return a slice of a array.
-- Like string.sub, the end index may be negative.
-- @param t the array
-- @param i1 the start index
-- @param i2 the end index, default #t
-- @return a array such that `t[i]` for `i` from `i1` to `i2` inclusive
function ml.sub(t,i1,i2)
    i2 = upper(t,i2)
    local res,k = {},1
    for i = i1,i2 do
        res[k] = t[i]
        k = k + 1
    end
    return Array(res)
end

--- delete a range of values from a array.
-- @param tbl the array
-- @param start start index
-- @param finish end index (like `ml.sub`)
function ml.removerange(tbl,start,finish)
    finish = upper(tbl,finish)
    local count = finish - start + 1
    for k=start+count,#tbl do tbl[k-count]=tbl[k] end
    for k=#tbl,#tbl-count+1,-1 do tbl[k]=nil end
end

--- copy values from `src` into `dest` starting at `index`.
-- By default, it inserts into `dest` and moves up elements of `src`
-- to make room.
-- @param dest destination array
-- @param index start index in destination
-- @param src source array
-- @param overwrite write over values
function ml.insertvalues(dest,index,src,overwrite)
    local sz = #src
    if not overwrite then
        for i = #dest,index,-1 do dest[i+sz] = dest[i] end
    end
    for i = 1,sz do
        dest[index+i-1] = src[i]
    end
end

--- extend a array using values from another.
-- @param t the array to be extended
-- @param other a array
-- @return the extended array
function ml.extend(t,other)
    ml.insertvalues(t,#t+1,other)
    return t
end

--- make a array of indexed values.
-- Generalized table indexing
-- @param t a table
-- @param keys a array of keys or indices
-- @return a array `L` such that `L[keys[i]]`
-- @usage indexby({one=1,two=2},{'one'}) == {1}
function ml.indexby(t,keys)
    local res,k = {},1
    for _,v in pairs(keys) do
        res[k] = t[v] or false
        k = k + 1
    end
    return Array(res)
end

--- create an array of numbers from start to end.
-- With one argument it goes `1..x1`. `d` may be a
-- floating-point fraction
-- @param x1 start value
-- @param x2 end value
-- @param d increment (default 1)
-- @return array of numbers
-- @usage range(2,10) == {2,3,4,5,6,7,8,9,10}
-- @usage range(5) == {1,2,3,4,5}
function ml.range (x1,x2,d)
    if not x2 then
        x2 = x1
        x1 = 1
    end
    d = d or 1
    local res,k = {},1
    for x = x1,x2,d do
        res[k] = x
        k = k + 1
    end
    return Array(res)
end


--- add the key/value pairs of `other` to `t`.
-- For sets, this is their union. For the same keys,
-- the values from the first table will be overwritten.
-- If `other` is a string, then it becomes the result of `require`
-- With only one argument, the second argument is assumed to be
-- the `ml` table itself.
-- @param t table to be updated
-- @param other table
-- @return the updated table
function ml.import(t,...)
    local other
    -- explicit table, or current environment
    t = t or _ENV or getfenv(2)
    if select('#',...) == 0 then -- default is to pull in this library!
        other = ml
    else
        other = ...
        if type(other) == 'string' then -- lazy require!
            other = require (other)
        end
    end
    for k,v in pairs(other) do
        t[k] = v
    end
    return t
end

ml.update = ml.import


--- make a table from a array of keys and a array of values.
-- @param t a array of keys
-- @param tv a array of values
-- @return a table where `{[t[i]]=tv[i]}`
-- @usage makemap({'power','glory'},{20,30}) == {power=20,glory=30}
function ml.makemap(t,tv)
    local res = {}
    for i = 1,#t do
        res[t[i]] = tv and tv[i] or i
    end
    return res
end

--- make a set from a array.
-- The values are the original array indices.
-- @param t a array of values
-- @return a table where the keys are the indices in the array.
-- @usage invert{'one','two'} == {one=1,two=2}
-- @function ml.invert
ml.invert = ml.makemap

--- extract the keys of a table as a array.
-- @param t a table
-- @return a array of keys
function ml.keys(t)
    local res,k = {},1
    for key in pairs(t) do
        res[k] = key
        k = k + 1
    end
    return Array(res)
end

--- are all the keys of `other` in `t`?
-- Only compares keys!
-- @param t a set
-- @param other a possible subset
-- @return true or false
function ml.issubset(t,other)
    for k,v in pairs(other) do
        if t[k] == nil then return false end
    end
    return true
end

ml.contains_keys = ml.issubset

--- return the number of keys in this table.
-- @param t a table
-- @return key count, (which is set cardinality)
function ml.count (t)
    local count = 0
    for k in pairs(t) do count = count + 1 end
    return count
end

--- do these tables have the same keys?
-- @param t a table
-- @param other a table
-- @return true or false
function ml.equal_keys(t,other)
    return ml.issubset(t,other) and ml.issubset(other,t)
end

local function makeT (...) return {...} end
local function nop (x) return x end

local function collect_ (condn,iter,obj,...)
    local n = type(condn) == 'number' and condn
    local pred = ml.callable(condn) and condn
    local kv = select('#',...) > 0
    local start = select(1,...)
    local res,k = {},1
    for key,value in iter,obj,start do
        value = kv and value or key
        res[k] = value
        k = k + 1
        if pred and not pred(value) then
            break
        elseif n and k > n then
            break
        end
    end
    return Array(res)
end

function ml.collect (...)
    return collect_(nil,...)
end

function ml.collect_until (n,...)
    return collect_(n,...)
end

---------------------------------------------------
-- Functional helpers.
-- @section function
---------------------------------------------------

--- create a function which will throw an error on failure.
-- @param f a function that returns nil,err if it fails
-- @param quit exit the script immediately with the error (default false)
-- @return an equivalent function that raises an error
function ml.throw(f,quit)
    f = ml.function_arg(f)
    return function(...)
        local res,err = f(...)
        if err then
            if quit then
                io.stderr:write(err,'\n')
                os.exit(1)
            else
                error(err,2)
            end
        end
        return res
    end
end

--- bind the value `v` to the first argument of function `f`.
-- @param f a function of at least one argument
-- @param v a value
-- @return a function of one less argument
-- @usage (bind1(string.match,'hello')('^hell') == 'hell'
function ml.bind1(f,v)
    f = ml.function_arg(f)
    return function(...)
        return f(v,...)
    end
end

--- bind the value `v` to the second argument of function `f`.
-- @param f a function of at least one argument
-- @param v a value
-- @return a function of one less argument
-- @usage (bind2(string.match,'^hell')('hello') == 'hell'
function ml.bind2(f,v)
    f = ml.function_arg(f)
    return function(x,...)
        return f(x,v,...)
    end
end

--- compose two functions.
-- For instance, `printf` can be defined as `compose(io.write,string.format)`
-- @param f1 a function
-- @param f2 a function
-- @return `f1(f2(...))`
function ml.compose(f1,f2)
    f1 = ml.function_arg(f1)
    f2 = ml.function_arg(f2)
    return function(...)
        return f1(f2(...))
    end
end

--- is the object either a function or a callable object?.
-- @param obj Object to check.
-- @return true if callable
function ml.callable (obj)
    return type(obj) == 'function' or getmetatable(obj) and getmetatable(obj).__call
end

-- exported but not documented because this is used as a hook for people
-- wishing to extend the idea of 'callable' in this library.
function ml.function_arg(f)
    assert(ml.callable(f),"expecting a function or callable object")
    return f
end

--- 'memoize' a function (cache returned value for next call).
-- This is useful if you have a function which is relatively expensive,
-- but you don't know in advance what values will be required, so
-- building a table upfront is wasteful/impossible.
-- @param func a function of at least one argument
-- @return a function with at least one argument, which is used as the key.
function ml.memoize(func)
    return setmetatable({}, {
        __index = function(self, k, ...)
            local v = func(k,...)
            self[k] = v
            return v
        end,
        __call = function(self, k) return self[k] end
    })
end


---------------------------------------------------
-- Classes.
-- @section class
---------------------------------------------------

--- create a class with an optional base class.
-- The resulting table can be called to make a new object, which invokes
-- an optional constructor named `_init`. If the base
-- class has a constructor, you can call it as the `super()` method.
-- Every class has a `_class` and a maybe-nil `_base` field, which can
-- be accessed through the object.
-- All metamethods are inherited.
-- The class is given a function `Klass.class_of(obj)`.
-- @param base optional base class
-- @return the metatable representing the class
function ml.class(base)
    local klass, base_ctor = {}
    if base then
        ml.import(klass,base)
        klass._base = base
        base_ctor = rawget(base,'_init')
    end
    klass.__index = klass
    klass._class = klass
    klass.class_of = function(obj)
        local m = getmetatable(obj) -- an object created by class() ?
        if not m or not m._class then return false end
        while m do -- follow the inheritance chain --
            if m == klass then return true end
            m = rawget(m,'_base')
        end
        return false
    end
    setmetatable(klass,{
        __call = function(klass,...)
            local obj = setmetatable({},klass)
            if rawget(klass,'_init') then
                klass.super = base_ctor
                local res = klass._init(obj,...) -- call our constructor
                if res then -- which can return a new self..
                    obj = setmetatable(res,klass)
                end
            elseif base_ctor then -- call base ctor automatically
                base_ctor(obj,...)
            end
            return obj
        end
    })
    return klass
end
------------------------
-- a simple Array class.
-- @table Array

Array = ml.class()

local C=ml.compose

-- a class is just a table of functions, so we can do wholesale updates!
ml.import(Array,{
    -- straight from the table library
    concat=table.concat,insert=table.insert,remove=table.remove,append=table.insert,
    -- originals return table; these versions make the tables into arrays.
    filter=C(Array,ml.ifilter),sub=C(Array,ml.sub), indexby=C(Array,ml.indexby),
    range = C(Array,ml.range),
    indexof=ml.indexof, find=ml.ifind, extend=ml.extend
})

-- A constructor can return a _specific_ object
function Array:_init(t)
    if not t then return nil end  -- no table, make a new one
    if getmetatable(t)==Array then  -- was already a Array: copy constructor!
        t = ml.sub(t,1)
    end
    return t
end

-- need to do this to rearrange self/function order

function Array:sort(f) table.sort(self,f); return self end
function Array:sorted(f) return Array(self):sort(f) end
function Array:map(f,...) return Array(ml.imap(f,self,...)) end
function Array:map2(f,other) return Array(ml.imap2(f,self,other)) end

function Array:__tostring()
    return '{' .. self:map(ml.tstring):concat ',' .. '}'
end

function Array.__eq(l1,l2)
    if #l1 ~= #l2 then return false end
    for i = 1,#l1 do
        if l1[i] ~= l2[i] then return false end
    end
    return true
end

function Array.__concat (l1,l2)
    return Array(ml.extend(ml.extend({},l1),l2))
end

-- x(2,3) is short for x:sub(2,3)
Array.__call = Array.sub

ml.Array = Array
ml.List = Array

return ml
