local celib = require "custom_entities"

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

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function get_solids(floors)
    local solids = {}
    for i, v in ipairs(floors) do
        local flags = get_entity_flags(v)
        if test_flag(flags, ENT_FLAG.SOLID) then
            table.insert(solids, v)
        end
    end
    return solids
end

local function grapple_hook_set(ent, _, args) --gun, angle, facing_left
    local custom_data = {
        ["attached"] = false,
        ["chain_draw_id"] = nil,
        ["gun"] = args[1]
    }
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
        ["gun_uid"] = args[1],
        ["hook_uid"] = ent.uid
    }
    custom_data.chain_draw_id = #chains
    local x, y = get_position(ent.uid)
    local extrude = 0.175
    local floors = get_solids(get_entities_overlapping_hitbox(0, MASK.FLOOR | MASK.ACTIVEFLOOR, AABB:new(x-extrude,y+extrude,x+extrude,y-extrude), ent.layer))
    if floors[1] then
        messpect('floor')
        ent.velocityx = 0
        ent.velocityy = 0
        custom_data.attached = true
        attach_entity(floors[1], ent.uid)
        ent.flags = clr_flag(ent.flags, ENT_FLAG.NO_GRAVITY)
    end
    return custom_data
end

local function grapple_hook_update(ent, c_data)
    local hook_x, hook_y, l = get_position(ent.uid)
    
    local g_gun_uid = c_data.gun
    local g_gun = get_entity(g_gun_uid)
    
    if c_data.attached and g_gun and g_gun.overlay then
        local gun_x, gun_y = get_position(g_gun.overlay.uid)
        if distance(ent.uid, g_gun_uid) > 1 then
            local xdist, ydist = hook_x - gun_x, hook_y - gun_y
            if c_data.gun and g_gun.overlay and not (g_gun.overlay.overlay and g_gun.overlay.overlay.type.id == ENT_TYPE.FLOOR_PIPE) then
                local topmost = g_gun.overlay:topmost_mount()
                topmost.velocityx = topmost.velocityx + ((math.abs(xdist) > 1.5 or math.abs(xdist) < 0.2) and xdist*0.01 or (xdist > 0 and 0.02 or -0.02))
                topmost.velocityy = topmost.velocityy + ydist*0.01
                g_gun.overlay.falling_timer = 0
            else
                kill_entity(ent.uid)
            end
        end
    end
    local extrude = 0.15
    if c_data.attached then
        if not ent.overlay then
            if ent.velocityx ~= 0 then
                c_data.attached = false
            else
                kill_entity(ent.uid)
            end
        end
    else
        local floors = get_solids(get_entities_overlapping_hitbox(0, MASK.FLOOR | MASK.ACTIVEFLOOR, AABB:new(hook_x-extrude,hook_y+extrude,hook_x+extrude,hook_y-extrude), ent.layer))
        if floors[1] then
            ent.velocityx = 0
            ent.velocityy = 0
            c_data.attached = true
            attach_entity(floors[1], ent.uid)
            ent.flags = clr_flag(ent.flags, ENT_FLAG.NO_GRAVITY)
        end
    end
end

local hook_id = celib.new_custom_entity(grapple_hook_set, grapple_hook_update)

local function grapple_hook_destroy(c_data)
    if c_data.chain_draw_id then
        chains[c_data.chain_draw_id] = chains[#chains]
        chains[#chains] = nil
    end
end

celib.add_after_destroy_callback(hook_id, grapple_hook_destroy)

local function grapple_gun_set(ent, c_data)
    local custom_data = {
        ["shot"] = false,
        ["attached_uid"] = -1,
        ["being_shot"] = -1,
        ["next_joint_timer"] = 10,
        ["facing_left"] = false,
        ["angle"] = ent.angle
        
    }
    ent:set_texture(grapple_texture_id)
    ent.animation_frame = 0
    --celib.set_custom_entity(ent.uid, chain_id, {-1, -1, false, nil, true})
    return custom_data
end

local function grapple_gun_update(ent, c_data)
    local dist = distance(ent.uid, c_data.attached_uid)
    if c_data.shot and (dist > 10 or dist == -1) then
        ent.animation_frame = 0
        c_data.shot = false
        kill_entity(c_data.attached_uid)
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
    else
        ent.animation_frame = 1
        local x, y, l = get_position(ent.uid)
        local dir = test_flag(ent.flags, ENT_FLAG.FACING_LEFT) and -1 or 1
        local yvel = math.sin(c_data.angle)
        local xvel = math.cos(c_data.angle)
        local hook_uid = spawn(ENT_TYPE.ITEM_ROCK, x+0.15*dir, y, l, xvel*dir, yvel)
        celib.set_custom_entity(hook_uid, hook_id, {ent.uid, c_data.angle, test_flag(ent.flags, ENT_FLAG.FACING_LEFT)})
        c_data.attached_uid = hook_uid
        c_data.shot = true
        c_data.being_shot = 0
    end
end

local grapple_id = celib.new_custom_gun(grapple_gun_set, grapple_gun_update, grapple_gun_shoot, 4, 0.05, 0.025, ENT_TYPE.ITEM_CLONEGUN)

celib.add_custom_shop_chance(grapple_id, celib.CHANCE.COMMON, {celib.SHOP_TYPE.SPECIALTY_SHOP, celib.SHOP_TYPE.TUN, celib.SHOP_TYPE.CAVEMAN})
celib.add_custom_container_chance(grapple_id, celib.CHANCE.COMMON, {ENT_TYPE.ITEM_CRATE, ENT_TYPE.ITEM_PRESENT})

celib.init(true)

set_callback(function(render_ctx, draw_depth)
    if draw_depth == 30 then
        for _, v in ipairs(chains) do
            local hook_x, hook_y = get_render_position(v.hook_uid)
            local gun_x, gun_y = get_render_position(v.gun_uid)
            local dist = distance(v.hook_uid, v.gun_uid)*4
            local xdiff, ydiff = gun_x - hook_x, gun_y - hook_y
            local it_xdiff, it_ydiff = xdiff/dist, ydiff/dist
            for i = 1, math.floor(dist) do
                local ix, iy = hook_x+it_xdiff*i, hook_y+it_ydiff*i
                render_ctx:draw_world_texture(TEXTURE.DATA_TEXTURES_ITEMS_0, 6, 12+i%2, ix-0.5, iy+0.5, ix+0.5, iy-0.5, Color:white())
            end
    end
end
end, ON.RENDER_PRE_DRAW_DEPTH)

register_option_button('grapple_spawn', 'spawn grapple', '', function()
    local x, y, l = get_position(players[1].uid)
    celib.set_custom_entity(spawn(ENT_TYPE.ITEM_CLONEGUN, x, y, l, 0, 0), grapple_id)
end)