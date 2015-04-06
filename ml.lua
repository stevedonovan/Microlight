-----------------
-- Microlight - a very compact Lua utilities module
--
-- Steve Donovan, 2012; License MIT
-- @module ml

local ml = {}
local select,pairs = select,pairs
local function_arg

table.unpack = table.unpack or unpack

---------------------------------------------------
-- String utilties.
-- @section string
---------------------------------------------------

--- split a delimited string into an array of strings.
-- @param s The input string
-- @param re A Lua string pattern; defaults to '%s+'
-- @param n optional maximum number of splits
-- @return an array of strings
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

ml.lua51 = _VERSION:match '5%.1$'

--- escape any 'magic' pattern characters in a string.
-- Useful for functions like `string.gsub` and `string.match` which
-- always work with Lua string patterns.
-- For any s, `s:match('^'..escape(s)..'$') == s` is `true`.
-- @param s The input string
-- @return an escaped string
function ml.escape(s)
    local res = s:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1')
    if ml.lua51 then
        res = res:gsub('%z','%%z')
    end
    return res
end

--- expand a string containing any `${var}` or `$var`.
-- Substitution values should be only numbers or strings.
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
-- @return file contents, or nil,error
function ml.readfile(filename,is_bin)
    local mode = is_bin and 'b' or ''
    local f,err = io.open(filename,'r'..mode)
    if not f then return nil,err end
    local res,err = f:read('*a')
    f:close()
    if not res then return nil,err end
    return res
end

--- write a string to a file,
-- @param filename The file path
-- @param str The string
-- @param is_bin open in binary mode, default false
-- @return true or nil,error
function ml.writefile(filename,str,is_bin)
    local f,err = io.open(filename,'w'..(is_bin or ''))
    if not f then return nil,err end
    f:write(str)
    f:close()
    return true
end

---------------------------------------------------
-- File and Path functions
-- @section file
---------------------------------------------------

--- Does a file exist?
-- @param filename a file path
-- @return the file path, otherwise nil
-- @usage file = exists 'readme' or exists 'readme.txt' or exists 'readme.md'
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

--- split a path into directory and file part.
-- if there's no directory part, the first value will be the empty string.
-- Handles both forward and back-slashes on Windows.
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

--- split a path into root and extension part.
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

local append = table.insert

--- collect a series of values from an interator.
-- @param ... iterator
-- @return array-like table
-- @usage collect(pairs(t)) is the same as keys(t)
function ml.collect (...)
    local res = {}
    for k in ... do append(res,k) end
    return res
end

--- collect from an interator up to a condition.
-- If the function returns true, then collection stops.
-- @param f predicate receiving (value,count)
-- @param ... iterator
-- @return array-like table
function ml.collectuntil (f,...)
    local res,i,pred = {},1,function_arg(f)
    for k in ... do
        if pred(k,i) then break end
        res[i] = k
        i = i + 1
    end
    return res
end

--- collect `n` values from an interator.
-- @param n number of values to collect
-- @param ... iterator
-- @return array-like table
function ml.collectn (n,...)
    return collectuntil(function(k,i) return i > n end,...)
end

--- collect the second value from a iterator.
-- If the second value is `nil`, it won't be collected!
-- @param ... iterator
-- @return array-like table
-- @usage collect2nd(pairs{one=1,two=2}) is {1,2} or {2,1}
function ml.collect2nd (...)
    local res = {}
    for _,v in ... do append(res,v) end
    return res
end

--- extend a table by mapping a function over another table.
-- @param dest destination table
-- @param j start index in destination
-- @param nilv default value to use if function returns `nil`
-- @param f the function
-- @param t source table
-- @param ... extra arguments to function
function ml.mapextend (dest,j,nilv,f,t,...)
    f = function_arg(f)
    if j == -1 then j = #dest + 1 end
    for i = 1,#t do
        local val = f(t[i],...)
        val = val~=nil and val or nilv
        if val ~= nil then
            dest[j] = val
            j = j + 1
        end
    end
    return dest
end

local mapextend = ml.mapextend

--- map a function over an array.
-- The output must always be the same length as the input, so
-- any `nil` values are mapped to `false`.
-- @param f a function of one or more arguments
-- @param t the array
-- @param ... any extra arguments to the function
-- @return a new array with elements `f(t[i],...)`
function ml.imap(f,t,...)
    return mapextend({},1,false,f,t,...)
end

--- apply a function to each element of an array.
-- @param f a function of one or more arguments
-- @param t the array
-- @param ... any extra arguments to the function
-- @return the transformed array
function ml.transform (f,t,...)
    return mapextend(t,1,false,f,t,...)
end

--- map a function over values from two arrays.
-- Length of output is the size of the smallest array.
-- @param f a function of two or more arguments
-- @param t1 first array
-- @param t2 second array
-- @param ... any extra arguments to the function
-- @return a new array with elements `f(t1[i],t2[i],...)`
function ml.imap2(f,t1,t2,...)
    f = function_arg(f)
    local res = {}
    local n = math.min(#t1,#t2)
    for i = 1,n do
        res[i] = f(t1[i],t2[i],...) or false
    end
    return res
end

--- map a function over an array only keeping non-`nil` values.
-- @param f a function of one or more arguments
-- @param t the array
-- @param ... any extra arguments to the function
-- @return a new array with elements `v = f(t[i],...) such that v ~= nil`
function ml.imapfilter (f,t,...)
    return mapextend({},1,nil,f,t,...)
end

--- filter an array using a predicate.
-- @param t a table
-- @param pred a function that must return `nil` or `false`
-- to exclude a value
-- @param ... any extra arguments to the predicate
-- @return a new array such that `pred(t[i])` evaluates as true
function ml.ifilter(t,pred,...)
    local res,k = {},1
    pred = function_arg(pred)
    for i = 1,#t do
        if pred(t[i],...) then
            res[k] = t[i]
            k = k + 1
        end
    end
    return res
end

--- find an item in an array using a predicate.
-- @param t the array
-- @param pred a function of at least one argument
-- @param ... any extra arguments
-- @return the item value, or `nil`
-- @usage ifind({{1,2},{4,5}},'X[1]==Y',4) is {4,5}
function ml.ifind(t,pred,...)
    pred = function_arg(pred)
    for i = 1,#t do
        if pred(t[i],...) then
            return t[i]
        end
    end
end

--- return the index of an item in an array.
-- @param t the array
-- @param value item value
-- @param cmp optional comparison function (default is `X==Y`)
-- @return index, otherwise `nil`
function ml.indexof (t,value,cmp)
    if cmp then cmp = function_arg(cmp) end
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

local function copy_range (dest,index,src,i1,i2)
    local k = index
    for i = i1,i2 do
        dest[k] = src[i]
        k = k + 1
    end
    return dest
end

--- return a slice of an array.
-- Like `string.sub`, the end index may be negative.
-- @param t the array
-- @param i1 the start index, default 1
-- @param i2 the end index, default #t
-- @return an array of `t[i]` for `i` from `i1` to `i2` inclusive
function ml.sub(t,i1,i2)
    i1, i2 = i1 or 1, upper(t,i2)
    return copy_range({},1,t,i1,i2)
end

--- delete a range of values from an array.
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
-- By default, it moves up elements of `dest` to make room.
-- @param dest destination array
-- @param index start index in destination
-- @param src source array
-- @param overwrite write over values
function ml.insertvalues(dest,index,src,overwrite)
    local sz = #src
    if not overwrite then
        for i = #dest,index,-1 do dest[i+sz] = dest[i] end
    end
    copy_range(dest,index,src,1,sz)
end

--- extend an array using values from other tables.
-- @{readme.md.Extracting_and_Mapping}
-- @param t the array to be extended
-- @param ... the other arrays
-- @return the extended array
function ml.extend(t,...)
    for i = 1,select('#',...) do
        ml.insertvalues(t,#t+1,select(i,...),true)
    end
    return t
end

--- make an array of indexed values.
-- Generalized table indexing. Result will only contain
-- values for keys that exist.
-- @param t a table
-- @param keys an array of keys or indices
-- @return an array `L` such that `L[keys[i]]`
-- @usage indexby({one=1,two=2},{'one','three'}) is {1}
-- @usage indexby({10,20,30,40},{2,4}) is {20,40}
function ml.indexby(t,keys)
    local res = {}
    for _,v in pairs(keys) do
        if t[v] ~= nil then
            append(res,t[v])
        end
    end
    return res
end

--- create an array of numbers from start to end.
-- With one argument it goes `1..x1`. `d` may be a
-- floating-point fraction
-- @param x1 start value
-- @param x2 end value
-- @param d increment (default 1)
-- @return array of numbers
-- @usage range(2,10) is {2,3,4,5,6,7,8,9,10}
-- @usage range(5) is {1,2,3,4,5}
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
    return res
end

-- Bring modules or tables into 't`.
-- If `lib` is a string, then it becomes the result of `require`
-- With only one argument, the second argument is assumed to be
-- the `ml` table itself.
-- @param t table to be updated, or current environment
-- @param lib table, module name or `nil` for importing 'ml'
-- @return the updated table
function ml.import(t,...)
    local other
    -- explicit table, or current environment
    -- this isn't quite right - we won't get the calling module's _ENV
    -- this way. But it does prevent execution of the not-implemented setfenv.
    t = t or _ENV or getfenv(2)
    local libs = {}
    if select('#',...)==0 then -- default is to pull in this library!
        libs[1] = ml
    else
        for i = 1,select('#',...) do
            local lib = select(i,...)
            if type(lib) == 'string' then
                local value = _G[lib]
                if not value then -- lazy require!
                    value = require (lib)
                    -- and use the module part of package for the key
                    lib = lib:match '[%w_]+$'
                end
                lib = {[lib]=value}
            end
            libs[i] = lib
        end
    end
    return ml.update(t,table.unpack(libs))
end

--- add the key/value pairs of arrays to the first array.
-- For sets, this is their union. For the same keys,
-- the values from the first table will be overwritten.
-- @param t table to be updated
-- @param ... tables containg more pairs to be added
-- @return the updated table
function ml.update (t,...)
    for i = 1,select('#',...) do
        for k,v in pairs(select(i,...)) do
            t[k] = v
        end
    end
    return t
end

--- make a table from an array of keys and an array of values.
-- @param t an array of keys
-- @param tv an array of values
-- @return a table where `{[t[i]]=tv[i]}`
-- @usage makemap({'power','glory'},{20,30}) is {power=20,glory=30}
function ml.makemap(t,tv)
    local res = {}
    for i = 1,#t do
        res[t[i]] = tv and tv[i] or i
    end
    return res
end

--- make a set from an array.
-- The values are the original array indices.
-- @param t an array of values
-- @return a table where the keys are the indices in the array.
-- @usage invert{'one','two'} is {one=1,two=2}
-- @function ml.invert
ml.invert = ml.makemap

--- extract the keys of a table as an array.
-- @param t a table
-- @return an array of keys
function ml.keys(t)
    return ml.collect(pairs(t))
end

--- are all the values of `other` in `t`?
-- @param t a set
-- @param other a possible subset
-- @treturn bool
function ml.issubset(t,other)
    for k,v in pairs(other) do
        if t[k] == nil then return false end
    end
    return true
end

--- are all the keys of `other` in `t`?
-- @param t a table
-- @param other another table
-- @treturn bool
ml.containskeys = ml.issubset

--- return the number of keys in this table, or members in this set.
-- @param t a table
-- @treturn int key count
function ml.count (t)
    local count = 0
    for k in pairs(t) do count = count + 1 end
    return count
end

--- do these tables have the same keys?
-- THis is set equality.
-- @param t a table
-- @param other a table
-- @return true or false
function ml.equalkeys(t,other)
    return ml.issubset(t,other) and ml.issubset(other,t)
end

---------------------------------------------------
-- Functional helpers.
-- @section function
---------------------------------------------------

--- create a function which will throw an error on failure.
-- @param f a function that returns nil,err if it fails
-- @return an equivalent function that raises an error
function ml.throw(f)
    f = function_arg(f)
    return function(...)
        local r1,r2,r3 = f(...)
        if not r1 then error(r2,2) end
        return r1,r2,r3
    end
end

--- bind the value `v` to the first argument of function `f`.
-- @param f a function of at least one argument
-- @param v a value
-- @return a function of one less argument
-- @usage (bind1(string.match,'hello')('^hell') == 'hell'
function ml.bind1(f,v)
    f = function_arg(f)
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
    f = function_arg(f)
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
    f1 = function_arg(f1)
    f2 = function_arg(f2)
    return function(...)
        return f1(f2(...))
    end
end

--- a function returning the second value of `f`
-- @param f a function returning at least two values
-- @return a function returning second of those values
-- @usage take2(splitpath) is basename
function ml.take2 (f)
    f = function_arg(f)
    return function(...)
        local _,b = f(...)
        return b
    end
end

--- is the object either a function or a callable object?.
-- @param obj Object to check.
-- @return true if callable
function ml.callable (obj)
    return type(obj) == 'function' or getmetatable(obj) and getmetatable(obj).__call
end

--- create a callable from an indexable object.
-- @param t a table or other indexable object.
function ml.map2fun (t)
    return setmetatable({},{
        __call = function(obj,key) return t[key] end
    })
end

--- create an indexable object from a callable.
-- @param f a callable of one argument.
function ml.fun2map (f)
    return setmetatable({},{
        __index = function(obj,key) return f(key) end;
        __newindex = function() error("not writeable!",2) end
    })
end

local function _string_lambda (f)
    local code = 'return function(X,Y,Z) return '..f..' end'
    local chunk = assert(loadstring(code,'tmp'))
    return chunk()
end

local string_lambda

--- defines how we convert something to a callable.
--
-- Currently, anything that matches @{callable} or is a _string lambda_.
-- These are expressions with any of the placeholders, `X`,`Y` or `Z`
-- corresponding to the first, second or third argument to the function.
--
-- This can be overriden by people
-- wishing to extend the idea of 'callable' in this library.
-- @param f a callable or a string lambda.
-- @return a function
-- @raise error if `f` is not callable in any way, or errors in string lambda.
-- @usage function_arg('X+Y')(1,2) == 3
function ml.function_arg(f)
    if type(f) == 'string' then
        if not string_lambda then
            string_lambda = ml.memoize(_string_lambda)
        end
        f = string_lambda(f)
    else
        assert(ml.callable(f),"expecting a function or callable object")
    end
    return f
end

function_arg = ml.function_arg

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
--
-- See  @{readme.md.Classes}
-- The resulting table can be called to make a new object, which invokes
-- an optional constructor named `_init`. If the base
-- class has a constructor, you can call it as the `super()` method.
-- Every class has a `_class` and a maybe-nil `_base` field, which can
-- be accessed through the object.
--
-- All metamethods are inherited.
-- The class is given a function `Klass.classof(obj)`.
-- @param base optional base class
-- @return the callable metatable representing the class
function ml.class(base)
    local klass, base_ctor = {}
    if base then
        ml.import(klass,base)
        klass._base = base
        base_ctor = rawget(base,'_init')
    end
    klass.__index = klass
    klass._class = klass
    klass.classof = function(obj)
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
-- @{readme.md.Array_Class}
--
-- `table` functions: `sort`,`concat`,`insert`,`remove`,`insert` as `append`.
--
-- `ml` functions: `ifilter` as `filter`,`imap` as `map`,`sub`,`indexby`,`range`,
-- `indexof`,`ifind` as `find`,`extend`,`split` and `collect`.
--
-- The `sorted` method returns a sorted copy.
--
-- Concatenation, equality and custom tostring is defined.
--
-- This implementation has covariant methods; so that methods like `map` and `sub`
-- will return an object of the derived type, not `Array`
-- @table Array

local Array

if not rawget(_G,'NO_MICROLIGHT_ARRAY') then

    Array = ml.class()

    local extend, setmetatable, C = ml.extend, setmetatable, ml.compose

    local function set_class (self,res)
        return setmetatable(res,self._class)
    end

    local function awrap (fun)
        return function(self,...) return set_class(self,fun(self,...))  end
    end

    local function awraps (fun)
        return function(self,f,...) return set_class(self,fun(f,self,...))  end
    end

    -- a class is just a table of functions, so we can do wholesale updates!
    ml.import(Array,{
        -- straight from the table library
        concat=table.concat,insert=table.insert,remove=table.remove,append=table.insert,
        -- originals return table; these versions make the tables into arrays.
        filter=awrap(ml.ifilter),sub=awrap(ml.sub), indexby=awrap(ml.indexby),
        map=awraps(ml.imap), map2=awraps(ml.imap2), mapfilter=awraps(ml.imapfilter),
        range=C(Array,ml.range),split=C(Array,ml.split),collect=C(Array,ml.collect),
        indexof=ml.indexof, find=ml.ifind, extend=ml.extend
    })

    -- A constructor can return a _specific_ object
    function Array:_init(t)
        if not t then return nil end  -- no table, make a new one
        if t._class == self._class then  -- was already a Array: copy constructor!
            t = ml.sub(t,1)
        end
        return t
    end

    function Array:sort(f)
        if type(f) ~= "nil" then f = function_arg(f) end
        table.sort(self,f)
        return self
    end

    function Array:sorted(f)
        return self:sub(1):sort(f)
    end

    function Array:foreach(f,...)
        f = function_arg(f)
        for i = 1,#self do f(self[i],...) end
    end

    function Array.mappers (klass,t)
        local method = Array.mapfilter
        if t.__use then
            method = t.__use
            t.__use = nil
        end
        for k,f in pairs(t) do
            klass[k] = ml.bind2(method,function_arg(f))
        end
    end

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
        return set_class(l1,extend({},l1,l2))
    end

end

ml.Array = Array

return ml
