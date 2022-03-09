meta = {
    name = "Rainbower",
    version = "1.0",
    author = "Estebanfer",
    description = "Example custom pickup that makes you rainbow"
}

local celib = import("estebanfer/custom-entities-library")
--local celib = require "custom_entities"

local colors = {'r', 'g', 'b'}

local function number_to_range(num, min, max)
    if num > max then
        num = (num - max) + min - 1
    elseif num < min then
        num = (num - min) + max + 1
    end
    return num
end

local pickup_id

local function powerup_set_func(ent)
    ent.color.b = 0
    ent.color.g = 0
    return {
        ["color_n"] = 2,
        ["vel"] = math.random()/20+0.01,
        ["up"] = true
    }
end

local function powerup_update_func(ent, data)
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

local function pickup_set_func(ent)
    ent.color.b = 0
    ent.color.g = 0
    celib.set_entity_info_from_custom_id(ent, pickup_id)
    return {
        ["color_n"] = 2,
        ["vel"] = math.random()/20+0.01,
        ["up"] = true
    }
end

local function pickup_update_func(ent, data)
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

local function pickup_picked_func(_, player, _)
    celib.do_pickup_effect(player.uid, TEXTURE.DATA_TEXTURES_FX_SMALL3_0, 8)
end

local powerup_id = celib.new_custom_powerup(powerup_set_func, powerup_update_func, TEXTURE.DATA_TEXTURES_FX_SMALL3_0, 1, 0)

pickup_id = celib.new_custom_pickup(pickup_set_func, pickup_update_func, pickup_picked_func, powerup_id, ENT_TYPE.ITEM_PICKUP_COMPASS)
celib.add_custom_entity_info(pickup_id, "Rainbower", TEXTURE.DATA_TEXTURES_FX_SMALL3_0, 8, 1500, 500)
celib.set_powerup_drop(pickup_id)

local purchasable_pickup_id = celib.new_custom_purchasable_pickup(pickup_set_func, pickup_update_func, pickup_id)

celib.add_custom_container_chance(pickup_id, celib.CHANCE.COMMON, celib.ALL_CONTAINERS)

celib.add_custom_shop_chance(purchasable_pickup_id, celib.CHANCE.COMMON, celib.ALL_SHOPS, true)

celib.init()

set_callback(function()
    local x, y, l = get_position(players[1].uid)
    celib.spawn_custom_entity(pickup_id, x, y, l, 0, 0)
end, ON.START)