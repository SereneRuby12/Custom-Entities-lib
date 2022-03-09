meta = {
    name = "Purchasable backpack example",
    version = "WIP",
    author = "Estebanfer",
    description = "Example of a purchasable backpack"
}

local c_ent_lib = import("estebanfer/custom-entities-library")
--local c_ent_lib = require "custom_entities"

local colors = {'r', 'g', 'b'}

local rainbow_cape

local function number_to_range(num, min, max)
    if num > max then
        num = (num - max) + min - 1
    elseif num < min then
        num = (num - min) + max + 1
    end
    return num
end

local function rainbow_cape_set(ent)
    ent.color.b = 0
    ent.color.g = 0
    c_ent_lib.set_entity_info_from_custom_id(ent, rainbow_cape)
    return {
        ["color_n"] = 2,
        ["vel"] = math.random()/20+0.01,
        ["up"] = true
    }
end

local function rainbow_cape_update(ent, data)
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

rainbow_cape = c_ent_lib.new_custom_entity(rainbow_cape_set, rainbow_cape_update, c_ent_lib.CARRY_TYPE.HELD, ENT_TYPE.ITEM_CAPE)
c_ent_lib.add_custom_entity_info(rainbow_cape, "Rainbow cape", TEXTURE.DATA_TEXTURES_ITEMS_0, 40, 10000, 1000)
local rainbow_cape_p = c_ent_lib.new_custom_purchasable_back(rainbow_cape_set, rainbow_cape_update, rainbow_cape, false)

c_ent_lib.add_custom_shop_chance(rainbow_cape_p, c_ent_lib.CHANCE.COMMON, c_ent_lib.ALL_SHOPS, true)

c_ent_lib.init()

set_callback(function()
    local x, y, l = get_position(players[1].uid)
    c_ent_lib.spawn_custom_entity(rainbow_cape, x, y, l, 0, 0)
end, ON.START)