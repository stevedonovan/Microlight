local ml = require 'ml'

ml.import(_G,ml)

t = {one=1,two=2,10,20,{1,2}}

tdump(t)

--print(tequal({1,2,one=1},{1,2,one=2}))

printf = compose(io.write,string.format)

printf("the answer is %d\n",42)

local Table = {}
Table.__index = Table

function Table.new(t)
    return setmetatable(t or {},Table)
end

local T = Table.new

import(Table,{
    concat=table.concat,sort=table.sort,insert=table.insert,
    ifilter=ml.ifilter,filter=ml.tfilter,index=ml.index,
    tfind=ml.tfind,ifind=ml.ifind,extend=ml.extend,update=ml.update,
})

function Table:imap(f,...) return T(imap(f,self,...)) end
function Table:map(f,...) return T(tmap(f,self,...)) end
Table.sub = compose(T,sub)
--function Table:sub(i1,i2) return T(sub(self,i1,i2)) end

t = Table.new{10,20,30}
t:insert(1,5)
t = t:imap(function(x) return x*x end)
t:extend {3,2,1}
t = t:sub(2,-2)
print(t:concat ',')

Animal = class()

function Animal:_init (name)
    self.name = name
end

function Animal:kind ()
    return 'unknown!'
end

function Animal:__tostring ()
    return "animal "..self.name
end

print(Animal "tiger")

Cat = class(Animal)

--[[
function Cat:_init (name)
    --self._base._init(self,name)
    self:super(name)
end
--]]

function Cat:kind ()
    return 'cat'
end

--~ function Cat:__tostring ()
--~     return "meeoww "..self.name
--~ end

felix = Cat 'felix'

print(felix, felix:kind())

print(Cat.class_of(felix),Animal.class_of(felix))

