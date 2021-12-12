local c_ent_lib = require "custom_entities"

local parachute_texture_id
do
    local parachute_texture_def = TextureDefinition.new()
    parachute_texture_def.width = 128
    parachute_texture_def.height = 128
    parachute_texture_def.tile_width = 128
    parachute_texture_def.tile_height = 128
    
    parachute_texture_def.texture_path = "ParachutePack.png"
    parachute_texture_id = define_texture(parachute_texture_def)
end

local function parachute_back_set(ent)
    ent:set_texture(parachute_texture_id)
    ent.animation_frame = 0
    set_post_statemachine(ent.uid, function(ent)
        ent.animation_frame = 0
    end)
    ent.hitboxy = 0.420
    ent.offsety = -0.01
    return {}
end

local function parachute_back_update(ent, c_data, holder) --make a new_backpack in the lib
    ent.color.r = 0.75
    ent.color.g = 0.75
    ent.color.b = 0.75
    if holder and holder.falling_timer > 35 and not holder:has_powerup(ENT_TYPE.ITEM_POWERUP_PARACHUTE) then
        holder:give_powerup(ENT_TYPE.ITEM_POWERUP_PARACHUTE)
    end
end

local function parachute_back_p_set(ent)
    ent.color.r = 0.75
    ent.color.g = 0.75
    ent.color.b = 0.75
    add_custom_name(ent.uid, "ParachutePack")
    c_ent_lib.set_price(ent, 5000, 750)
    return {}
end

local parachute_back = c_ent_lib.new_custom_backpack(parachute_back_set, parachute_back_update, false)
local parachute_back_p = c_ent_lib.new_custom_purchasable_back(parachute_back_p_set, function() end, 43, parachute_back, false)
c_ent_lib.init(true)

c_ent_lib.add_custom_shop_chance(parachute_back_p, c_ent_lib.CHANCE.COMMON, c_ent_lib.ALL_SHOPS)
c_ent_lib.add_custom_container_chance(parachute_back, c_ent_lib.CHANCE.LOW, {ENT_TYPE.ITEM_CRATE, ENT_TYPE.ITEM_PRESENT})

set_callback(function()
    local x, y, l = get_position(players[1].uid)
    c_ent_lib.set_custom_entity(spawn(ENT_TYPE.ITEM_JETPACK, x, y, l, 0, 0), parachute_back)
    c_ent_lib.set_custom_entity(spawn(ENT_TYPE.ITEM_JETPACK, x, y, l, 0, 0), parachute_back)
end, ON.START)