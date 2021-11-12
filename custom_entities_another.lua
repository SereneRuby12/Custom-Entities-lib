local module = {}
local custom_types = {}
local custom_ents = {}

local custom_entities_t_info = {} --transition info
local custom_entities_t_info_hh = {}
local function set_transition_info(c_type_id, data, slot, mounted) --mounted: false = being held
    table.insert(custom_entities_t_info,
    {
        ["custom_type_id"] = c_type_id,
        ["data"] = data,
        ["slot"] = slot,
        ["mounted"] = mounted
    })
end

local function set_transition_info_hh(c_type_id, data, e_type, hp, cursed, poisoned)
    table.insert(custom_entities_t_info_hh,
    {
        ["custom_type_id"] = c_type_id,
        ["data"] = data,
        ["e_type"] = e_type,
        ["hp"] = hp,
        ["cursed"] = cursed,
        ["poisoned"] = poisoned
    })
end

local function update_customs()
    local is_portal = #get_entities_by_type(ENT_TYPE.FX_PORTAL) > 0 
    for _,c_type in ipairs(custom_types) do
        for uid, c_data in pairs(c_type.entities) do
            local ent = get_entity(uid)
            if ent then
                c_type.update(ent, c_data, c_type, is_portal)
            else
                c_type[uid] = nil
            end
        end
    end
end

local function get_holder_player(ent) -- or hh
    local holder = ent:topmost()
    if holder == ent then
        return nil
    elseif holder.type.search_flags == MASK.PLAYER or holder.type.search_flags == MASK.MOUNT then
        if holder.type.search_flags == MASK.MOUNT then --if the topmost is a mount, that means the true holder is the one riding it
            holder = get_entity(holder.rider_uid)
        end
        return holder
    end
end

local function set_custom_ents_from_previous(companions)
    for i, info in ipairs(custom_entities_t_info) do
        for ip,p in ipairs(players) do
            if p.inventory.player_slot == info.slot then
                local custom_ent
                if info.mounted then
                    custom_ent = p:topmost_mount()
                else
                    custom_ent = p:get_held_entity()
                end
                custom_ents[custom_ent.uid] = custom_types[info.custom_type_id].set_func(custom_ent, info.data)
            end
        end
    end
    for i, uid in ipairs(companions) do
        local ent = get_entity(uid)
        for _, info in pairs(custom_entities_t_info_hh) do --check if linked_companion_parent works like this (-1 when not having parent)
            if ent.type.id == info.e_type and ent.linked_companion_parent ~= -1 and
            ent.health == info.hp and test_flag(ent.more_flags, ENT_MORE_FLAG.CURSED_EFFECT) == info.cursed and
            ent:is_poisoned() == info.poisoned then
                local custom_ent = ent:get_held_entity()
                custom_ents[custom_ent.uid] = custom_types[info.custom_type_id].set_func(custom_ent, info.data)
            end
        end
    end
end

function module.init(game_frame)
    set_callback(function()
        custom_ents = {}
    end, ON.START)
    
    set_callback(function()
        
    end, ON.LEVEL)
    
    if (game_frame) then
        set_callback(function()
            update_customs()
        end, ON.GAMEFRAME)
    else
        set_callback(function()
            update_customs()
        end, ON.FRAME)
    end
    
    set_callback(function()
        if state.loading == 2 and ((state.screen_next == SCREEN.TRANSITION and state.screen ~= SCREEN.SPACESHIP) or state.screen_next == SCREEN.SPACESHIP) then
            for _,c_type in ipairs(custom_types) do
                for uid, c_data in pairs(c_type.entities) do
                    local ent = get_entity(uid)
                    local holder, rider_uid
                    if not ent or ent.state == 24 or ent.last_state == 24 then
                        holder = c_ent.last_holder
                        rider_uid = c_ent.last_rider_uid
                    else
                        holder = get_holder_player(ent)
                        rider_uid = ent.rider_uid
                    end
                    if holder then
                        if holder.inventory.player_slot == -1 then
                            set_transition_info_hh(holder.type.id, holder.health, test_flag(holder.more_flags, ENT_MORE_FLAG.CURSED_EFFECT), holder:is_poisoned())
                        else
                            set_transition_info(holder.inventory.player_slot, false) --the bumble
                        end
                    elseif rider_uid ~= -1 then
                        holder = get_entity(rider_uid)
                        if holder.type.search_flags == MASK.PLAYER then
                            set_transition_info(holder.inventory.player_slot, true)
                        end
                    end
                end
            end
        end
    end, ON.LOADING)
end

function module.new_custom_entity(set_func, update_func, is_item, is_mount, opt_ent_type)
    local custom_id = #custom_types
    custom_types[custom_id] = {
        ["set"] = set_func,
        ["update_callback"] = update_func,
        ["is_item"] = is_item,
        ["is_mount"] = is_mount,
        ["ent_type"] = opt_ent_type,
        ["entities"] = {}
    }
    
    --WIP del update
    if is_item then
        if is_mount then
            custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
                c_type.update_callback(ent, c_data)
                if is_portal then
                    if ent.state ~= 24 and ent.last_state ~= 24 then --24 seems to be the state when entering portal
                        c_ent.last_holder = get_holder_player(ent)
                        c_ent.last_rider_uid = ent.rider_uid
                    end
                end
            end
        else
            custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
                c_type.update_callback(ent, c_data)
                if is_portal then
                    if ent.state ~= 24 and ent.last_state ~= 24 then --24 seems to be the state when entering portal
                        c_ent.last_holder = get_holder_player(ent)
                    end
                end
            end
        end
    elseif is_mount then
        custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
            c_type.update_callback(ent, c_data)
            if is_portal then
                if ent.state ~= 24 and ent.last_state ~= 24 then --24 seems to be the state when entering portal
                    c_ent.last_rider_uid = ent.rider_uid
                end
            end
        end
    else
        custom_types[custom_id].update = function(ent, c_data, c_type)
            c_type.update_callback(ent, c_data)
        end
    end
end