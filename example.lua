local c_ent_lib = require "custom_entities"
--TODO: test mounts

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
    ent.color.r, ent.color.g, ent.color.b = 0.5, 0.5, 0.5
    return {
        ["hit_ground"] = test_flag(ent.flags, ENT_MORE_FLAG.HIT_GROUND),
        ["hit_wall"] = test_flag(ent.flags, ENT_MORE_FLAG.HIT_WALL)
    }
end

local function mycustom_item_update(ent, data)
    local hit_ground = test_flag(ent.more_flags, ENT_MORE_FLAG.HIT_GROUND)
    local hit_wall = test_flag(ent.more_flags, ENT_MORE_FLAG.HIT_WALL)
    if (hit_ground and not data.hit_ground) or (hit_wall and not data.hit_wall) then
        local x, y, l = get_position(ent.uid)
        spawn(ENT_TYPE.FX_EXPLOSION, x, y, l, 0, 0)
        ent:destroy()
    end
    data.hit_ground = hit_ground
    data.hit_wall = hit_wall
end

c_ent_lib.init()
local mycustom = c_ent_lib.new_custom_entity(mycustom_set, mycustom_update, false, false)
local mycustom_item = c_ent_lib.new_custom_entity(mycustom_item_set, mycustom_item_update, true, false)
set_callback(function()
    local snakes = get_entities_by_type(ENT_TYPE.MONS_SNAKE)
    for _,uid in ipairs(snakes) do
        if math.random() > 0.01 then
            c_ent_lib.set_custom_entity(uid, mycustom)
        end
    end

    local rocks = get_entities_by_type(ENT_TYPE.ITEM_ROCK)
    for _,uid in ipairs(rocks) do
        if math.random() > 0.4 then
            c_ent_lib.set_custom_entity(uid, mycustom_item)
        end
    end
end, ON.LEVEL)