local celib = import("estebanfer/custom-entities-library")
--local celib = require "custom_entities"

local ghost_id, powerup_id, pickup_id

---@class GhostPowerup
---@field is_button_held boolean
---@field controlling_ghost boolean
---@field ghost_uid integer

---@class ChainedPlayerGhost
---@field controlling_ghost boolean
---@field just_changed boolean
---@field changing boolean
---@field alpha number
---@field increasing_alpha boolean
---@field chain_id integer
---@field player_uid integer
---@field statemachine integer

---@class GhostChain
---@field ghost_uid integer
---@field player_uid integer
---@field color Color

local mirror_texture_id
do
    local mirror_texture_def = TextureDefinition.new()
    mirror_texture_def.width = 128
    mirror_texture_def.height = 128
    mirror_texture_def.tile_width = 128
    mirror_texture_def.tile_height = 128

    mirror_texture_def.texture_path = "Mirror.png"
    mirror_texture_id = define_texture(mirror_texture_def)
end

---@param ent Button
local function filter_visiblebutton(ent)
    return ent.color.a > 0.5
end

local function filter_shopitem(ent)
    return test_flag(ent.flags, ENT_FLAG.SHOP_ITEM)
end

---@type GhostChain[]
local ghost_chains = {}

local function remove_chain(arr, pos)
    arr[pos] = arr[#arr]
    arr[#arr] = nil
    if arr[pos] then
        local hook_c_data = celib.get_custom_entity(arr[pos].ghost_uid, ghost_id)
        if hook_c_data then
            hook_c_data.chain_id = pos
        end
    end
end

local function powerup_set_func(ent)
    if state.screen ~= SCREEN.TRANSITION then
        local p_num = ent.inventory.player_slot
        local health = state.items.player_inventory[p_num].health 
        state.items.player_inventory[p_num].health = 0

        local x, y = get_position(ent.uid)
        spawn_player(p_num, x, y)
        state.items.player_inventory[p_num].health = health
        local playerghost_uid = -1
        if state.time_level == 0 then
            local playerghosts = get_entities_by_type(ENT_TYPE.ITEM_PLAYERGHOST)
            playerghost_uid = playerghosts[#playerghosts]
            celib.set_custom_entity(playerghost_uid, ghost_id, ent.uid)
        else
            local prev_ghosts = #get_entities_by_type(ENT_TYPE.ITEM_PLAYERGHOST)
            set_timeout(function()
                local playerghosts = get_entities_by_type(ENT_TYPE.ITEM_PLAYERGHOST)
                playerghost_uid = playerghosts[prev_ghosts+1] --make something to make picking two at the same time work?
                celib.custom_types[powerup_id].entities[ent.uid].ghost_uid = playerghost_uid
                celib.set_custom_entity(playerghost_uid, ghost_id, ent.uid)
            end, 1)
        end
        return {
            is_button_held = true,
            controlling_ghost = false,
            ghost_uid = playerghost_uid,
        }
    end
end

---@param ent Player
---@param c_data GhostPowerup
local function powerup_update_func(ent, c_data)
    if test_flag(ent.flags, ENT_FLAG.DEAD) and not ent:has_powerup(ENT_TYPE.ITEM_POWERUP_ANKH) then
        local chain_id = celib.custom_types[ghost_id].entities[c_data.ghost_uid].chain_id
        if ghost_chains[chain_id] then
            remove_chain(ghost_chains, chain_id)
        end

        if state.items.player_count ~= 1 then
            local ghost_uid = c_data.ghost_uid
            local ghost_texture = get_entity(ghost_uid):get_texture()
            set_timeout(function()
                local playerghosts = get_entities_by_type(ENT_TYPE.ITEM_PLAYERGHOST)
                for _, uid in ipairs(playerghosts) do
                    if uid ~= ghost_uid and get_entity(uid):get_texture() == ghost_texture then
                        kill_entity(uid)
                    end
                end
            end, 1)
        end
        celib.unset_custom_entity(c_data.ghost_uid, ghost_id)
        get_entity(c_data.ghost_uid).color.a = 1.0
        return
    end
    local input = state.player_inputs.player_slots[ent.inventory.player_slot].buttons_gameplay
    if input & (BUTTON.DOOR | INPUTS.DOWN) == BUTTON.DOOR then
        if not c_data.is_button_held and c_data.ghost_uid ~= -1 then
            if c_data.controlling_ghost or ent.state ~= CHAR_STATE.ENTERING and (ent.state ~= CHAR_STATE.STANDING
                or (
                    filter_entities(get_entities_overlapping_hitbox(ENT_TYPE.FX_BUTTON, MASK.FX, get_hitbox(ent.uid, 0, 0, 0.31), ent.layer), filter_visiblebutton)[1] == nil
                    and filter_entities(get_entities_overlapping_hitbox(0, MASK.ITEM | MASK.MOUNT | MASK.MONSTER, get_hitbox(ent.uid), ent.layer), filter_shopitem)[1] == nil
                )
            ) then
                if c_data.controlling_ghost then
                    return_input(ent.uid)
                    celib.get_custom_entity(c_data.ghost_uid, ghost_id).just_changed = true
                else
                    celib.get_custom_entity(c_data.ghost_uid, ghost_id).just_changed = true
                    steal_input(ent.uid)
                end
                c_data.controlling_ghost = not c_data.controlling_ghost
            end
            c_data.is_button_held = true
        end
    elseif c_data.is_button_held then
        c_data.is_button_held = false
    end
end


local function pickup_set_func(ent)
    ent:set_texture(mirror_texture_id)
    ent.animation_frame = 0
    ent.hitboxy = 0.27
    add_custom_name(ent.uid, "Ghost Mirror")
    celib.set_price(ent, 500, 20)
end

local function pickup_update_func()
end

local function pickup_picked_func(_, player)
    celib.do_pickup_effect(player.uid, mirror_texture_id, 0)
end

local function update_ghost_color(entity, c_data)
    if c_data.changing then
        if c_data.increasing_alpha then
            c_data.alpha = c_data.alpha + 0.075
            if c_data.alpha >= 0.8 then
                c_data.changing = false
            end
        else
            c_data.alpha = c_data.alpha - 0.075
            if c_data.alpha <= 0.1 then
                c_data.changing = false
            end
        end
        entity.color.a = c_data.alpha
    elseif not c_data.controlling_ghost then
        entity.color.a = 0
        if ghost_chains[c_data.chain_id] then
            remove_chain(ghost_chains, c_data.chain_id)
            c_data.chain_id = -1
        end
    end
end

local function chained_ghost_set(ent, _, _, player_uid)
    return {
        controlling_ghost = false,
        just_changed = false,
        changing = false,
        alpha = 0.0,
        increasing_alpha = false,
        chain_id = -1,
        player_uid = player_uid,
    }
end

---@param ent Player
---@param c_data ChainedPlayerGhost
local function chained_ghost_update(ent, c_data)
    if c_data.controlling_ghost then
        if distance(ent.uid, c_data.player_uid) > 5 then
            local gx, gy = get_position(ent.uid)
            local px, py = get_position(c_data.player_uid)
            local xdist, ydist = px - gx, py - gy
            ent.velocityx = ent.velocityx + xdist*0.005
            ent.velocityy = ent.velocityy + ydist*0.005
        end
    else
        ent.lock_input_timer = 60
    end

    if c_data.just_changed then
        c_data.changing = true
        if c_data.controlling_ghost then
            ent.lock_input_timer = 60
            c_data.increasing_alpha = false
        else
            local px, py = get_position(c_data.player_uid)
            move_entity(ent.uid, px, py+0.8, 0, 0)
            ent.lock_input_timer = 0
            c_data.increasing_alpha = true

            if c_data.chain_id == -1 then
                ghost_chains[#ghost_chains+1] = {
                    player_uid = c_data.player_uid,
                    ghost_uid = ent.uid,
                    color = get_entity(c_data.player_uid):get_heart_color()
                }
                c_data.chain_id = #ghost_chains
            end
        end
        c_data.controlling_ghost = not c_data.controlling_ghost
        c_data.just_changed = false
    end
    update_ghost_color(ent, c_data)
end

powerup_id = celib.new_custom_powerup(powerup_set_func, powerup_update_func, mirror_texture_id, 0, 0)

pickup_id = celib.new_custom_pickup(pickup_set_func, pickup_update_func, pickup_picked_func, powerup_id, ENT_TYPE.ITEM_PICKUP_COMPASS)
celib.set_powerup_drop(powerup_id, pickup_id)

local purchasable_pickup_id = celib.new_custom_purchasable_pickup(pickup_set_func, pickup_update_func, pickup_id)

ghost_id = celib.new_custom_entity(chained_ghost_set, chained_ghost_update, nil, nil, celib.UPDATE_TYPE.POST_STATEMACHINE)

celib.add_custom_container_chance(pickup_id, celib.CHANCE.COMMON, ENT_TYPE.ITEM_GHIST_PRESENT)

celib.add_custom_shop_chance(purchasable_pickup_id, celib.CHANCE.LOW, {celib.SHOP_TYPE.CAVEMAN, celib.SHOP_TYPE.TUN}, true) --celib.CHANCE.COMMON, celib.ALL_SHOPS

set_callback(function()
    local x, y, l = get_position(players[1].uid)
    celib.spawn_custom_entity(pickup_id, x, y, l, 0, 0)
    celib.spawn_custom_entity(pickup_id, x+1, y, l, 0, 0)
end, ON.START)

set_callback(function()
    if state.loading == 2 then
        ghost_chains = {}
    end
end, ON.LOADING)

set_callback(function()
    ghost_chains = {}
end, ON.POST_LEVEL_GENERATION)

set_callback(function(render_ctx, draw_depth)
    if draw_depth == 4 then
        for _, v in ipairs(ghost_chains) do
            local player_x, player_y = get_render_position(v.ghost_uid)
            local ghost_x, ghost_y = get_render_position(v.player_uid)
            local dist = 5*4--distance(v.player_uid, v.ghost_uid)*4
            local xdiff, ydiff = ghost_x - player_x, ghost_y - player_y
            local it_xdiff, it_ydiff = xdiff/dist, ydiff/dist
            for i = 1, math.floor(dist) do
                local color = v.color
                local alpha = get_entity(v.ghost_uid).color.a--0.5 --celib.custom_types[ghost_id].entities[v.ghost_uid].alpha * 0.5
                local ix, iy = player_x+it_xdiff*i, player_y+it_ydiff*i
                render_ctx:draw_world_texture(TEXTURE.DATA_TEXTURES_ITEMS_0, 6, 12+i%2, ix-0.5, iy+0.5, ix+0.5, iy-0.5, Color:new((color.r+1)*0.5, (color.g+1)*0.5, (color.b+1)*0.5, alpha))
            end
        end
    end
end, ON.RENDER_PRE_DRAW_DEPTH)

celib.init()