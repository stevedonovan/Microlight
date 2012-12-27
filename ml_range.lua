-- ml_range.lua (c) 2012 Dirk Laurie, Lua-like MIT licence, except that
--    Steve Donovan is allowed to use the code in any way he likes.

--[[
Usage:

    range = require "ml_range"

 `range(n)` returns {1,2,3,...,n}, with vector semantics. All binary
 operations are term-by-term, with numbers allowed left or right.
 Exponentiation and logical operators are undefined at this stage.
 Sum and product methods, with optional starting values, are supplied.

 The vector class could be useful independently. To gain access to it:
    Vector = getmetatable(range(1))
 Then e.g. Vector{1,2,3,4} creates a vector.

 Some fun can be had with
     debug.setmetatable(1,{__len=range})
 e.g.
    print(2*#10-1) --> {1,3,5,7,9,11,13,15,17,19}
]]

local concat = table.concat
local isnumber = function(x) return type(x)=='number' end
local instance = function (class,obj) return setmetatable(obj,class) end

local Vector
Vector = {
    __unm = function(x) local s=Vector{}
       for k=1,#x do s[k]=-x[k] end
       return s
    end;
    __add = function(x,y) local s=Vector{}
       if isnumber(x) then for k=1,#y do s[k]=x+y[k] end
          elseif isnumber(y) then for k=1,#x do s[k]=x[k]+y end
          else for k=1,#x do s[k]=x[k]+y[k] end
          end
       return s
    end;
    __sub = function(x,y) local s=Vector{}
       if isnumber(x) then for k=1,#y do s[k]=x-y[k] end
          elseif isnumber(y) then for k=1,#x do s[k]=x[k]-y end
          else for k=1,#x do s[k]=x[k]-y[k] end
          end
       return s
    end;
    __mul = function(x,y) local s=Vector{}
       if isnumber(x) then for k=1,#y do s[k]=x*y[k] end
          elseif isnumber(y) then for k=1,#x do s[k]=x[k]*y end
          else for k=1,#x do s[k]=x[k]*y[k] end
          end
       return s
    end;
    __div = function(x,y) local s=Vector{}
       if isnumber(x) then for k=1,#y do s[k]=x/y[k] end
          elseif isnumber(y) then for k=1,#x do s[k]=x[k]/y end
          else for k=1,#x do s[k]=x[k]/y[k] end
          end
       return s
    end;
    __concat = function(x,y) local s=Vector{}
       for k,v in ipairs(x) do s[k]=v end
       if isnumber(x) then insert(s,1,x)
          elseif isnumber(y) then append(s,x)
          else for k,v in ipairs(y) do s[#s+1]=v end
          end
       return s
    end;
    __tostring = function(x) return '{'..concat(x,',')..'}'
    end;
    sum = function(x,y) local sum=y or 0
       for k,v in ipairs(x) do sum = sum+v end
       return sum
    end;
    prod = function(x,y) local prod=y or 1
       for k,v in ipairs(x) do prod = prod*v end
       return prod
    end;
}
setmetatable(Vector,{__call = instance})
Vector.__index = Vector

local function range(x)
   local s=Vector{}
   for k=1,x do s[k]=k end
   return s
end

return range
