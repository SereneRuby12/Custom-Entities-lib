meta = {
    name = "Custom Entities Library",
    version = "0.8",
    author = "Estebanfer",
    description = "A library for creating custom entities"
}
--TODO: dice shop (PrizeDispenser?), clonegun


local FLAGS_BIT = { --https://github.com/Mr-Auto/spelunky2-lua-libs/blob/main/libraries/flags/flags.lua
0x1,
0x2,
0x4,
0x8,
0x10,
0x20,
0x40,
0x80,
0x100,
0x200,
0x400,
0x800,
0x1000,
0x2000,
0x4000,
0x8000,
0x10000,
0x20000,
0x40000,
0x80000,
0x100000,
0x200000,
0x400000,
0x800000,
0x1000000,
0x2000000,
0x4000000,
0x8000000,
0x10000000,
0x20000000,
0x40000000,
0x80000000,
}
local module = {}
local custom_types = {}

local cb_update, cb_loading, cb_transition, cb_post_room_gen, cb_post_level_gen = -1, -1, -1, -1, -1

local custom_entities_t_info = {} --transition info
local custom_entities_t_info_hh = {}
local custom_entities_t_info_storage = {}
local custom_entities_t_info_cog_ankh = {}
local storage_pos = nil

local CARRY_TYPE = {
    HELD = 1,
    MOUNT = 2,
    BACK = 3,
    POWERUP = 4
}

local function has(arr, item)
    for _, v in ipairs(arr) do
        if v == item then
            return true
        end
    end
    return false
end

local function join(a, b)
    local result = {table.unpack(a)}
    table.move(b, 1, #b, #result + 1, result)
    return result
end

local shop_items = {ENT_TYPE.ITEM_PICKUP_ROPEPILE, ENT_TYPE.ITEM_PICKUP_BOMBBAG, ENT_TYPE.ITEM_PICKUP_BOMBBOX, ENT_TYPE.ITEM_PICKUP_PARACHUTE, ENT_TYPE.ITEM_PICKUP_SPECTACLES, ENT_TYPE.ITEM_PICKUP_SKELETON_KEY, ENT_TYPE.ITEM_PICKUP_COMPASS, ENT_TYPE.ITEM_PICKUP_SPRINGSHOES, ENT_TYPE.ITEM_PICKUP_SPIKESHOES, ENT_TYPE.ITEM_PICKUP_PASTE, ENT_TYPE.ITEM_PICKUP_PITCHERSMITT, ENT_TYPE.ITEM_PICKUP_CLIMBINGGLOVES, ENT_TYPE.ITEM_WEBGUN, ENT_TYPE.ITEM_MACHETE, ENT_TYPE.ITEM_BOOMERANG, ENT_TYPE.ITEM_CAMERA, ENT_TYPE.ITEM_MATTOCK, ENT_TYPE.ITEM_TELEPORTER, ENT_TYPE.ITEM_FREEZERAY, ENT_TYPE.ITEM_METAL_SHIELD, ENT_TYPE.ITEM_PURCHASABLE_CAPE, ENT_TYPE.ITEM_PURCHASABLE_HOVERPACK, ENT_TYPE.ITEM_PURCHASABLE_TELEPORTER_BACKPACK, ENT_TYPE.ITEM_PURCHASABLE_POWERPACK, ENT_TYPE.ITEM_PURCHASABLE_JETPACK, ENT_TYPE.ITEM_PRESENT, ENT_TYPE.ITEM_PICKUP_HEDJET, ENT_TYPE.ITEM_PICKUP_ROYALJELLY, ENT_TYPE.ITEM_ROCK, ENT_TYPE.ITEM_SKULL, ENT_TYPE.ITEM_POT, ENT_TYPE.ITEM_WOODEN_ARROW, ENT_TYPE.ITEM_PICKUP_COOKEDTURKEY}
local shop_guns = {ENT_TYPE.ITEM_SHOTGUN, ENT_TYPE.ITEM_PLASMACANNON, ENT_TYPE.ITEM_FREEZERAY, ENT_TYPE.ITEM_WEBGUN, ENT_TYPE.ITEM_CROSSBOW}
local all_shop_ents = join(shop_items, shop_guns)
local normal_shop_rooms = {ROOM_TEMPLATE.SHOP, ROOM_TEMPLATE.SHOP_LEFT, ROOM_TEMPLATE.SHOP_ENTRANCE_UP, ROOM_TEMPLATE.SHOP_ENTRANCE_UP_LEFT, ROOM_TEMPLATE.SHOP_ENTRANCE_DOWN, ROOM_TEMPLATE.SHOP_ENTRANCE_DOWN_LEFT}
local DICESHOP_ROOMS = {ROOM_TEMPLATE.DICESHOP, ROOM_TEMPLATE.DICESHOP_LEFT, ROOM_TEMPLATE.TUSKDICESHOP, ROOM_TEMPLATE.TUSKDICESHOP_LEFT}
local DICESHOP_ITEMS = {ENT_TYPE.ITEM_PICKUP_BOMBBAG, ENT_TYPE.ITEM_PICKUP_BOMBBOX, ENT_TYPE.ITEM_PICKUP_ROPEPILE, ENT_TYPE.ITEM_PICKUP_COMPASS, ENT_TYPE.ITEM_PICKUP_PASTE, ENT_TYPE.ITEM_PICKUP_PARACHUTE, ENT_TYPE.ITEM_PURCHASABLE_CAPE, ENT_TYPE.ITEM_PICKUP_SPECTACLES, ENT_TYPE.ITEM_PICKUP_CLIMBINGGLOVES, ENT_TYPE.ITEM_PICKUP_PITCHERSMITT, ENT_TYPE.ITEM_PICKUP_SPIKESHOES, ENT_TYPE.ITEM_PICKUP_SPRINGSHOES, ENT_TYPE.ITEM_MACHETE, ENT_TYPE.ITEM_BOOMERANG, ENT_TYPE.ITEM_CROSSBOW, ENT_TYPE.ITEM_SHOTGUN, ENT_TYPE.ITEM_FREEZERAY, ENT_TYPE.ITEM_WEBGUN, ENT_TYPE.ITEM_CAMERA, ENT_TYPE.ITEM_MATTOCK, ENT_TYPE.ITEM_PURCHASABLE_JETPACK, ENT_TYPE.ITEM_PURCHASABLE_HOVERPACK, ENT_TYPE.ITEM_TELEPORTER, ENT_TYPE.ITEM_PURCHASABLE_TELEPORTER_BACKPACK, ENT_TYPE.ITEM_PURCHASABLE_POWERPACK}

local function new_chances()
    return {
        common = {},
        low = {},
        lower = {}
    }
end
local custom_types_shop = {new_chances(), new_chances(), new_chances(), new_chances(), new_chances(), new_chances(), [0] = new_chances(), [13] = new_chances()} --SHOP_TYPE
local custom_types_tun_shop = new_chances()
local custom_types_caveman_shop = new_chances()
local custom_types_diceshop = new_chances()
local custom_types_tuskdiceshop = new_chances()
local custom_shop_items_set = false --if the set_pre_entity_spawn for custom shop items was already set

local custom_types_container = {
    [ENT_TYPE.ITEM_CRATE] = new_chances(),
    [ENT_TYPE.ITEM_PRESENT] = new_chances(),
    [ENT_TYPE.ITEM_GHIST_PRESENT] = new_chances()
}
module.ALL_CONTAINERS = {
    ENT_TYPE.ITEM_CRATE,
    ENT_TYPE.ITEM_PRESENT,
    ENT_TYPE.ITEM_GHIST_PRESENT
}
local custom_container_items_set = false
local nonflammable_backs_callbacks_set = false
local item_draw_callbacks_set = false

local just_burnt, last_burn = 0, 0 --for non_flammable backpacks

--chance type
module.CHANCE = {
    COMMON = "common",
    LOW = "low",
    LOWER = "lower"
}
--SHOP_TYPE
local SHOP_ROOM_TYPES = {
    GENERAL_STORE = 0,
    CLOTHING_SHOP = 1,
    WEAPON_SHOP = 2,
    SPECIALTY_SHOP = 3,
    HIRED_HAND_SHOP = 4,
    PET_SHOP = 5,
    DICESHOP = ROOM_TEMPLATE.DICESHOP, --75
    TUSKDICESHOP = ROOM_TEMPLATE.TUSKDICESHOP,
    TUN = ROOM_TEMPLATE.CURIOSHOP, --77
    CAVEMAN = ROOM_TEMPLATE.CAVEMANSHOP --79
}

module.ALL_SHOPS = {SHOP_ROOM_TYPES.GENERAL_STORE, SHOP_ROOM_TYPES.CLOTHING_SHOP, SHOP_ROOM_TYPES.WEAPON_SHOP, SHOP_ROOM_TYPES.SPECIALTY_SHOP, SHOP_ROOM_TYPES.HIRED_HAND_SHOP, SHOP_ROOM_TYPES.PET_SHOP, SHOP_ROOM_TYPES.DICESHOP, SHOP_ROOM_TYPES.TUSKDICESHOP, SHOP_ROOM_TYPES.TUN, SHOP_ROOM_TYPES.CAVEMAN}

local weapon_info = {
    [ENT_TYPE.ITEM_SHOTGUN] = {
        bullet = ENT_TYPE.ITEM_BULLET,
        bullet_off_y = 0.099998474121094,
        sound = VANILLA_SOUND.ITEMS_SHOTGUN_FIRE,
        shots = 0,
        callb_set = false,
        sound_callb_set = false
    },
    [ENT_TYPE.ITEM_FREEZERAY] = {
        bullet = ENT_TYPE.ITEM_FREEZERAYSHOT,
        bullet_off_y = 0.12000274658203,
        sound = VANILLA_SOUND.ITEMS_FREEZE_RAY,
        shots = 0,
        callb_set = false,
        sound_callb_set = false
    },
    [ENT_TYPE.ITEM_PLASMACANNON] = {
        bullet = ENT_TYPE.ITEM_PLASMACANNON_SHOT,
        bullet_off_y = 0.0,
        sound = VANILLA_SOUND.ITEMS_PLASMA_CANNON,
        shots = 0,
        callb_set = false,
        sound_callb_set = false
    },
    [ENT_TYPE.ITEM_CLONEGUN] = {
        bullet = ENT_TYPE.ITEM_CLONEGUNSHOT,
        bullet_off_y = 0.12000274658203,
        sound = VANILLA_SOUND.ITEMS_CLONE_GUN,
        shots = 0,
        callb_set = false,
        sound_callb_set = false
    },
}

local function set_transition_info(c_type_id, data, slot, carry_type)
    table.insert(custom_entities_t_info,
    {
        custom_type_id = c_type_id,
        data = data,
        slot = slot,
        carry_type = carry_type
    })
end

local function set_transition_info_hh(c_type_id, data, e_type, hp, cursed, poisoned)
    table.insert(custom_entities_t_info_hh,
    {
        custom_type_id = c_type_id,
        data = data,
        e_type = e_type,
        hp = hp,
        cursed = cursed,
        poisoned = poisoned
    })
end

local function set_transition_info_storage(c_type_id, data, e_type)
    if custom_entities_t_info_storage[e_type] then
        table.insert(custom_entities_t_info_storage[e_type], {
            custom_type_id = c_type_id,
            data = data
        })
    else
        custom_entities_t_info_storage[e_type] = {
            {
                custom_type_id = c_type_id,
                data = data
            }
        }
    end
end

local function update_customs()
    local is_portal = #get_entities_by_type(ENT_TYPE.FX_PORTAL) > 0
    for c_type_id, c_type in ipairs(custom_types) do
        for uid, c_data in pairs(c_type.entities) do
            local ent = get_entity(uid)
            if ent then
                c_type.update(ent, c_data, c_type, is_portal, c_type_id)
            else
                if c_type.after_destroy_callback then
                    c_type.after_destroy_callback(c_data)
                end
                c_type.entities[uid] = nil
            end
        end
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
    for _, info in ipairs(custom_entities_t_info) do
        for _, p in ipairs(players) do
            if p.inventory.player_slot == info.slot then
                local custom_ent
                if info.carry_type == CARRY_TYPE.MOUNT then
                    custom_ent = p:topmost_mount()
                elseif info.carry_type == CARRY_TYPE.HELD then
                    custom_ent = p:get_held_entity()
                elseif info.carry_type == CARRY_TYPE.BACK then
                    custom_ent = get_entity(p:worn_backitem())
                elseif info.carry_type == CARRY_TYPE.POWERUP then
                    custom_ent = p
                end
                custom_types[info.custom_type_id].entities[custom_ent.uid] = custom_types[info.custom_type_id].set(custom_ent, info.data)
                break
            end
        end
    end
    for _, info in pairs(custom_entities_t_info_hh) do
        for _, uid in ipairs(companions) do
            local ent = get_entity(uid)
            if ent.type.id == info.e_type and ent.linked_companion_parent ~= -1 and
            ent.health == info.hp and test_flag(ent.more_flags, ENT_MORE_FLAG.CURSED_EFFECT) == info.cursed and
            ent:is_poisoned() == info.poisoned then
                local custom_ent = ent:get_held_entity()
                if custom_ent then
                    custom_types[info.custom_type_id][custom_ent.uid] = custom_types[info.custom_type_id].set(custom_ent, info.data)
                    break
                end
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
                    if c_type.carry_type == CARRY_TYPE.HELD then
                        local ent = get_entity(uid)
                        local holder
                        if not ent or ent.state == 24 or ent.last_state == 24 then
                            holder = c_data.last_holder
                        else
                            holder = ent.overlay
                        end
                        if holder and holder.type.search_flags & MASK.PLAYER == MASK.PLAYER then
                            if holder:worn_backitem() == uid then
                                set_transition_info(c_id, c_data, holder.inventory.player_slot, CARRY_TYPE.BACK)
                            elseif holder.inventory.player_slot == -1 then
                                set_transition_info_hh(c_id, c_data, holder.type.id, holder.health, test_flag(holder.more_flags, ENT_MORE_FLAG.CURSED_EFFECT), holder:is_poisoned())
                            else
                                set_transition_info(c_id, c_data, holder.inventory.player_slot, CARRY_TYPE.HELD)
                            end
                        elseif ent and is_storage_floor_there and ent.standing_on_uid and get_entity(ent.standing_on_uid).type.id == ENT_TYPE.FLOOR_STORAGE then
                            set_transition_info_storage(c_id, c_data, ent.type.id)
                        end
                    elseif c_type.carry_type == CARRY_TYPE.MOUNT then
                        local ent = get_entity(uid)
                        local holder, rider_uid
                        if not ent or ent.state == 24 or ent.last_state == 24 then
                            holder = c_data.last_holder
                            rider_uid = c_data.last_rider_uid
                        else
                            holder = ent.overlay
                            rider_uid = ent.rider_uid
                        end
                        if holder then
                            if holder.inventory.player_slot == -1 then
                                set_transition_info_hh(c_id, c_data, holder.type.id, holder.health, test_flag(holder.more_flags, ENT_MORE_FLAG.CURSED_EFFECT), holder:is_poisoned())
                            else
                                set_transition_info(c_id, c_data, holder.inventory.player_slot, CARRY_TYPE.HELD)
                            end
                        elseif rider_uid and rider_uid ~= -1 then
                            holder = get_entity(rider_uid)
                            if holder and holder.type.search_flags == MASK.PLAYER then
                                set_transition_info(c_id, c_data, holder.inventory.player_slot, CARRY_TYPE.MOUNT)
                            end
                        end
                    elseif c_type.carry_type == CARRY_TYPE.POWERUP then
                        local ent = get_entity(uid)
                        if ent then
                            set_transition_info(c_id, c_data, ent.inventory.player_slot, CARRY_TYPE.POWERUP)
                        end
                    end
                end
            end
            if custom_entities_t_info_cog_ankh[1] then
                for _, info in ipairs(custom_entities_t_info_cog_ankh) do
                    messpect('transition_cog', custom_entities_t_info_cog_ankh.custom_type_id)
                    set_transition_info(info.custom_type_id, info.c_data, info.player_slot, CARRY_TYPE.POWERUP)
                end
            end
            custom_entities_t_info_cog_ankh = {}
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

function module.new_custom_entity(set_func, update_func, carry_type, opt_ent_type)
    local custom_id = #custom_types + 1
    custom_types[custom_id] = {
        set = set_func,
        update_callback = update_func,
        carry_type = carry_type,
        ent_type = opt_ent_type,
        entities = {}
    }

    if carry_type == CARRY_TYPE.HELD then
        custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
            c_type.update_callback(ent, c_data)
            if is_portal then
                if ent.state ~= 24 and ent.last_state ~= 24 then --24 seems to be the state when entering portal
                    c_data.last_holder = ent.overlay
                end
            end
        end
    elseif carry_type == CARRY_TYPE.MOUNT then
        custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
            c_type.update_callback(ent, c_data)
            if is_portal then
                if ent.state ~= 24 and ent.last_state ~= 24 then
                    c_data.last_holder = ent.overlay
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
        set = set_func,
        update_callback = update_func,
        carry_type = CARRY_TYPE.HELD,
        ent_type = opt_ent_type,
        shoot = firefunc,
        cooldown = cooldown,
        recoil_x = recoil_x,
        recoil_y = recoil_y,
        entities = {}
    }
    custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
        ent.cooldown = math.max(ent.cooldown, 2)
        local holder = ent.overlay
        if holder and holder.type.search_flags == MASK.PLAYER then --Other entities that can hold guns will never shoot when cooldown isn't zero, so only players, also to prevent activefloors
            if holder:is_button_pressed(BUTTON.WHIP) and ent.cooldown == 2 and holder.state ~= CHAR_STATE.DUCKING and holder.animation_frame ~= 18 then
                ent.cooldown = c_type.cooldown+2
                local recoil_dir = test_flag(holder.flags, ENT_FLAG.FACING_LEFT) and 1 or -1
                holder.velocityx = holder.velocityx + c_type.recoil_x*recoil_dir
                holder.velocityy = holder.velocityy + c_type.recoil_y
                c_type.shoot(ent, c_data)
            end
        end
        c_type.update_callback(ent, c_data)
        if is_portal then
            if ent.state ~= 24 and ent.last_state ~= 24 then
                c_data.last_holder = ent.overlay
            end
        end
    end
    return custom_id
end

local function set_custom_bullet_callback(weapon_id)
    set_pre_entity_spawn(function(entity_type, x, y, layer, overlay_ent, spawn_flags)
        --horizontal offset probably isn't very useful to know cause it changes when being next to a wall
        --freezeray and clonegun bullet offset: 0.5, ~0.12
        --plasmacannon: ~0.3545, 0.0
        --shotgun: ~0.35, ~0.1
        local weapons_left = get_entities_at(weapon_id, MASK.ITEM, x-0.25, y-0.12, layer, 0.4)
        local last_left = #weapons_left
        local weapons = join(weapons_left, get_entities_at(weapon_id, MASK.ITEM, x+0.25, y-0.12, layer, 0.4))
        for _,c_type in ipairs(custom_types) do
            for i, weapon_uid in ipairs(weapons) do
                local c_data = c_type.entities[weapon_uid]
                if c_data and c_type.bulletfunc and weapon_info[c_type.ent_type].bullet == entity_type and (c_data.not_shot and c_data.not_shot ~= 0) then
                    local weapon = get_entity(weapon_uid)
                    local holder = weapon.overlay
                    if holder and ( (holder:is_button_pressed(BUTTON.WHIP) and holder.state ~= CHAR_STATE.DUCKING) or (holder.type.id == ENT_TYPE.MONS_CAVEMAN and holder.velocityy > 0.05 and holder.velocityy < 0.0501 and holder.state == CHAR_STATE.STANDING) ) and weapon.cooldown == 0 then
                        local wx, wy = get_position(weapon_uid)
                        if weapon_info[weapon_id].bullet_off_y+0.001 >= y-wy and weapon_info[weapon_id].bullet_off_y-0.001 <= y-wy
                        and test_flag(weapon.flags, ENT_FLAG.FACING_LEFT) == (i <= last_left) then
                            if c_type.mute_sound then
                                weapon_info[weapon_id].shots = weapon_info[weapon_id].shots + 1
                            end
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

    weapon_info[weapon_id].callb_set = true
end

function module.new_custom_gun2(set_func, update_func, bulletfunc, cooldown, recoil_x, recoil_y, ent_type, mute_sound)
    local custom_id = #custom_types + 1
    custom_types[custom_id] = {
        set = set_func,
        update_callback = update_func,
        carry_type = CARRY_TYPE.HELD,
        ent_type = ent_type,
        bulletfunc = bulletfunc,
        cooldown = cooldown,
        recoil_x = recoil_x,
        recoil_y = recoil_y,
        not_shot = true,
        mute_sound = mute_sound,
        entities = {}
    }
    if not weapon_info[ent_type].callb_set then
        set_custom_bullet_callback(ent_type)
    end
    if mute_sound and not weapon_info[ent_type].sound_callb_set then
        --Crashes sometimes on OL, not on PL
        set_vanilla_sound_callback(weapon_info[ent_type].sound, VANILLA_SOUND_CALLBACK_TYPE.STARTED, function(sound)
            if weapon_info[ent_type].shots > 0 then
                sound:set_volume(0)
                sound:stop()
                weapon_info[ent_type].shots = weapon_info[ent_type].shots - 1
            end
        end)
        weapon_info[ent_type].sound_callb_set = true
    end

    custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
        if ent.type.id == ENT_TYPE.ITEM_SHOTGUN then
            c_data.not_shot = 6
        else
            c_data.not_shot = true
        end
        c_type.update_callback(ent, c_data)
        if is_portal then
            if ent.state ~= 24 and ent.last_state ~= 24 then
                c_data.last_holder = ent.overlay
            end
        end
    end
    return custom_id
end

local function spawn_replacement(ent, custom_id)
    local x, y, l = get_position(ent.uid)
    local vx, vy = get_velocity(ent.uid)
    local replacement_uid = spawn(custom_types[custom_id].ent_type, x, y, l, vx, vy)
    local replacement = get_entity(replacement_uid)
    module.set_custom_entity(replacement_uid, custom_id)
    if ent.overlay and ent.overlay.type.search_flags == MASK.PLAYER then
        messpect(ent.overlay.type.id)
        ent.overlay:pick_up(replacement)
    end
    ent:destroy()
    return replacement
end

local back_warn_sound = get_sound(VANILLA_SOUND.ITEMS_BACKPACK_WARN)
function module.new_custom_purchasable_back(set_func, update_func, toreplace_custom_id, flammable)
    local custom_id = #custom_types + 1
    custom_types[custom_id] = {
        update_callback = update_func,
        entities = {}
    }
    if flammable then
        custom_types[custom_id].ent_type = ENT_TYPE.ITEM_ROCK
        custom_types[custom_id].set = function(ent, c_data, args)
            ent.flags = clr_flag(ent.flags, ENT_FLAG.TAKE_NO_DAMAGE)
            ent.hitboxx = 0.3
            ent.hitboxy = 0.35
            ent.offsety = -0.03
            set_timeout(function()
                custom_types[custom_id].entities[ent.uid].shop_owner = ent.last_owner_uid
            end, 1)
            return set_func(ent, c_data, args)
        end
        custom_types[custom_id].update = function(ent, c_data, c_type)
            if not test_flag(ent.flags, ENT_FLAG.SHOP_ITEM) then
                spawn_replacement(ent, toreplace_custom_id)
                c_data = nil
            else
                local danger_entities = get_entities_overlapping_hitbox({ENT_TYPE.MONS_MAGMAMAN, ENT_TYPE.ITEM_BULLET}, MASK.ANY, get_hitbox(ent.uid), ent.layer)
                if danger_entities[1] or ent.onfire_effect_timer > 0 then
                    messpect(ent.last_owner_uid)
                    back_warn_sound:play()
                    if ent.last_owner_uid ~= -1 and get_entity(ent.last_owner_uid).type.search_flags == MASK.PLAYER then
                        get_entity(c_data.shop_owner).aggro_trigger = true
                    end --TODO: make shopkeeper shoot when not caused by players
                    spawn_replacement(ent, toreplace_custom_id).explosion_trigger = true
                    c_data = nil
                end
                c_type.update_callback(ent, c_data)
            end
        end
    else
        custom_types[custom_id].ent_type = ENT_TYPE.ITEM_ROCK
        custom_types[custom_id].set = function(ent, c_data, args)
            ent.hitboxx = 0.3
            ent.hitboxy = 0.35
            ent.offsety = -0.03
            return set_func(ent, c_data, args)
        end
        custom_types[custom_id].update = function(ent, c_data, c_type)
            if not test_flag(ent.flags, ENT_FLAG.SHOP_ITEM) then
                spawn_replacement(ent, toreplace_custom_id)
                c_data = nil
            else
                c_type.update_callback(ent, c_data)
            end
        end
    end
    return custom_id
end

local function set_nonflammable_backs_callbacks()
    set_pre_entity_spawn(function(_, x, y, layer, _, _)
        if y == -123 then
            return spawn_entity_nonreplaceable(ENT_TYPE.ITEM_ROCK, x, y, layer, 0, 0)
        end
    end, SPAWN_TYPE.SYSTEMIC, MASK.EXPLOSION, ENT_TYPE.FX_EXPLOSION)

    set_vanilla_sound_callback(VANILLA_SOUND.ITEMS_BACKPACK_WARN, VANILLA_SOUND_CALLBACK_TYPE.STARTED, function(sound)
        if just_burnt > 0 and last_burn == get_frame()-1 then
            sound:set_volume(0)
            sound:stop()
            just_burnt = just_burnt - 1
        end
    end)
    nonflammable_backs_callbacks_set = true
end

local yellow = Color:yellow()

function module.new_custom_backpack(set_func, update_func, flammable)
    local custom_id = #custom_types + 1
    custom_types[custom_id] = {
        update_callback = update_func,
        carry_type = CARRY_TYPE.HELD,
        ent_type = ENT_TYPE.ITEM_JETPACK,
        entities = {}
    }
    if flammable then
        custom_types[custom_id].set = set_func
        custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
            local holder = ent.overlay
            if holder and holder.type.search_flags == MASK.PLAYER then
                local backitem_uid = holder:worn_backitem()
                if backitem_uid == ent.uid then
                    ent.fuel = 0
                    c_type.update_callback(ent, c_data, holder)
                    local holding = get_entity(holder.holding_uid)
                    if holding and holding.type.id == ENT_TYPE.ITEM_JETPACK and not c_type.entities[holding.uid] then
                        holder:unequip_backitem()
                        holder:pick_up(holding)
                    end
                elseif not c_type.entities[backitem_uid] then
                    holder:unequip_backitem()
                    holder:pick_up(ent)
                else
                    c_type.update_callback(ent, c_data)
                end
            else
                c_type.update_callback(ent, c_data)
            end
            if is_portal then
                if ent.state ~= 24 and ent.last_state ~= 24 then
                    c_data.last_holder = holder
                end
            end
        end
    else
        custom_types[custom_id].set = function(ent, c_data)
            set_on_kill(ent.uid, function(entity)
                generate_world_particles(PARTICLEEMITTER.ITEM_CRUSHED_SPARKS, entity.uid)
                local x, y = get_position(entity.uid)
                create_illumination(yellow, 1.0, x, y).brightness = 2.0
                move_entity(entity.uid, 0, -123, 0, 0)
            end)
            ent.flags = set_flag(ent.flags, ENT_FLAG.TAKE_NO_DAMAGE)
            return set_func(ent, c_data)
        end
        if not nonflammable_backs_callbacks_set then
            set_nonflammable_backs_callbacks()
        end
        custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
            local holder = ent.overlay
            if holder and holder.type.search_flags == MASK.PLAYER then
                local backitem_uid = holder:worn_backitem()
                if backitem_uid == ent.uid then
                    ent.fuel = 0
                    c_type.update_callback(ent, c_data, holder)

                    local holding = get_entity(holder.holding_uid)
                    if holding and holding.type.id == ENT_TYPE.ITEM_JETPACK and not c_type.entities[holding.uid] then
                        holder:unequip_backitem()
                        ent.flags = clr_flag(ent.flags, ENT_FLAG.PAUSE_AI_AND_PHYSICS)
                        holder:pick_up(holding)
                    end

                    --this helps with preventing backpack warning sounds, not sure if use this, was mainly made for preventing hoverpack behiavour
                    --TODO: decide if remove this (probably yes)
                    if holder.state ~= CHAR_STATE.ENTERING and holder.state ~= CHAR_STATE.EXITING and holder.state ~= CHAR_STATE.CLIMBING and holder.state ~= 24 then
                        if not test_flag(ent.flags, ENT_FLAG.PAUSE_AI_AND_PHYSICS) then
                            ent.flags = set_flag(ent.flags, ENT_FLAG.PAUSE_AI_AND_PHYSICS)
                            ent:set_draw_depth(26)
                        else
                            if test_flag(holder.flags, ENT_FLAG.FACING_LEFT) then
                                ent.flags = set_flag(ent.flags, ENT_FLAG.FACING_LEFT)
                                ent.x = 0.25
                            else
                                ent.flags = clr_flag(ent.flags, ENT_FLAG.FACING_LEFT)
                                ent.x = -0.25
                            end
                        end
                    elseif test_flag(ent.flags, ENT_FLAG.PAUSE_AI_AND_PHYSICS) then
                        ent.flags = clr_flag(ent.flags, ENT_FLAG.PAUSE_AI_AND_PHYSICS)
                    end
                elseif not c_type.entities[backitem_uid] then
                    holder:unequip_backitem()
                    holder:pick_up(ent)
                else
                    c_type.update_callback(ent, c_data)
                end
            else
                c_type.update_callback(ent, c_data)
                if test_flag(ent.flags, ENT_FLAG.PAUSE_AI_AND_PHYSICS) then
                    ent.flags = clr_flag(ent.flags, ENT_FLAG.PAUSE_AI_AND_PHYSICS)
                end
            end
            if ent.explosion_trigger then
                ent.explosion_trigger = false
                ent.explosion_timer = 0
                just_burnt = just_burnt + 1
                last_burn = get_frame()
            end
            if test_flag(ent.flags, ENT_FLAG.DEAD) then
                move_entity(ent.uid, 0, -123, 0, 0)
            elseif is_portal then
                if ent.state ~= 24 and ent.last_state ~= 24 then
                    c_data.last_holder = ent.overlay
                end
            end
        end
    end
    return custom_id
end

local player_items_draw = {{}, {}, {}, {}}
local item_height = 0.04 * (16.0/9.0)
local item_hud_color = Color:white()
item_hud_color.a = 0.4

local function set_item_draw_callbacks()
    if not item_draw_callbacks_set then
        set_callback(function(render_ctx)
            if not test_flag(state.pause, 1) and state.level_flags & (FLAGS_BIT[21] | FLAGS_BIT[22]) == 0 then --(state.screen == SCREEN.LEVEL or state.screen == SCREEN.CAMP) then --state.paused is probably flags, 1 is the pause menu
                for i, v in ipairs(player_items_draw) do
                    for i1, draw_info in ipairs(v) do
                        local y1, x1 = 0.74, -0.95+((i1-1)*0.04)+((i-1)*0.32)
                        --render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_1, 1, 0, x1, y1, x1 + 0.04, y1 - (0.04 * (16.0/9.0)), item_hud_color)
                        render_ctx:draw_screen_texture(draw_info.texture_id, draw_info.row, draw_info.column, x1, y1, x1 + 0.04, y1 - item_height, draw_info.color)
                    end
                end
            end
        end, ON.RENDER_POST_HUD)

        set_callback(function()
            local players_existing = 0
            for _, player in ipairs(players) do
                if test_flag(player.flags, ENT_FLAG.DEAD) and not entity_has_item_type(player.uid, ENT_TYPE.ITEM_POWERUP_ANKH) then
                    if player_items_draw[player.inventory.player_slot][1] then
                        messpect("clear", player.inventory.player_slot)
                        player_items_draw[player.inventory.player_slot] = {}
                        messpect("pid", player_items_draw)
                    end
                end
                players_existing = players_existing | FLAGS_BIT[player.inventory.player_slot]
            end
            for slot=1, state.items.player_count do
                if players_existing & FLAGS_BIT[slot] == 0 then
                    if player_items_draw[slot][1] then
                        messpect("clear", slot)
                        player_items_draw[slot] = {}
                    end
                end
            end
        end, ON.GAMEFRAME)

        set_callback(function()
            player_items_draw = {{}, {}, {}, {}}
        end, ON.PRE_LEVEL_GENERATION)
        item_draw_callbacks_set = true
    end
end

function module.new_item_draw_info(texture_id, row, column, color)
    color = color ~= nil and color or item_hud_color
    return {
        texture_id = texture_id,
        row = row,
        column = column,
        color = color
    }
end

function module.add_player_item_draw(player_num, item_draw_info)
    set_item_draw_callbacks()
    local new_pos = #player_items_draw[player_num]+1
    player_items_draw[player_num][new_pos] = item_draw_info
    return player_num, new_pos
end

function module.new_custom_powerup(set_func, update_func, texture_id, row, column, color)
    local custom_id = #custom_types + 1
    custom_types[custom_id] = {
        update_callback = update_func,
        --custom_pickup_id to be set on set_powerup_drop
        carry_type = CARRY_TYPE.POWERUP,
        entities = {}
    }
    local item_draw_info = module.new_item_draw_info(texture_id, row, column, color)
    custom_types[custom_id].item_draw_info = item_draw_info

    custom_types[custom_id].set = function(ent, prev_c_data)
        module.add_player_item_draw(ent.inventory.player_slot, item_draw_info)
        return set_func(ent, prev_c_data)
    end
    custom_types[custom_id].update = function(ent, c_data, c_type, _, c_type_id)
        c_type.update_callback(ent, c_data)
        if test_flag(ent.flags, ENT_FLAG.DEAD) then
            if not entity_has_item_type(ent.uid, ENT_TYPE.ITEM_POWERUP_ANKH) then
                if state.items.player_count ~= 1 then
                    local x, y, l = get_position(ent.uid)
                    module.spawn_custom_entity(c_type.custom_pickup_id, x, y, l, prng:random_float(PRNG_CLASS.PARTICLES)*0.2-0.1, 0.1)
                end
            end
            c_type.entities[ent.uid] = nil
            messpect(ent:has_powerup(ENT_TYPE.ITEM_POWERUP_ANKH), entity_has_item_type(ent.uid, ENT_TYPE.ITEM_POWERUP_ANKH) )
        else
            if state.theme == THEME.CITY_OF_GOLD and ent.idle_counter == 19 and ent.standing_on_uid ~= -1 and ent:standing_on().type.id == ENT_TYPE.FLOOR_ALTAR and ent:has_powerup(ENT_TYPE.ITEM_POWERUP_ANKH) and ent.stun_timer > 0 then
                custom_entities_t_info_cog_ankh[#custom_entities_t_info_cog_ankh+1] = {
                    custom_type_id = c_type_id,
                    c_data = c_data,
                    player_slot = ent.inventory.player_slot
                }
                c_type.entities[ent.uid] = nil
                messpect('added')
            end
        end
    end
    return custom_id
end

function module.set_powerup_drop(custom_powerup_id, custom_pickup_id)
    custom_types[custom_powerup_id].custom_pickup_id = custom_pickup_id
end

function module.new_custom_pickup(set_func, update_func, pickup_func, custom_powerup_id, opt_ent_type)
    local custom_id = #custom_types + 1
    custom_types[custom_id] = {
        update_callback = update_func,
        pickup_callback = pickup_func,
        custom_powerup_id = custom_powerup_id,
        carry_type = CARRY_TYPE.HELD,
        ent_type = opt_ent_type,
        entities = {}
    }
    custom_types[custom_id].set = function(ent, c_data)
        messpect("set")
        ent.more_flags = set_flag(ent.more_flags, 22)
        return set_func(ent, c_data)
    end
    custom_types[custom_id].update = function(ent, c_data, c_type, is_portal)
        c_type.update_callback(ent, c_data)
        if not test_flag(ent.flags, ENT_FLAG.SHOP_ITEM) and ent.stand_counter > 15 and state.screen ~= SCREEN.TRANSITION then
            for _, player in pairs(players) do
                local has_powerup = custom_types[custom_powerup_id].entities[player.uid]
                if player.health > 0 and (state.items.player_count == 1 or not has_powerup) and player:overlaps_with(ent) then
                    c_type.pickup_callback(ent, player, c_data, has_powerup)
                    if not has_powerup then
                        module.set_custom_entity(player.uid, custom_powerup_id)
                    end
                    ent:destroy()
                    break
                end
            end
        end
        if is_portal then
            if ent.state ~= 24 and ent.last_state ~= 24 then
                c_data.last_holder = ent.overlay
            end
        end
    end
    return custom_id
end

local get_item_sound = get_sound(VANILLA_SOUND.UI_GET_ITEM1)
function module.do_pickup_effect(player_uid, texture_id, animation_frame)
    local pickup_fx = get_entity(spawn_entity_over(ENT_TYPE.FX_PICKUPEFFECT, player_uid, 0, 0))
    if texture_id then
        pickup_fx:set_texture(texture_id)
    end
    pickup_fx.animation_frame = animation_frame
    get_item_sound:play()
    return pickup_fx
end

local function spawn_pickup_replacement(ent, c_data, toreplace_custom_id)
    local powerup_id = custom_types[toreplace_custom_id].custom_powerup_id
    local buyer
    if ent.overlay and ent.overlay.search_flags == MASK.PLAYER then
        buyer = ent.overlay
    else
        for _, player in ipairs(players) do
            if ent:overlaps_with(player) and player.standing_uid ~= -1 and player:is_button_pressed(BUTTON.DOOR) then
                buyer = player
                break
            end
        end
    end
    if buyer then
        local has_powerup = module.get_custom_entity(buyer.uid, powerup_id)
        if has_powerup and state.items.player_count ~= 1 then
            spawn_replacement(ent, toreplace_custom_id)
        else
            if not has_powerup then
                module.set_custom_entity(buyer.uid, powerup_id)
            end
            custom_types[toreplace_custom_id].pickup_callback(ent, buyer, c_data, has_powerup)
            ent:destroy()
        end
    else
        spawn_replacement(ent, toreplace_custom_id)
    end
end

function module.new_custom_purchasable_pickup(set_func, update_func, toreplace_custom_id)
    local custom_id = #custom_types + 1
    custom_types[custom_id] = {
        update_callback = update_func,
        carry_type = CARRY_TYPE.HELD,
        ent_type = ENT_TYPE.ITEM_ROCK,
        entities = {}
    }
    custom_types[custom_id].set = function(ent, c_data)
        messpect("set")
        ent.more_flags = set_flag(ent.more_flags, 22)
        ent.width, ent.height = 1.25, 1.25
        ent.hitboxx, ent.hitboxy = 0.3, 0.38
        ent.offsety = -0.05
        return set_func(ent, c_data)
    end
    custom_types[custom_id].update = function(ent, c_data, c_type, _)
        c_type.update_callback(ent, c_data)
        if not test_flag(ent.flags, ENT_FLAG.SHOP_ITEM) then
            spawn_pickup_replacement(ent, c_data, toreplace_custom_id)
        end
    end
    return custom_id
end

function module.set_custom_entity(uid, custom_ent_id, optional_args)
    local ent = get_entity(uid)
    custom_types[custom_ent_id].entities[uid] = custom_types[custom_ent_id].set(ent, nil, optional_args)
end

function module.spawn_custom_entity(custom_ent_id, x, y, l, vel_x, vel_y, optional_args)
    local uid = spawn(custom_types[custom_ent_id].ent_type, x, y, l, vel_x, vel_y)
    local ent = get_entity(uid)
    custom_types[custom_ent_id].entities[uid] = custom_types[custom_ent_id].set(ent, nil, optional_args)
end

function module.add_after_destroy_callback(custom_ent_id, callback)
    custom_types[custom_ent_id].after_destroy_callback = callback
end

function module.get_custom_entity(ent_uid, custom_ent_id)
    return custom_types[custom_ent_id].entities[ent_uid]
end

local function get_custom_item(custom_types_table)
    if #custom_types_table == 0 then
        return
    end
    local custom_type_id = custom_types_table[prng:random_index(#custom_types_table, PRNG_CLASS.LEVEL_DECO)]
    return custom_type_id, custom_types[custom_type_id].ent_type
end

local function get_custom_item_from_chances(chances_table)
    local chance = prng:random_float(PRNG_CLASS.LEVEL_DECO)
    local custom_type_id, entity_type
    if chance < 0.3 then
        custom_type_id, entity_type = get_custom_item(chances_table.common)
    elseif chance < 0.45 then
        custom_type_id, entity_type = get_custom_item(chances_table.low)
    elseif chance < 0.5 then
        custom_type_id, entity_type = get_custom_item(chances_table.lower)
    end
    return custom_type_id, entity_type
end

local function set_custom_item_spawn_random(shop_type, x, y, l)
    local custom_type_id, entity_type = get_custom_item_from_chances(shop_type)
    if custom_type_id then
        local uid = spawn_entity_nonreplaceable(entity_type, x, y, l, 0, 0)
        module.set_custom_entity(uid, custom_type_id)
        return uid
    end
end

local function set_custom_random_item_roomtype(roomtype, x, y, l)
    if has(normal_shop_rooms, roomtype) then
        return set_custom_item_spawn_random(custom_types_shop[state.level_gen.shop_type], x, y, l)
    elseif roomtype == ROOM_TEMPLATE.CURIOSHOP or roomtype == ROOM_TEMPLATE.CURIOSHOP_LEFT then
        return set_custom_item_spawn_random(custom_types_tun_shop, x, y, l)
    elseif roomtype == ROOM_TEMPLATE.CAVEMANSHOP or roomtype == ROOM_TEMPLATE.CAVEMANSHOP_LEFT then
        return set_custom_item_spawn_random(custom_types_caveman_shop, x, y, l)
    end
end

local function set_custom_shop_spawns() --TODO: do something for purchsasable backpacks when shopkeeper angry
    set_pre_entity_spawn(function(type, x, y, l, overlay)
        if (type == ENT_TYPE.ITEM_SHOTGUN or type == ENT_TYPE.ITEM_CROSSBOW) and y%1 > 0.04 and y%1 < 0.040001 then --when is a shotgun held by shopkeeper cause they're patrolling
            return
        end
        local rx, ry = get_room_index(x, y)
        local roomtype = get_room_template(rx, ry, l)
        if not overlay then --TODO: check if this is necessary? (if not overlay)
            return set_custom_random_item_roomtype(roomtype, x, y, l)
        end
    end, SPAWN_TYPE.LEVEL_GEN, MASK.ITEM, all_shop_ents)
    set_pre_entity_spawn(function(type, x, y, l, overlay)
        messpect("diceshop item", x, y, l) --TODO: check position or if close to PrizeDispenser
        local rx, ry = get_room_index(x, y)
        local roomtype = get_room_template(rx, ry, l)
        if x % 1 == 0 and get_entities_at(ENT_TYPE.ITEM_DICE_PRIZE_DISPENSER, MASK.ANY, x, y, LAYER.FRONT, 0.01)[1] then
            if roomtype == ROOM_TEMPLATE.DICESHOP or roomtype == ROOM_TEMPLATE.DICESHOP_LEFT then
                return set_custom_item_spawn_random(custom_types_diceshop, x, y, l)
            elseif roomtype == ROOM_TEMPLATE.TUSKDICESHOP or roomtype == ROOM_TEMPLATE.TUSKDICESHOP_LEFT then
                return set_custom_item_spawn_random(custom_types_tuskdiceshop, x, y, l)
            end
        end
    end, SPAWN_TYPE.SYSTEMIC, MASK.ITEM, DICESHOP_ITEMS)
    custom_shop_items_set = true
end

local function add_custom_shop_chance(custom_ent_id, chance_type, shop_type)
    if shop_type <= 13 then
        table.insert(custom_types_shop[shop_type][chance_type], custom_ent_id)
    elseif shop_type == SHOP_ROOM_TYPES.TUN then
        table.insert(custom_types_tun_shop[chance_type], custom_ent_id)
    elseif shop_type == SHOP_ROOM_TYPES.CAVEMAN then
        table.insert(custom_types_caveman_shop[chance_type], custom_ent_id)
    elseif shop_type == SHOP_ROOM_TYPES.DICESHOP then
        table.insert(custom_types_diceshop[chance_type], custom_ent_id)
    elseif shop_type == SHOP_ROOM_TYPES.TUSKDICESHOP then
        table.insert(custom_types_tuskdiceshop[chance_type], custom_ent_id)
    end
end

function module.add_custom_shop_chance(custom_ent_id, chance_type, shop_types)
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

local toreplace_crate_content = {
    custom_type_id = nil,
    entity_type = nil
}
local function set_custom_container_spawns()
    set_post_entity_spawn(function(crate)
        local function customize_drop(crate)
            local custom_type_id, entity_type = get_custom_item_from_chances(custom_types_container[crate.type.id])
            if custom_type_id then
                crate.inside = ENT_TYPE.ITEM_TUTORIAL_MONSTER_SIGN
                toreplace_crate_content.custom_type_id = custom_type_id
                toreplace_crate_content.entity_type = entity_type
            end
        end
        set_on_kill(crate.uid, customize_drop)
        set_on_open(crate.uid, customize_drop)
    end, SPAWN_TYPE.ANY, MASK.ANY, {ENT_TYPE.ITEM_CRATE, ENT_TYPE.ITEM_PRESENT, ENT_TYPE.ITEM_GHIST_PRESENT})

    set_pre_entity_spawn(function(_, x, y, layer, _, _) --this is immediately called after the kill or open, will work even when opening many crates at the same time
        if toreplace_crate_content.custom_type_id then
            local uid = spawn(toreplace_crate_content.entity_type, x, y, layer, prng:random_float(PRNG_CLASS.LEVEL_DECO)*0.2-0.1, 0.1)
            module.set_custom_entity(uid, toreplace_crate_content.custom_type_id)

            toreplace_crate_content.custom_type_id = nil
            return uid
        end
    end, SPAWN_TYPE.SYSTEMIC, MASK.ANY, ENT_TYPE.ITEM_TUTORIAL_MONSTER_SIGN)
    custom_container_items_set = true
end

function module.add_custom_container_chance(custom_ent_id, chance_type, container_types)
    if not custom_container_items_set then
        set_custom_container_spawns()
    end
    if type(container_types) == "table" then
        for _, container_type in ipairs(container_types) do
            table.insert(custom_types_container[container_type][chance_type], custom_ent_id)
        end
    else
        table.insert(custom_types_container[container_types][chance_type], custom_ent_id)
    end
end

function module.set_price(entity, base_price, inflation) --made for the set_callback, for some reason you need to wait one frame and get the entity againt to make it work
    set_timeout(function()
        local _, y, l = get_position(entity.uid)
        if test_flag(state.presence_flags, 2) and y < 80 and l == LAYER.BACK then --if black market
            get_entity(entity.uid).price = base_price+inflation
        else
            get_entity(entity.uid).price = base_price+(state.level_count*inflation)
        end
    end, 1)
end

module.custom_types = custom_types
module.SHOP_TYPE = SHOP_ROOM_TYPES
module.CARRY_TYPE = CARRY_TYPE

--register_console_command('get_custom_types', function() return custom_types end)

return module