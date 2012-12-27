---------
-- Simple Lua 5.2 module.
-- Thin wrapper around ml.import
--
--    local _ENV = require 'ml_module' (_G)
--    function f1() .. end
--    function f2() .. end
--    return _M
--
-- See mod52.lua for an example of usage
-- @module ml_module

local ml = require 'ml'

return function(G,...)
    local _M, EMT = {}, {}
    local env = {_M=_M}  --> this will become _ENV

    ml.import(env,...)

    EMT.__newindex = function(t,k,v)
        rawset(env,k,v)  -- copy to environment
        _M[k] = v        -- and add to module!
    end

    -- any undefined lookup goes to 'global' table specified
    if G ~= nil then EMT.__index = G  end

    return setmetatable(env,EMT)
end
