-----------------
-- Microlight - a very compact Lua utilities module
--
-- Steve Donovan, 2012; License MIT
-- @module ml

local ml = {}

---------------------------------------------------
-- String utilties.
-- @section string
---------------------------------------------------

--- split a string into a list of strings separated by a delimiter.
-- @param s The input string
-- @param re A Lua string pattern; defaults to '%s+'
-- @param n optional maximum number of splits
-- @return a list
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
                return {}
            else
                return ls
            end
        end
        append(ls,sub(s,i1,i2-1))
        if n and #ls == n then
            ls[#ls] = sub(s,i1)
            return ls
        end
        i1 = i3+1
    end
end

--- escape any 'magic' characters in a string
-- @param s The input string
-- @return an escaped string
function ml.escape(s)
    return (s:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1'))
end

--- expand a string containing any ${var} or $var.
-- @param s the string
-- @param subst either a table or a function (as in `string.gsub`)
-- @return expanded string
function ml.expand (s,subst)
    local res = s:gsub('%${([%w_]+)}',subst)
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
-- 'list' here is shorthand for 'list-like table'; these functions
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

local tbuff
function tbuff (t,buff,k)
    local used
    local function append (v)
        buff[k] = v
        k = k + 1
    end
    append "{"
    if #t > 0 then -- dump out the array part
        used = {}
        for i,value in ipairs(t) do
            if type(value) == 'table' then
                k = tbuff(value,buff,k)
            else
                append(quote(value))
            end
            append ","
            used[i] = true
        end
    end
    for key,value in pairs(t) do
        if not used or not used[key] then
            if type(value) ~= 'table' then
                -- non-identifiers need []
                if type(key)~='string' or not key:match '^%a[%w_]*$' then
                    key = "["..key.."]"
                end
                append(key.."="..quote(value))
            else
                if not buff.tables[value] then
                    k = tbuff(value,buff,k)
                    buff.tables[value] = true
                else
                    append "<cycle>"
                end
            end
            append ","
        end
    end
    if buff[k-1] == "," then k = k - 1 end
    append "}"
    return k
end

--- return a string representation of a Lua value.
-- Cycles are detected, and a limit on number of items can be imposed.
-- @param t the table
-- @return a string
function ml.tstring (t,limit)
    if type(t) == 'table' then
        local buff = {tables={}}
        pcall(tbuff,t,buff,1)
        return table.concat(buff)
    else
        return quote(t)
    end
end

--- dump a Lua value to a file object.
-- With no second argument, dumps to standard output.
-- @param t the table
-- @param f the file object (anything supporting f.write)
function ml.tdump(t,...)
    local f = select('#',...) > 0 and select(1,...) or io.stdout
    f:write(ml.tstring(t),'\n')
end

--- map a function over a list.
-- The output must always be the same length as the input, so
-- any `nil` values are mapped to `false`.
-- @param f a function of one or more arguments
-- @param t the table
-- @param ... any extra arguments to the function
-- @return a list with elements `f(t[i])`
function ml.imap(f,t,...)
    f = ml.function_arg(f)
    local res = {}
    for i = 1,#t do
        res[i] = f(t[i],...) or false
    end
    return res
end

function ml.imap2(f,t1,t2)
    f = ml.function_arg(f)
    local res = {}
    local n = math.min(#t1,#t2)
    for i = 1,n do
        res[i] = f(t1[i],t2[i]) or false
    end
    return res
end

local function truth (x)
    return x and true or false
end

--- filter a list using a predicate.
-- If `pred` is absent, then we provide a default which
-- filters out any `false` values.
-- @param t a table
-- @param pred the predicate function
-- @param ... any extra arguments to the predicate
-- @return a list such that `pred(t[i])` is true
function ml.ifilter(t,pred,...)
    local res,k = {},1
    pred = ml.function_arg(pred or truth)
    for i = 1,#t do
        if pred(t[i],...) then
            res[k] = t[i]
            k = k + 1
        end
    end
    return res
end

--- find an item in a list using a predicate.
-- @param t the list
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

--- return the index of an item in a list.
-- @param t the list
-- @param value item value
-- @return index, otherwise `nil`
function ml.indexof (t,value)
    for i = 1,#t do
        if t[i] == value then return i end
    end
end

--- return a slice of a list.
-- Like string.sub, the end index may be negative.
-- @param t the list
-- @param i1 the start index
-- @param i2 the end index, default #t
function ml.sub(t,i1,i2)
    if not i2 or i2 > #t then
        i2 = #t
    elseif i2 < 0 then
        i2 = #t + i2 + 1
    end
    local res,k = {},1
    for i = i1,i2 do
        res[k] = t[i]
        k = k + 1
    end
    return res
end

--- copy a list into another.
-- @param dest destination list
-- @param src source list
-- @param idest start index in destination, default 1
-- @param isrc start index in source, default 1
-- @param nsrc number of elements to copy, default #src
-- @return the first list
function ml.icopy(dest,src,idest,isrc,nsrc)
    local k = idest or 1
    isrc = isrc or 1
    nsrc = nsrc or #src
    for i = isrc,nsrc do
        dest[k] = src[i]
        k = k + 1
    end
    return dest
end

--- make a list of indexed values.
-- Generalized table indexing
-- @param t a table
-- @param keys a list of keys or indices
-- @return a list `L` such that `L[keys[i]]`
-- @usage indexby({one=1,two=2},{'one'}) == {1}
function ml.indexby(t,keys)
    local res,k = {},1
    for _,v in pairs(keys) do
        res[k] = t[v] or false
        k = k + 1
    end
    return res
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

--- extend a list using values from another.
-- @param t the list to be extended
-- @param other a list
-- @return the extended list
function ml.extend(t,other)
    local n = #t
    for i = 1,#other do
        t[n+i] = other[i]
    end
    return t
end

--- make a map from a list.
-- In its simplest form, this makes a _set_ from a list; each value
-- becomes a key. The default value of that key is the original
-- list index. These values can also be provided directly.
-- @param t a list of values that become the keys
-- @param v optional list that become the values
-- @return a table where the keys are the values
-- @usage makemap{'one','two'} == {one=1,two=2}
-- @usage makemap({'power','glory'},{20,30}) == {power=20,glory=30}
function ml.makemap(t,tv)
    local res = {}
    for i = 1,#t do
        res[t[i]] = tv and tv[i] or i
    end
    return res
end

--- extract the keys of a table as a list.
-- @param t a table
-- @return a list of keys
function ml.keys(t)
    local res,k = {},1
    for key in pairs(t) do
        res[k] = key
        k = k + 1
    end
    return res
end

--- is `other` a subset of `t`?
-- @param t a set
-- @param other a possible subset
-- @return true or false
function ml.subset(t,other)
    for k,v in pairs(other) do
        if t[k] == nil then return false end
    end
    return true
end

--- are these two tables equal?
-- This is shallow equality.
-- @param t a table
-- @param other a table
-- @return true or false
function ml.tequal(t,other)
    return ml.subset(t,other) and ml.subset(other,t)
end

local function makeT (...) return {...} end
local function nop (x) return x end

--- collect the values of an iterator into a list.
-- @param iter an iterator returning one or more values
-- @param select (optional) Either a number of values to collect, or `true`
-- meaning collect values as a tuple, or a function to process/filter values.
-- @return a list of values.
-- @usage collect(math.random,3) == {0.23,0.75,0.13}
function ml.collect (iter, select)
    local F,count = nop
    if type(select) == 'function' then
        F = select
    elseif select == true then
        F = makeT
    else
        count = select
    end
    local res,k = {},1
    repeat
        local v = F(iter())
        if v == nil or (count and k > count) then break end
        if v ~= false then
            res[k] = v
            k = k + 1
        end
    until false
    return res
end

---------------------------------------------------
-- Functional helpers.
-- @section function
---------------------------------------------------

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
        if not m or not m._klass then return false end
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


return ml