--- Base class for all other classes.
--
--  Could have used Giant's Class() but then we'd always need to run
--  from the game. This works in standalone mode too.
--
function cgClass( members, baseClass )

    members = members or {}

    local mt = {
        __metatable = members;
        __index     = members;
    }

    if baseClass ~= nil then
        setmetatable( members, { __index = baseClass } );
    end;
    
    local function new(self, init)
        return setmetatable(init or {}, mt);
    end;

    local function copy(self, ...)
        local newobj = self:new(unpack(arg));
        for n,v in pairs(self) do
            newobj[n] = v;
        end;
        return newobj;
    end;
    
    members.new  = members.new  or new;
    members.copy = members.copy or copy;

    return mt;
end;

