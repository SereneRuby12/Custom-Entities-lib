meta = {
    name = "ParachutePack",
    version = "1.0",
    author = "Estebanfer",
    description = "Adds a new backpack with infinite parachutes"
}

local c_ent_lib = import("estebanfer/custom-entities-library")
--local c_ent_lib = require "custom_entities"

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

local parachute_back

local function darker_color(ent)
    ent.color.r = 0.75
    ent.color.g = 0.75
    ent.color.b = 0.75
end

local function parachute_back_set(ent, _, custom_id)
    c_ent_lib.set_entity_info_from_custom_id(ent, custom_id)
    ent.hitboxy = 0.420
    ent.offsety = -0.01
    darker_color(ent)
end

local function parachute_back_update(ent, _, holder)
    darker_color(ent)
    ent.animation_frame = 0
    if holder and holder.falling_timer > 35 and not holder:has_powerup(ENT_TYPE.ITEM_POWERUP_PARACHUTE) then
        holder:give_powerup(ENT_TYPE.ITEM_POWERUP_PARACHUTE)
    end
end

local function parachute_back_p_set(ent)
    darker_color(ent)
    ent.animation_frame = 43
    add_custom_name(ent.uid, "ParachutePack")
    c_ent_lib.set_price(ent, 5000, 750)
end

parachute_back = c_ent_lib.new_custom_backpack(parachute_back_set, parachute_back_update, false, c_ent_lib.UPDATE_TYPE.POST_STATEMACHINE)
c_ent_lib.add_custom_entity_info(parachute_back, "ParachutePack", parachute_texture_id, 0, 5000, 750)
local parachute_back_p = c_ent_lib.new_custom_purchasable_back(parachute_back_p_set, function() end, parachute_back, false)
c_ent_lib.init()

c_ent_lib.add_custom_shop_chance(parachute_back_p, c_ent_lib.CHANCE.LOW, {c_ent_lib.SHOP_TYPE.GENERAL_STORE, c_ent_lib.SHOP_TYPE.SPECIALTY_SHOP, c_ent_lib.SHOP_TYPE.HIRED_HAND_SHOP, c_ent_lib.SHOP_TYPE.PET_SHOP, c_ent_lib.SHOP_TYPE.TURKEY_SHOP}, true)
c_ent_lib.add_custom_container_chance(parachute_back, c_ent_lib.CHANCE.LOW, {ENT_TYPE.ITEM_CRATE, ENT_TYPE.ITEM_PRESENT})

c_ent_lib.add_custom_entity_crust_chance(parachute_back, 0.05)
c_ent_lib.define_custom_entity_tilecode(parachute_back, "parachute_pack", true)


register_option_button('parachutepack_spawn', 'spawn ParachutePack', '', function()
    local x, y, l = get_position(players[1].uid)
    c_ent_lib.spawn_custom_entity(parachute_back, x, y, l, 0, 0)
end)