local Token = {}

local tokens = {}

local counter = 0

--- Assigns a unquie id for the given var.
-- This function cannot be called after on_init() or on_load() has run as that is a desync risk.
-- Typically this is used to register functions, so the id can be stored in the global table
-- instead of the function. This is becasue closures cannot be safely stored in the global table.
-- @param  var<any>
-- @return number the unique token for the variable.
function Token.register(var)
    if _LIFECYCLE == 8 then -- Runtime
        error('Calling Token.register after on_init() or on_load() has run is a desync risk.', 2)
    end

    counter = counter + 1

    tokens[counter] = var

    return counter
end
--- Returns current counter
-- Helpful for recurrent functions
function Token.get_counter()
    return counter
end

function Token.get(token_id)
    return tokens[token_id]
end

storage.tokens = {}

function Token.register_global(var)
    local c = #storage.tokens + 1

    storage.tokens[c] = var

    return c
end

function Token.get_global(token_id)
    return storage.tokens[token_id]
end

function Token.set_global(token_id, var)
    storage.tokens[token_id] = var
end

local uid_counter = 100

function Token.uid()
    uid_counter = uid_counter + 1

    return uid_counter
end

return Token
