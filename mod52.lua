
local _ENV = require 'ml_module' (nil, -- no wholesale access to _G
    'print','assert','os', -- quoted global values brought in
    'lfs', -- not global, so use require()!
    table -- not quoted, import the whole table into the environment!
    )

function format (s)
    local out = {'Hello',s,'at',os.date('%c'),'here is',lfs.currentdir()}
    return concat(out,' ')
end

function message(s)
    print(format(s))
end

-- no, we didn't bring anything else in
assert(setmetatable == nil)

-- NB return the _module_, not the _environment_!
return _M
