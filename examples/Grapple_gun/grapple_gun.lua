meta = {
    name = "Grapple Gun",
    version = "1.0",
    author = "Estebanfer",
    description = "Adds a grapple gun to the game. Sprite from The Henry Stickmin Collection"
}

local celib = import("estebanfer/custom-entities-library")
--local celib = require "custom_entities"

local grapple_texture_id
do
    local grapple_texture_def = TextureDefinition.new()
    grapple_texture_def.width = 384
    grapple_texture_def.height = 128
    grapple_texture_def.tile_width = 128
    grapple_texture_def.tile_height = 128
    
    grapple_texture_def.texture_path = "Grapple_gun.png"
    grapple_texture_id = define_texture(grapple_texture_def)
end

local UP_DIR = 11 -- 1024
local DOWN_DIR = 12 -- 2048

local chains = {}
local level_xsize, level_ysize
local hook_id

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function remove_chain(arr, pos)
    arr[pos] = arr[#arr]
    arr[#arr] = nil
    if arr[pos] then
        local hook_c_data = celib.get_custom_entity(arr[pos].hook_uid, hook_id)
        if hook_c_data then
            hook_c_data.chain_draw_id = pos
        end
    end
end

local function get_co_distances(x1, y1, x2, y2)
    local xdist, ydist = x2 - x1, y2 - y1
    local loop_x, loop_y = false, false
    if state.theme == THEME.COSMIC_OCEAN then
        local loop_xdist, loop_ydist = xdist < 0 and xdist + level_xsize or xdist - level_xsize,
        ydist < 0 and ydist + level_ysize or ydist - level_ysize
        --messpect(x1, loop_xdist, xdist, loop_xdist*loop_xdist, xdist*xdist)
        --messpect(y1, loop_ydist, ydist, loop_ydist*loop_ydist, ydist*ydist)
        if xdist*xdist > loop_xdist*loop_xdist then
            loop_x = true
            xdist = loop_xdist
        end
        if ydist*ydist > loop_ydist*loop_ydist then
            loop_y = true
            ydist = loop_ydist
        end
    end
    return math.sqrt(xdist*xdist+ydist*ydist), xdist, ydist, loop_x, loop_y
end

local function get_co_distance(uid1, uid2)
    local x1, y1 = get_position(uid1)
    local x2, y2 = get_position(uid2)
    local dist, xdist, ydist = get_co_distances(x1, y1, x2, y2)
    return dist, xdist, ydist
end

local function filter_solids(ent)
    return test_flag(ent.flags, ENT_FLAG.SOLID) 
end

local function grapple_hook_set(ent, _, _, args) --gun, angle, facing_left, gun_overlay
    local custom_data = {
        attached = false,
        chain_draw_id = nil,
        gun = args[1]
    }
    ent.last_owner_uid = args[4]
    ent:set_texture(grapple_texture_id)
    ent.animation_frame = 2
    ent.hitboxx = 0.1
    ent.hitboxy = 0.1
    ent.flags = set_flag(ent.flags, ENT_FLAG.NO_GRAVITY)
    ent.invincibility_frames_timer = 5
    if args[2] then
        ent.angle = args[2] * (args[3] and -1 or 1)
        ent.flags = args[3] and set_flag(ent.flags, ENT_FLAG.FACING_LEFT) or clr_flag(ent.flags, ENT_FLAG.FACING_LEFT)
    end
    chains[#chains+1] = {
        gun_uid = args[1],
        hook_uid = ent.uid
    }
    custom_data.chain_draw_id = #chains
    local x, y = get_position(ent.uid)
    local extrude = 0.175
    local floors = filter_entities(get_entities_overlapping_hitbox(0, MASK.FLOOR | MASK.ACTIVEFLOOR, AABB:new(x-extrude,y+extrude,x+extrude,y-extrude), ent.layer), filter_solids)
    if floors[1] then
        ---@type Movable
        local floor = get_entity(floors[1])
        if floor.health and floor.health ~= 0 then
            floor:damage(ent.uid, 1, 0, 0, 0, 0)
            if floor.type.id ~= ENT_TYPE.ACTIVEFLOOR_BONEBLOCK then
                ent.velocityx = 0
                ent.velocityy = 0
                custom_data.attached = true
            end
        else
            ent.velocityx = 0
            ent.velocityy = 0
            custom_data.attached = true
            attach_entity(floors[1], ent.uid)
            ent.flags = clr_flag(ent.flags, ENT_FLAG.NO_GRAVITY)
        end
    end
    return custom_data
end

local function grapple_hook_update(ent, c_data)
    local hook_x, hook_y = get_position(ent.uid)
    
    local g_gun_uid = c_data.gun
    local g_gun = get_entity(g_gun_uid)
    
    if not g_gun then
        kill_entity(ent.uid)
        return
    end
    if c_data.attached and g_gun.overlay and g_gun.overlay.type.search_flags ~= MASK.ACTIVEFLOOR then
        local gun_x, gun_y = get_position(g_gun.overlay.uid)
        local dist, xdist, ydist = get_co_distances(gun_x, gun_y, hook_x, hook_y)
        if dist > 1 then
            --local xdist, ydist = hook_x - gun_x, hook_y - gun_y
            if not (g_gun.overlay.overlay and g_gun.overlay.overlay.type.id == ENT_TYPE.FLOOR_PIPE) then
                ---@type Movable
                local topmost = g_gun.overlay:topmost_mount()
                topmost.velocityx = topmost.velocityx + ((math.abs(xdist) > 1.5 or math.abs(xdist) < 0.2) and xdist*0.01 or (xdist > 0 and 0.02 or -0.02))
                topmost.velocityy = topmost.velocityy + ydist*0.01
                topmost.falling_timer = 0
                if topmost.state == CHAR_STATE.PUSHING then
                    move_entity(topmost.uid, gun_x, gun_y, 0, 0)
                end
            else
                kill_entity(ent.uid)
            end
        end
    end
    local extrude = 0.15
    if c_data.attached then
        if not ent.overlay then
            if ent.velocityx == 0 then
                kill_entity(ent.uid)
            else
                c_data.attached = false
            end
        end
    else
        local floors = filter_entities(get_entities_overlapping_hitbox(0, MASK.FLOOR | MASK.ACTIVEFLOOR, AABB:new(hook_x-extrude,hook_y+extrude,hook_x+extrude,hook_y-extrude), ent.layer), filter_solids)
        if floors[1] then
            local floor_type = get_entity_type(floors[1])
            if floor_type ~= ENT_TYPE.FLOOR_CONVEYORBELT_LEFT and floor_type ~= ENT_TYPE.FLOOR_CONVEYORBELT_RIGHT then
                if floor_type == ENT_TYPE.ACTIVEFLOOR_BONEBLOCK or floor_type == ENT_TYPE.ACTIVEFLOOR_POWDERKEG or floor_type == ENT_TYPE.ACTIVEFLOOR_REGENERATINGBLOCK then
                    get_entity(floors[1]):damage(ent.uid, 1, 0, 0, 0, 0)
                    kill_entity(ent.uid)
                else
                    ent.velocityx = 0
                    ent.velocityy = 0
                    c_data.attached = true
                    attach_entity(floors[1], ent.uid)
                    ent.flags = clr_flag(ent.flags, ENT_FLAG.NO_GRAVITY)
                end
            else
                kill_entity(ent.uid)
            end
        end
    end
end

hook_id = celib.new_custom_entity(grapple_hook_set, grapple_hook_update)

local function grapple_gun_set(ent, _, custom_id)
    local custom_data = {
        shot = false,
        attached_uid = -1,
        being_shot = -1,
        next_joint_timer = 10,
        facing_left = false,
        angle = ent.angle
    }
    celib.set_entity_info_from_custom_id(ent, custom_id)
    return custom_data
end

local function grapple_gun_update(ent, c_data)
    if c_data.attached_uid then
        local dist = get_co_distance(ent.uid, c_data.attached_uid)
        if c_data.shot and (dist > 10 or dist == -1) then
            ent.animation_frame = 0
            c_data.shot = false
            kill_entity(c_data.attached_uid)
        end
    end
    if ent.overlay and ent.overlay.type.search_flags == MASK.PLAYER then
        local input = read_input(ent.overlay.uid)
        if test_flag(input, UP_DIR) then
            c_data.angle = lerp(c_data.angle, math.pi/2-0.01, 0.2)
        elseif test_flag(input, DOWN_DIR) then
            c_data.angle = lerp(c_data.angle, math.pi/(-2)+0.01, 0.2)
        else
            c_data.angle = lerp(c_data.angle, 0, 0.25)
        end
    end
    ent.angle = c_data.angle * (test_flag(ent.flags, ENT_FLAG.FACING_LEFT) and -1 or 1)
end

local function grapple_gun_shoot(ent, c_data)
    if c_data.shot then
        ent.animation_frame = 0
        c_data.shot = false
        kill_entity(c_data.attached_uid)
        c_data.attached_uid = nil
    else
        ent.animation_frame = 1
        local x, y, l = get_position(ent.uid)
        local dir = test_flag(ent.flags, ENT_FLAG.FACING_LEFT) and -1 or 1
        local yvel = math.sin(c_data.angle)
        local xvel = math.cos(c_data.angle)
        local hook_uid = spawn(ENT_TYPE.ITEM_ROCK, x+0.15*dir, y, l, xvel*dir, yvel)
        celib.set_custom_entity(hook_uid, hook_id, {ent.uid, c_data.angle, test_flag(ent.flags, ENT_FLAG.FACING_LEFT), ent.overlay.uid})
        c_data.attached_uid = hook_uid
        c_data.shot = true
        c_data.being_shot = 0
    end
end

local grapple_id = celib.new_custom_gun(grapple_gun_set, grapple_gun_update, grapple_gun_shoot, 4, 0.05, 0.025, ENT_TYPE.ITEM_CLONEGUN)

celib.add_custom_entity_info(grapple_id, "Grapple gun", grapple_texture_id, 0, 6500, 1000)

celib.add_custom_shop_chance(grapple_id, celib.CHANCE.LOW, {celib.SHOP_TYPE.SPECIALTY_SHOP, celib.SHOP_TYPE.TUN, celib.SHOP_TYPE.CAVEMAN}, true)
celib.add_custom_container_chance(grapple_id, celib.CHANCE.LOW, {ENT_TYPE.ITEM_CRATE, ENT_TYPE.ITEM_PRESENT})
celib.add_custom_entity_crust_chance(grapple_id, 0.05)
celib.define_custom_entity_tilecode(grapple_id, "grapple_gun", true)
celib.add_custom_item_to_arena(grapple_id)
celib.enable_arena_customization_settings()

celib.init()

local white = Color:white()
set_callback(function(render_ctx, draw_depth)
    if draw_depth == 30 then
        for chain_i, v in ipairs(chains) do
            local hook_x, hook_y = get_render_position(v.hook_uid)
            local gun_x, gun_y = get_render_position(v.gun_uid)
            if hook_x == 0 or gun_x == 0 then 
                remove_chain(chains, chain_i)
                v = chains[chain_i]
                if not v then return end
                hook_x, hook_y = get_render_position(v.hook_uid)
                gun_x, gun_y = get_render_position(v.gun_uid)
            end
            local dist, xdiff, ydiff, loop_x, loop_y = get_co_distances(hook_x, hook_y, gun_x, gun_y)
            dist = dist*4
            --local xdiff, ydiff = gun_x - hook_x, gun_y - hook_y
            local it_xdiff, it_ydiff = xdiff/dist, ydiff/dist
            if loop_x then
                if xdiff > 0 then
                    hook_x = hook_x - level_xsize
                else
                    hook_x = hook_x + level_xsize
                end
            end
            if loop_y then
                if ydiff > 0 then
                    hook_y = hook_y - level_ysize
                else
                    hook_y = hook_y + level_ysize
                end
            end
            for i = 1, math.floor(dist) do
                local ix, iy = hook_x+it_xdiff*i, hook_y+it_ydiff*i
                render_ctx:draw_world_texture(TEXTURE.DATA_TEXTURES_ITEMS_0, 6, 12+i%2, ix-0.5, iy+0.5, ix+0.5, iy-0.5, white)
            end
        end
    end
end, ON.RENDER_PRE_DRAW_DEPTH)

set_callback(function()
    local x1, y1, x2, y2 = get_bounds()
    level_xsize, level_ysize = x2-x1, y1-y2
    chains = {}
end, ON.POST_ROOM_GENERATION)

register_option_button('grapple_spawn', 'spawn grapple', '', function()
    local x, y, l = get_position(players[1].uid)
    celib.set_custom_entity(spawn(ENT_TYPE.ITEM_CLONEGUN, x, y, l, 0, 0), grapple_id)
end)