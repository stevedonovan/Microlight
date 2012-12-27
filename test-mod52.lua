local m = require 'mod52'

m.message 'you'

-- the module itself only contains the exported functions
-- (sandbox safe)
for k,v in pairs(m) do print(k,v) end
