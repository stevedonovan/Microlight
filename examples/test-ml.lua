--package.path = '../?.lua;'..package.path
local ml = require 'ml'
local mlx = require 'mlx'
local Set = mlx.Set

ml.import(_G,ml)

t = {one=1,two=2,10,20,{1,2}}

print(tstring(t))

printf = compose(io.write,string.format)

printf("the answer is %d\n",42)

t = Array{10,20,30}
t:insert(1,5)
t = t:map(function(x) return x*x end)
t:extend {3,2,1}
t = t:sub(2,-2)
print(t)

s1 = Set{1,2,3}
s2 = Set{1,2}
s3 = Set{1,2,3}

assert( s2 < s1, s1 == s3 )


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

function Cat:kind ()
    return 'cat'
end

--- can override if you like...
--~ function Cat:__tostring ()
--~     return "meeoww "..self.name
--~ end

felix = Cat 'felix'

print(felix, felix:kind())

print(Cat.class_of(felix),Animal.class_of(felix))

