local celib = require "custom_entities"
--TODO: add spawns
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

local next_anim_frame = 108
local max_dist = 1

local LEFT_DIR = 9 -- 256
local RIGHT_DIR = 10 -- 512
local UP_DIR = 11 -- 1024
local DOWN_DIR = 12 -- 2048

local chains = {}

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function bsign(bool)
    return bool and 1 or -1
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

local function grapple_hook_set(ent, c_data, args)
    local custom_data = {
        ["attached"] = false,
        ["attached_uid"] = -1,
        ["chain_draw_id"] = nil,
        ["gun"] = args[1]
    }
    ent:set_texture(grapple_texture_id)
    ent.animation_frame = 2
    ent.hitboxx = 0.1
    ent.hitboxy = 0.1
    if args[2] then
        ent.animation_frame = args[2]
        --ent.flags = clr_flag(ent.flags, ENT_FLAG.PASSES_THROUGH_OBJECTS)
        ent.flags = set_flag(ent.flags, ENT_FLAG.NO_GRAVITY)
    end
    if args[3] then
        ent.angle = args[3] * bsign(not args[4])
        ent.flags = args[4] and set_flag(ent.flags, ENT_FLAG.FACING_LEFT) or clr_flag(ent.flags, ENT_FLAG.FACING_LEFT)
    end
    chains[#chains+1] = {
        ["gun_uid"] = args[1],
        ["hook_uid"] = ent.uid
    }
    custom_data.chain_draw_id = #chains
    return custom_data
end

local function sign(num)
    if num > 0 then
        return 1
    elseif num < 0 then
        return -1
    else return 0 end
end

local function grapple_hook_update(ent, c_data)
    local hook_x, hook_y, l = get_position(ent.uid)
    
    local g_gun_uid = c_data.gun
    local gun_x, gun_y = get_position(g_gun_uid)
    local ent2 = get_entity(g_gun_uid)
    
    messpect(gun_x, hook_x, gun_x-hook_x, g_gun_uid)
    messpect(gun_y, hook_y, gun_y-hook_y, g_gun_uid)
    if c_data.attached and gun_x ~= 0 then
        if distance(ent.uid, g_gun_uid) > 1 then
            --local xdist, ydist = math.abs(gun_x - hook_x), math.abs(gun_y - hook_y)
            local xdist, ydist = hook_x - gun_x, hook_y - gun_y
            local xdiff, ydiff = sign(xdist), sign(ydist)
            --local xdiff, ydiff = sign(gun_x - hook_x), sign(gun_y - hook_y)
            local vhook_x, vhook_y = ent.velocityx, ent.velocityy
            local vgun_x, vgun_y = ent2.velocityx, ent2.velocityy
            local dist = math.sqrt((xdist*xdist) + (ydist*ydist))
            local total = math.abs(xdist) + math.abs(ydist)
            local x_ratio, y_ratio = (xdist/total)/2, (ydist/total)/2
            if c_data.gun and ent2.overlay and not (ent2.overlay.overlay and ent2.overlay.overlay.type.id == ENT_TYPE.FLOOR_PIPE) then
                ent2.overlay.velocityx = ent2.overlay.velocityx + xdist*0.01--(xdist*xdist)*xdiff*0.005 --(x_ratio*xdiff)*(x_ratio*xdiff)*0.01
                ent2.overlay.velocityy = ent2.overlay.velocityy + ydist*0.01--(ydist*ydist)*ydiff*0.005 -- (y_ratio*ydiff)*0.01
                ent2.overlay.falling_timer = 0
            else
                kill_entity(ent.uid)
            end
        end
    end
    local extrude = 0.15
    if c_data.attached then
        if not get_entity(c_data.attached_uid) then
            kill_entity(ent.uid)
        end
    else
        local floors = get_solids(get_entities_overlapping_hitbox(0, MASK.FLOOR | MASK.ACTIVEFLOOR, AABB:new(hook_x-extrude,hook_y+extrude,hook_x+extrude,hook_y-extrude), ent.layer))
        messpect(#floors)
        if #floors > 0 then
            ent.velocityx = 0
            ent.velocityy = 0
            c_data.attached = true
            c_data.attached_uid = floors[1]
            attach_entity(floors[1], ent.uid)
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
        ["atached_uid"] = -1,
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
    if c_data.shot and (distance(ent.uid, c_data.atached_uid) > 10 or not get_entity(c_data.atached_uid)) then
        ent.animation_frame = 0
        c_data.shot = false
        kill_entity(c_data.atached_uid)
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
    ent.angle = c_data.angle * bsign(not test_flag(ent.flags, ENT_FLAG.FACING_LEFT))
end

local function grapple_gun_shoot(ent, c_data)
    if c_data.shot then
        ent.animation_frame = 0
        c_data.shot = false
        kill_entity(c_data.atached_uid)
    else
        ent.animation_frame = 1
        local x, y, l = get_position(ent.uid)
        local dir = test_flag(ent.flags, ENT_FLAG.FACING_LEFT) and -1 or 1
        local yvel = math.sin(c_data.angle)
        local xvel = math.cos(c_data.angle)
        local hook_uid = spawn(ENT_TYPE.ITEM_ROCK, x, y, l, xvel*dir, yvel)
        celib.set_custom_entity(hook_uid, hook_id, {ent.uid, 68, c_data.angle, test_flag(ent.flags, ENT_FLAG.FACING_LEFT)})
        c_data.atached_uid = hook_uid
        c_data.shot = true
        c_data.being_shot = 0
    end
end

local grapple_id = celib.new_custom_gun(grapple_gun_set, grapple_gun_update, grapple_gun_shoot, 10, 0.05, 0.025, ENT_TYPE.ITEM_CLONEGUN)

register_option_button('grapple_spawn', 'spawn grapple', '', function()
    local x, y, l = get_position(players[1].uid)
    celib.set_custom_entity(spawn(ENT_TYPE.ITEM_CLONEGUN, x, y, l, 0, 0), grapple_id)
end)
celib.init(true)

set_callback(function(render_ctx, draw_depth)
    if draw_depth == 30 then
        for _, v in ipairs(chains) do
            local hook_x, hook_y = get_render_position(v.hook_uid)
            local gun_x, gun_y = get_render_position(v.gun_uid)
            local dist = distance(v.hook_uid, v.gun_uid)*4
            local floor_dist = math.floor(dist)
            local xdiff, ydiff = gun_x - hook_x, gun_y - hook_y
            local it_xdiff, it_ydiff = xdiff/dist, ydiff/dist
            for i = 1, floor_dist do
                local ix, iy = hook_x+it_xdiff*i, hook_y+it_ydiff*i
                render_ctx:draw_world_texture(TEXTURE.DATA_TEXTURES_ITEMS_0, 6, 12+i%2, ix-0.5, iy+0.5, ix+0.5, iy-0.5, Color:white())
            end
            
            --[[for i, p in ipairs(pl_portal) do
            if p.x ~= -1 and state.camera_layer == p.l then
                if p.drawbox then
                    local alpha = 0.1
                    local xsum = p.horiz and (p.positive and 1 or -1) or 0
                    local ysum = (not p.horiz) and (p.positive and 1 or -1) or 0
                    local left, top, right, bottom = p.drawbox.left + xsum, p.drawbox.top + ysum, p.drawbox.right + xsum, p.drawbox.bottom + ysum
                    for di = 1, 10 do
                        render_ctx:draw_world_texture(portal_items_texture, p.horiz and 0 or 1, p.positive and 1 or 2, left, top, right, bottom, Color:new(using_colors[i][pl_i].r, using_colors[i][pl_i].g, using_colors[i][pl_i].b, alpha))
                        if xsum == -1 then
                            left = left+0.1
                        elseif xsum == 1 then
                            right = right-0.1
                        elseif ysum == -1 then
                            bottom = bottom + 0.1
                        else
                            top = top - 0.1
                        end
                        alpha = alpha + 0.05
                    end
                end
                --render_ctx:draw_world_texture(TEXTURE.DATA_TEXTURES_FLOOR_CAVE_0, 0, 0, p.hitbox, white)
            end
        end]]
    end
end
end, ON.RENDER_PRE_DRAW_DEPTH)
--96 + 12 or 13 chain anim_frame
