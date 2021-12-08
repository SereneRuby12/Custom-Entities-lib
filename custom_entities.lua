meta = {
    name = "Custom Entities Library",
    version = "0.5",
    author = "Estebanfer",
    description = "A library for creating custom entities"
}
--TODO: Backpacks
local module = {}
local custom_types = {}

local cb_update, cb_loading, cb_transition, cb_post_room_gen, cb_post_level_gen = -1, -1, -1, -1, -1

local custom_entities_t_info = {} --transition info
local custom_entities_t_info_hh = {}
local custom_entities_t_info_storage = {}
local storage_pos = nil

local function join(a, b)
    local result = {table.unpack(a)}
    table.move(b, 1, #b, #result + 1, result)
    return result
end

local shop_items = {ENT_TYPE.ITEM_PICKUP_ROPEPILE, ENT_TYPE.ITEM_PICKUP_BOMBBAG, ENT_TYPE.ITEM_PICKUP_BOMBBOX, ENT_TYPE.ITEM_PICKUP_PARACHUTE, ENT_TYPE.ITEM_PICKUP_SPECTACLES, ENT_TYPE.ITEM_PICKUP_SKELETON_KEY, ENT_TYPE.ITEM_PICKUP_COMPASS, ENT_TYPE.ITEM_PICKUP_SPRINGSHOES, ENT_TYPE.ITEM_PICKUP_SPIKESHOES, ENT_TYPE.ITEM_PICKUP_PASTE, ENT_TYPE.ITEM_PICKUP_PITCHERSMITT, ENT_TYPE.ITEM_PICKUP_CLIMBINGGLOVES, ENT_TYPE.ITEM_WEBGUN, ENT_TYPE.ITEM_MACHETE, ENT_TYPE.ITEM_BOOMERANG, ENT_TYPE.ITEM_CAMERA, ENT_TYPE.ITEM_MATTOCK, ENT_TYPE.ITEM_TELEPORTER, ENT_TYPE.ITEM_FREEZERAY, ENT_TYPE.ITEM_METAL_SHIELD, ENT_TYPE.ITEM_PURCHASABLE_CAPE, ENT_TYPE.ITEM_PURCHASABLE_HOVERPACK, ENT_TYPE.ITEM_PURCHASABLE_TELEPORTER_BACKPACK, ENT_TYPE.ITEM_PURCHASABLE_POWERPACK, ENT_TYPE.ITEM_PURCHASABLE_JETPACK, ENT_TYPE.ITEM_PRESENT, ENT_TYPE.ITEM_PICKUP_HEDJET, ENT_TYPE.ITEM_PICKUP_ROYALJELLY, ENT_TYPE.ITEM_ROCK, ENT_TYPE.ITEM_SKULL, ENT_TYPE.ITEM_POT, ENT_TYPE.ITEM_WOODEN_ARROW, ENT_TYPE.ITEM_PICKUP_COOKEDTURKEY}
local extra_shop_items = {ENT_TYPE.ITEM_LIGHT_ARROW, ENT_TYPE.ITEM_PICKUP_GIANTFOOD, ENT_TYPE.ITEM_PICKUP_ELIXIR, ENT_TYPE.ITEM_PICKUP_CLOVER, ENT_TYPE.ITEM_PICKUP_SPECIALCOMPASS, ENT_TYPE.ITEM_PICKUP_UDJATEYE, ENT_TYPE.ITEM_PICKUP_KAPALA, ENT_TYPE.ITEM_PICKUP_CROWN, ENT_TYPE.ITEM_PICKUP_EGGPLANTCROWN, ENT_TYPE.ITEM_PICKUP_TRUECROWN, ENT_TYPE.ITEM_PICKUP_ANKH, ENT_TYPE.ITEM_CLONEGUN, ENT_TYPE.ITEM_HOUYIBOW, ENT_TYPE.ITEM_WOODEN_SHIELD, ENT_TYPE.ITEM_LANDMINE, ENT_TYPE.ITEM_SNAP_TRAP} --scepter, vlads cape and the swords don't work
local all_shop_items = join(shop_items, extra_shop_items)
local shop_guns = {ENT_TYPE.ITEM_SHOTGUN, ENT_TYPE.ITEM_PLASMACANNON, ENT_TYPE.ITEM_FREEZERAY, ENT_TYPE.ITEM_WEBGUN, ENT_TYPE.ITEM_CROSSBOW}
local all_shop_ents = join(all_shop_items, shop_guns)
--local shop_rooms = {ROOM_TEMPLATE.SHOP, ROOM_TEMPLATE.SHOP_LEFT, ROOM_TEMPLATE.CURIOSHOP, ROOM_TEMPLATE.CURIOSHOP_LEFT, ROOM_TEMPLATE.CAVEMANSHOP, ROOM_TEMPLATE.CAVEMANSHOP_LEFT}

local function new_shop()
    return {
        ["common"] = {},
        ["low"] = {},
        ["lower"] = {}
    }
end
local custom_types_shop = {new_shop(), new_shop(), new_shop(), new_shop(), new_shop(), new_shop(), [0] = new_shop(), [13] = new_shop} --SHOP_TYPE
local custom_types_tun_shop = new_shop()
local custom_types_caveman_shop = new_shop()
local custom_shop_items_set = false --if the set_pre_entity_spawn for custom shop items was already set

--chance type
module.CHANCE = {
    ["COMMON"] = "common",
    ["LOW"] = "low",
    ["LOWER"] = "lower"
}
--SHOP_TYPE
local SHOP_ROOM_TYPES = {
    ["GENERAL_STORE"] = 0,
    ["CLOTHING_SHOP"] = 1,
    ["WEAPON_SHOP"] = 2,
    ["SPECIALTY_SHOP"] = 3,
    ["HIRED_HAND_SHOP"] = 4,
    ["PET_SHOP"] = 5,
    ["DICE_SHOP"] = 6,
    ["TUSK_DICE_SHOP"] = 13,
    ["TUN"] = 77,
    ["CAVEMAN"] = 79
}

module.ALL_SHOPS = {SHOP_ROOM_TYPES.GENERAL_STORE, SHOP_ROOM_TYPES.CLOTHING_SHOP, SHOP_ROOM_TYPES.WEAPON_SHOP, SHOP_ROOM_TYPES.SPECIALTY_SHOP, SHOP_ROOM_TYPES.HIRED_HAND_SHOP, SHOP_ROOM_TYPES.PET_SHOP, SHOP_ROOM_TYPES.DICE_SHOP, SHOP_ROOM_TYPES.TUSK_DICE_SHOP, SHOP_ROOM_TYPES.TUN, SHOP_ROOM_TYPES.CAVEMAN}

local weapon_info = {
    [ENT_TYPE.ITEM_SHOTGUN] = {
        ["bullet"] = ENT_TYPE.ITEM_BULLET,
        ["bullet_off_y"] = 0.099998474121094,
        ["sound"] = VANILLA_SOUND.ITEMS_SHOTGUN_FIRE,
        ["shots"] = 0,
        ["callb_set"] = false
    },
    [ENT_TYPE.ITEM_FREEZERAY] = {
        ["bullet"] = ENT_TYPE.ITEM_FREEZERAYSHOT,
        ["bullet_off_y"] = 0.12000274658203,
        ["sound"] = VANILLA_SOUND.ITEMS_FREEZE_RAY,
        ["shots"] = 0,
        ["callb_set"] = false
    },
    [ENT_TYPE.ITEM_PLASMACANNON] = {
        ["bullet"] = ENT_TYPE.ITEM_PLASMACANNON_SHOT,
        ["bullet_off_y"] = 0.0,
        ["sound"] = VANILLA_SOUND.ITEMS_PLASMA_CANNON,
        ["shots"] = 0,
        ["callb_set"] = false
    },
    [ENT_TYPE.ITEM_CLONEGUN] = {
        ["bullet"] = ENT_TYPE.ITEM_CLONEGUNSHOT,
        ["bullet_off_y"] = 0.12000274658203,
        ["sound"] = VANILLA_SOUND.ITEMS_CLONE_GUN,
        ["shots"] = 0,
        ["callb_set"] = false
    },
}

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

local function set_transition_info_storage(c_type_id, data, e_type)
    if custom_entities_t_info_storage[e_type] then
        table.insert(custom_entities_t_info_storage[e_type], {
            ["custom_type_id"] = c_type_id,
            ["data"] = data
        })
    else
        custom_entities_t_info_storage[e_type] = {
            {
                ["custom_type_id"] = c_type_id,
                ["data"] = data
            }
        }
    end
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
    local holder = ent:topmost_mount()
    if holder == ent then
        return nil
    elseif holder.type.search_flags == MASK.PLAYER or holder.type.search_flags == MASK.MOUNT then
        if holder.type.search_flags == MASK.MOUNT then --if the topmost is a mount, that means the true holder is the one riding it
            holder = get_entity(holder.rider_uid)
        end
        return holder
    end
end

local function set_custom_items_waddler(items_zone, layer)
    local stored_items = get_entities_overlapping_hitbox(0, MASK.ITEM, items_zone, layer)
    for _, uid in ipairs(stored_items) do
        local ent = get_entity(uid)
        local custom_t_info = custom_entities_t_info_storage[ent.type.id]
        if custom_t_info and custom_t_info[1] then
            custom_types[custom_t_info[1].custom_type_id].entities[uid] = custom_types[custom_t_info[1].custom_type_id].set(ent, custom_t_info[1].data)
            table.remove(custom_entities_t_info_storage[ent.type.id], 1)
        end
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
                custom_types[info.custom_type_id].entities[custom_ent.uid] = custom_types[info.custom_type_id].set(custom_ent, info.data)
            end
        end
    end
    for i, uid in ipairs(companions) do
        local ent = get_entity(uid)
        for _, info in pairs(custom_entities_t_info_hh) do
            if ent.type.id == info.e_type and ent.linked_companion_parent ~= -1 and
            ent.health == info.hp and test_flag(ent.more_flags, ENT_MORE_FLAG.CURSED_EFFECT) == info.cursed and
            ent:is_poisoned() == info.poisoned then
                local custom_ent = ent:get_held_entity()
                custom_types[info.custom_type_id][custom_ent.uid] = custom_types[info.custom_type_id].set(custom_ent, info.data)
            end
        end
    end
    if storage_pos then
        set_custom_items_waddler(AABB:new(storage_pos.x-0.5, storage_pos.y+1.5, storage_pos.x+1.5, storage_pos.y), storage_pos.l)
    end
    storage_pos = nil
end

set_post_tile_code_callback(function(x, y, l) 
    if not storage_pos then
        storage_pos = {['x'] = x, ['y'] = y, ['l'] = l}
    end
end, 'storage_floor')

function module.init(game_frame)
    if (game_frame) then
        cb_update = set_callback(function()
            update_customs()
        end, ON.GAMEFRAME)
    else
        cb_update = set_callback(function()
            update_customs()
        end, ON.FRAME)
    end
    
    cb_loading = set_callback(function()
        local is_storage_floor_there = #get_entities_by_type(ENT_TYPE.FLOOR_STORAGE) > 0
        if state.loading == 2 and ((state.screen_next == SCREEN.TRANSITION and state.screen ~= SCREEN.SPACESHIP) or state.screen_next == SCREEN.SPACESHIP) then
            for c_id,c_type in ipairs(custom_types) do
                for uid, c_data in pairs(c_type.entities) do
                    if c_type.is_item then
                        local ent = get_entity(uid)
                        local holder
                        if not ent or ent.state == 24 or ent.last_state == 24 then
                            holder = c_data.last_holder
                        else
                            holder = get_holder_player(ent)
                        end
                        if holder then
                            if holder.inventory.player_slot == -1 then
                                set_transition_info_hh(c_id, c_data, holder.type.id, holder.health, test_flag(holder.more_flags, ENT_MORE_FLAG.CURSED_EFFECT), holder:is_poisoned())
                            else
                                set_transition_info(c_id, c_data, holder.inventory.player_slot, false) --the bumble
                            end
                        elseif ent and is_storage_floor_there and ent.standing_on_uid and get_entity(ent.standing_on_uid).type.id == ENT_TYPE.FLOOR_STORAGE then
                            set_transition_info_storage(c_id, c_data, ent.type.id)
                        end
                    end
                    if c_type.is_mount then
                        local ent = get_entity(uid)
                        local holder, rider_uid
                        if not ent or ent.state == 24 or ent.last_state == 24 then
                            holder = c_data.last_holder
                            rider_uid = c_data.last_rider_uid
                        else
                            holder = get_holder_player(ent)
                            rider_uid = ent.rider_uid
                        end
                        if holder then
                            if holder.inventory.player_slot == -1 then
                                set_transition_info_hh(c_id, c_data, holder.type.id, holder.health, test_flag(holder.more_flags, ENT_MORE_FLAG.CURSED_EFFECT), holder:is_poisoned())
                            else
                                set_transition_info(c_id, c_data, holder.inventory.player_slot, false)
                            end
                        elseif rider_uid ~= -1 then
                            holder = get_entity(rider_uid)
                            if holder.type.search_flags == MASK.PLAYER then
                                set_transition_info(c_id, c_data, holder.inventory.player_slot, true)
                            end
                        end
                    end
                end
            end
        end
    end, ON.LOADING)
    
    cb_transition = set_callback(function()
        local companions = get_entities_by(0, MASK.PLAYER, LAYER.FRONT)
        set_custom_ents_from_previous(companions)
    end, ON.TRANSITION)
    
    cb_post_level_gen = set_callback(function()
        if state.screen == 12 then
            local px, py, pl = get_position(players[1].uid)
            local companions = get_entities_at(0, MASK.PLAYER, px, py, pl, 2)
            set_custom_ents_from_previous(companions)
            custom_entities_t_info = {} 
            custom_entities_t_info_hh = {}
        end
    end, ON.POST_LEVEL_GENERATION)
    
    cb_post_room_gen = set_callback(function()
        for _,c_type in ipairs(custom_types) do
            c_type.entities = {}
        end
    end, ON.POST_ROOM_GENERATION)
end

function module.stop()
    clear_callback(cb_update)
    clear_callback(cb_loading)
    clear_callback(cb_transition)
    clear_callback(cb_post_level_gen)
    clear_callback(cb_post_room_gen)
end

function module.new_custom_entity(set_func, update_func, is_item, is_mount, opt_ent_type)
    local custom_id = #custom_types + 1
    custom_types[custom_id] = {
        ["set"] = set_func,
        ["update_callback"] = update_func,
        ["is_item"] = is_item,
        ["is_mount"] = is_mount,
        ["ent_type"] = opt_ent_type,
        ["entities"] = {}
    }
    
    if is_item then
        if is_mount then
            custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
                c_type.update_callback(ent, c_data)
                if is_portal then
                    if ent.state ~= 24 and ent.last_state ~= 24 then --24 seems to be the state when entering portal
                        c_data.last_holder = get_holder_player(ent)
                        c_data.last_rider_uid = ent.rider_uid
                    end
                end
            end
        else
            custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
                c_type.update_callback(ent, c_data)
                if is_portal then
                    if ent.state ~= 24 and ent.last_state ~= 24 then --24 seems to be the state when entering portal
                        c_data.last_holder = get_holder_player(ent)
                    end
                end
            end
        end
    elseif is_mount then
        custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
            c_type.update_callback(ent, c_data)
            if is_portal then
                if ent.state ~= 24 and ent.last_state ~= 24 then --24 seems to be the state when entering portal
                    c_data.last_rider_uid = ent.rider_uid
                end
            end
        end
    else
        custom_types[custom_id].update = function(ent, c_data, c_type)
            c_type.update_callback(ent, c_data)
        end
    end
    return custom_id
end

function module.new_custom_gun(set_func, update_func, firefunc, cooldown, recoil_x, recoil_y, opt_ent_type)
    local custom_id = #custom_types + 1
    custom_types[custom_id] = {
        ["set"] = set_func,
        ["update_callback"] = update_func,
        ["is_item"] = true,
        ["is_mount"] = false,
        ["ent_type"] = opt_ent_type,
        ["shoot"] = firefunc,
        ["cooldown"] = cooldown,
        ["recoil_x"] = recoil_x,
        ["recoil_y"] = recoil_y,
        ["entities"] = {}
    }
    custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
        ent.cooldown = math.max(ent.cooldown, 2)
        local holder = ent:topmost_mount()
        if holder ~= ent then
            local holder_input = read_input(holder.uid)
            if holder:is_button_pressed(BUTTON.WHIP) and ent.cooldown == 2 and holder.state ~= CHAR_STATE.DUCKING then
                ent.cooldown = c_type.cooldown+2
                local recoil_dir = test_flag(holder.flags, ENT_FLAG.FACING_LEFT) and 1 or -1
                holder.velocityx = holder.velocityx + c_type.recoil_x*recoil_dir
                holder.velocityy = holder.velocityy + c_type.recoil_y
                c_type.shoot(ent, c_data)
            end
        end
        c_type.update_callback(ent, c_data)
        if is_portal then
            if ent.state ~= 24 and ent.last_state ~= 24 then --24 seems to be the state when entering portal
                c_data.last_holder = get_holder_player(ent)
            end
        end
    end
    return custom_id
end

local function get_entities(tabl)
    for i, uid in ipairs(tabl) do
        tabl[i] = get_entity(uid)
    end
end

local function set_custom_bullet_callback(weapon_id)
    messpect('set_callback', weapon_id)
    set_pre_entity_spawn(function(entity_type, x, y, layer, overlay_ent, spawn_flags)
        --horizontal offset probably isn't very useful to know cause it changes when being next to a wall
        --freezeray and clonegun bullet offset: 0.5, ~0.12
        --plasmacannon: ~0.3545, 0.0
        --shotgun: ~0.35, ~0.1
        local weapons_left = get_entities_at(weapon_id, MASK.ITEM, x-0.25, y-0.12, layer, 0.4)
        local last_left = #weapons_left
        local weapons = join(weapons_left, get_entities_at(weapon_id, MASK.ITEM, x+0.25, y-0.12, layer, 0.4))
        messpect('a', #weapons_left, #weapons)
        for _,c_type in ipairs(custom_types) do
            for i, weapon_uid in ipairs(weapons) do
                local c_data = c_type.entities[weapon_uid]
                if c_data and c_type.bulletfunc and weapon_info[c_type.ent_type].bullet == entity_type and (c_data.not_shot and c_data.not_shot ~= 0) then
                    local weapon = get_entity(weapon_uid)
                    local holder = weapon:topmost()--topmost_mount() topmost_mount only gets the player, not shopkeepers and others
                    set_timeout(function() messpect('has', entity_has_item_type(holder.uid, ENT_TYPE.FX_BIRDIES)) end, 1)
                    messpect(holder:is_button_pressed(BUTTON.WHIP), weapon.cooldown, 'caveman', holder.state, holder.type.id, holder.velocityy)
                    if ( (holder:is_button_pressed(BUTTON.WHIP) and holder.state ~= CHAR_STATE.DUCKING) or (holder.type.id == ENT_TYPE.MONS_CAVEMAN and holder.velocityy > 0.05 and holder.velocityy < 0.0501 and holder.state == CHAR_STATE.STANDING) ) and weapon.cooldown == 0 then
                        local wx, wy = get_position(weapon_uid)
                        messpect(wx-x, y-wy, weapon_info[weapon_id].bullet_off_y+0.001, weapon_info[weapon_id].bullet_off_y-0.001)
                        if weapon_info[weapon_id].bullet_off_y+0.001 >= y-wy and weapon_info[weapon_id].bullet_off_y-0.001 <= y-wy
                        and test_flag(weapon.flags, ENT_FLAG.FACING_LEFT) == (i <= last_left) then
                            weapon_info[weapon_id].shots = weapon_info[weapon_id].shots + 1
                            if entity_type == ENT_TYPE.ITEM_BULLET then
                                c_data.not_shot = c_data.not_shot - 1
                            else
                                c_data.not_shot = false
                            end
                            if c_type.cooldown then
                                weapon.cooldown = c_type.cooldown+2
                            end
                            local recoil_dir = test_flag(holder.flags, ENT_FLAG.FACING_LEFT) and 1 or -1
                            holder.velocityx = holder.velocityx + c_type.recoil_x*recoil_dir
                            holder.velocityy = holder.velocityy + c_type.recoil_y
                            
                            c_type.bulletfunc(weapon, c_data)
                            return spawn_entity(ENT_TYPE.ITEM_BULLET, 0, 0, layer, 0, 0)
                        end
                    end
                end
            end
        end
    end, SPAWN_TYPE.SYSTEMIC, MASK.ITEM, weapon_info[weapon_id].bullet)
    --Crashes sometimes on OL, not on PL
    set_vanilla_sound_callback(weapon_info[weapon_id].sound, VANILLA_SOUND_CALLBACK_TYPE.CREATED, function(soun)
        messpect('started', weapon_id)
        if weapon_info[weapon_id].shots > 0 then --test is weapon_id works?
            messpect(soun)
            soun:set_pitch(0)
            weapon_info[weapon_id].shots = weapon_info[weapon_id].shots - 1
        end
    end)
    
    weapon_info[weapon_id].callb_set = true
end

function module.new_custom_gun2(set_func, update_func, bulletfunc, cooldown, recoil_x, recoil_y, ent_type)
    local custom_id = #custom_types + 1
    custom_types[custom_id] = {
        ["set"] = set_func,
        ["update_callback"] = update_func,
        ["is_item"] = true,
        ["is_mount"] = false,
        ["ent_type"] = ent_type,
        ["bulletfunc"] = bulletfunc,
        ["cooldown"] = cooldown,
        ["recoil_x"] = recoil_x,
        ["recoil_y"] = recoil_y,
        ["not_shot"] = true,
        ["entities"] = {}
    }
    messpect(weapon_info[ent_type], ent_type)
    if not weapon_info[ent_type].callb_set then
        set_custom_bullet_callback(ent_type)
    end
    
    custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
        if ent.type.id == ENT_TYPE.ITEM_SHOTGUN then
            c_data.not_shot = 6
        else
            c_data.not_shot = true
        end
        c_type.update_callback(ent, c_data)
        if is_portal then
            if ent.state ~= 24 and ent.last_state ~= 24 then --24 seems to be the state when entering portal
                c_data.last_holder = get_holder_player(ent)
            end
        end
    end
    return custom_id
end

function module.set_custom_entity(uid, custom_ent_id)
    local ent = get_entity(uid)
    custom_types[custom_ent_id].entities[uid] = custom_types[custom_ent_id].set(ent)
end

local function get_custom_item(custom_types_table)
    if #custom_types_table == 0 then
        return
    end
    local custom_type_id = prng:random_index(#custom_types_table, PRNG_CLASS.LEVEL_DECO)
    for i,v in ipairs(custom_types) do
        messpect(i)
    end
    messpect('id: ', custom_type_id, "type", type(custom_types[custom_type_id]))
    return custom_type_id, custom_types[custom_type_id].ent_type
end

local function set_custom_item_spawn_random(shop_type, x, y, l)
    local chance = prng:random_float(PRNG_CLASS.LEVEL_DECO)
    local custom_type_id, entity_type
    if chance < 0.3 then
        custom_type_id, entity_type = get_custom_item(shop_type.common)
    elseif chance < 0.45 then
        custom_type_id, entity_type = get_custom_item(shop_type.low)
    elseif chance < 0.5 then
        custom_type_id, entity_type = get_custom_item(shop_type.lower)
    end
    if custom_type_id then
        local uid = spawn_entity_nonreplaceable(entity_type, x, y, l, 0, 0)
        module.set_custom_entity(uid, custom_type_id)
        return uid
    end
end

local function set_custom_shop_spawns()
    set_pre_entity_spawn(function(type, x, y, l, overlay)
        --messpect(type, x, y, l, overlay)
        local rx, ry = get_room_index(x, y)
        local roomtype = get_room_template(rx, ry, l)
        if not overlay then
            if roomtype == ROOM_TEMPLATE.SHOP or roomtype == ROOM_TEMPLATE.SHOP_LEFT then
                return set_custom_item_spawn_random(custom_types_shop[state.level_gen.shop_type], x, y, l)
            elseif roomtype == ROOM_TEMPLATE.CURIOSHOP or roomtype == ROOM_TEMPLATE.CURIOSHOP_LEFT then
                return set_custom_item_spawn_random(custom_types_tun_shop, x, y, l)
            elseif roomtype == ROOM_TEMPLATE.CAVEMANSHOP or roomtype == ROOM_TEMPLATE.CAVEMANSHOP_LEFT then
                return set_custom_item_spawn_random(custom_types_caveman_shop, x, y, l)
            end
        end
    end, SPAWN_TYPE.LEVEL_GEN, MASK.ITEM, all_shop_ents)
    custom_shop_items_set = true
end

local function add_custom_shop_chance(custom_ent_id, chance_type, shop_type)
    if shop_type <= 13 then
        messpect(custom_types_shop[shop_type], chance_type)
        table.insert(custom_types_shop[shop_type][chance_type], custom_ent_id)
    elseif shop_type == SHOP_ROOM_TYPES.TUN then
        table.insert(custom_types_tun_shop[chance_type], custom_ent_id)
    elseif shop_type == SHOP_ROOM_TYPES.CAVEMAN then
        table.insert(custom_types_caveman_shop[chance_type], custom_ent_id)
    end
end

function module.set_custom_shop_chance(custom_ent_id, chance_type, shop_types)
    if not custom_shop_items_set then
        set_custom_shop_spawns()
    end
    if type(shop_types) == "table" then
        for _, shop_type in ipairs(shop_types) do
            add_custom_shop_chance(custom_ent_id, chance_type, shop_type)
        end
    else
        add_custom_shop_chance(custom_ent_id, chance_type, shop_types)
    end
end

module.custom_types = custom_types
module.SHOP_TYPE = SHOP_ROOM_TYPES

--register_console_command('get_custom_types', function() return custom_types end)

return module