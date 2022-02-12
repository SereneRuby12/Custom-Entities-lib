meta = {
    name = "Custom Entities Lib example",
    version = "WIP",
    author = "Estebanfer",
    description = "Color changing snakes, explsive rocks, and rgb turkeys"
}

local c_ent_lib = require "custom_entities"

local function mycustom_set(ent, data)
    ent.color.r = 0.5
    return {["actualcolor"] = 0.5}
end

local function mycustom_update(ent, data)
    ent.color.r = data.actualcolor
    data.actualcolor = data.actualcolor - 0.01
    if data.actualcolor < 0 then
        data.actualcolor = 1
    end
end

local function mycustom_item_set(ent, data)
    local r,g,b
    if data then
        r, g, b = data.r, data.g, data.b
    else
        r, g, b = math.random(), math.random(), math.random()
    end
    ent.color.r, ent.color.g, ent.color.b = r, g, b
    return {
        ["hit_ground"] = test_flag(ent.flags, ENT_MORE_FLAG.HIT_GROUND),
        ["hit_wall"] = test_flag(ent.flags, ENT_MORE_FLAG.HIT_WALL),
        ["r"] = r,
        ["g"] = g,
        ["b"] = b
    }
end

local function mycustom_item_update(ent, data)
    ent.color.r, ent.color.g, ent.color.b = data.r, data.g, data.b
    local hit_ground = false -- test_flag(ent.more_flags, ENT_MORE_FLAG.HIT_GROUND)
    local hit_wall = test_flag(ent.more_flags, ENT_MORE_FLAG.HIT_WALL)
    if (hit_ground and not data.hit_ground) or (hit_wall and not data.hit_wall) then
        local x, y, l = get_position(ent.uid)
        spawn(ENT_TYPE.FX_EXPLOSION, x, y, l, 0, 0)
        ent:destroy()
    end
    data.hit_ground = hit_ground
    data.hit_wall = hit_wall
end

local colors = {'r', 'g', 'b'}

local function number_to_range(num, min, max)
    if num > max then
        num = (num - max) + min - 1
    elseif num < min then
        num = (num - min) + max + 1
    end
    return num
end

local function custom_mount_set(ent, data)
    ent.color.b = 0
    ent.color.g = 0
    return {
        ["color_n"] = 2,
        ["vel"] = math.random()/20+0.01,
        ["up"] = true
    }
end

local function custom_mount_update(ent, data)
    local color = colors[data.color_n]
    ent.color[color] = data.up and ent.color[color] + data.vel or ent.color[color] - data.vel
    if ent.color[color] <= 0 then
        ent.color[color] = 0
        data.color_n = number_to_range(data.color_n + 2, 1, 3)
        data.up = true
    elseif ent.color[color] >= 1 then
        ent.color[color] = 1
        data.color_n = number_to_range(data.color_n - 1, 1, 3)
        data.up = false
    end
end

c_ent_lib.init()
local mycustom = c_ent_lib.new_custom_entity(mycustom_set, mycustom_update)
local mycustom_item = c_ent_lib.new_custom_entity(mycustom_item_set, mycustom_item_update, c_ent_lib.CARRY_TYPE.HELD)
local custom_mount = c_ent_lib.new_custom_entity(custom_mount_set, custom_mount_update, c_ent_lib.CARRY_TYPE.MOUNT)

local function mycustom_item2_set(ent, data)
    local r,g,b
    if data then
        r, g, b = data.r, data.g, data.b
    else
        r, g, b = math.random(), math.random(), math.random()
    end
    ent.color.r, ent.color.g, ent.color.b = r, g, b
    return {
        ["hit_ground"] = test_flag(ent.flags, ENT_MORE_FLAG.HIT_GROUND),
        ["hit_wall"] = test_flag(ent.flags, ENT_MORE_FLAG.HIT_WALL),
        ["r"] = r,
        ["g"] = g,
        ["b"] = b
    }
end

local function mycustom_item2_update(ent, data)
    ent.color.r, ent.color.g, ent.color.b = data.r, data.g, data.b
    local hit_ground = false -- test_flag(ent.more_flags, ENT_MORE_FLAG.HIT_GROUND)
    local hit_wall = test_flag(ent.more_flags, ENT_MORE_FLAG.HIT_WALL)
    if (hit_ground and not data.hit_ground) or (hit_wall and not data.hit_wall) then
        local x, y, l = get_position(ent.uid)
        c_ent_lib.set_custom_entity(spawn(ENT_TYPE.ITEM_ROCK, x, y, l, 0, 0), mycustom_item)
    end
    data.hit_ground = hit_ground
    data.hit_wall = hit_wall
end
local mycustom_item2 = c_ent_lib.new_custom_entity(mycustom_item2_set, mycustom_item2_update, c_ent_lib.CARRY_TYPE.HELD)

set_callback(function()
    local snakes = get_entities_by_type(ENT_TYPE.MONS_SNAKE)
    for _,uid in ipairs(snakes) do
        if math.random() > 0.01 then
            c_ent_lib.set_custom_entity(uid, mycustom)
        end
    end

    local rocks = get_entities_by_type(ENT_TYPE.ITEM_ROCK)
    for _,uid in ipairs(rocks) do
        if math.random() > 0.1 then
            c_ent_lib.set_custom_entity(uid, mycustom_item)
        end
    end
    local x, y, l = get_position(players[1].uid)
    c_ent_lib.set_custom_entity(spawn(ENT_TYPE.ITEM_ROCK, x, y, l, 0, 0), mycustom_item)
    c_ent_lib.set_custom_entity(spawn_entity_snapped_to_floor(ENT_TYPE.ITEM_SKULL, x, y, l), mycustom_item2)

    local turks = get_entities_by_type(ENT_TYPE.MOUNT_TURKEY)
    for _,uid in ipairs(turks) do
        local ent = get_entity(uid)
        if not ent.overlay and ent.rider_uid == -1 and math.random() > 0.3 then
            c_ent_lib.set_custom_entity(uid, custom_mount)
        end
    end
end, ON.LEVEL)