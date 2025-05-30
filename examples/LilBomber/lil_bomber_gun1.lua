meta = {
    name = "Lil bomber",
    version = "WIP",
    author = "SereneRuby12",
    description = ""
}

local c_ent_lib = import("SereneRuby12/custom-entities-library")
--local c_ent_lib = require "custom_entities"

local bomb_spawn_sound = get_sound(VANILLA_SOUND.ENEMIES_OLMEC_BOMB_SPAWN)
local lil_bomber_texture_id
do
    local lil_bomber_texture_def = TextureDefinition.new()
    lil_bomber_texture_def.width = 128
    lil_bomber_texture_def.height = 128
    lil_bomber_texture_def.tile_width = 128
    lil_bomber_texture_def.tile_height = 128
    
    lil_bomber_texture_def.texture_path = "Lil_bomber.png"
    lil_bomber_texture_id = define_texture(lil_bomber_texture_def)
end
local function mycustom_set(ent)
    ent:set_texture(lil_bomber_texture_id)
    c_ent_lib.set_price(ent, 12000, 1500)
    add_custom_name(ent.uid, "Lil' Bomber")
end

local function mycustom_update(ent, data)
    ent.color.r = 1
    ent.color.g = 1 - ent.cooldown/124
    ent.color.b = 1 - ent.cooldown/124
end

local function mycustom_shoot(ent, data)
  local x, y, l = get_position(ent.uid)
  local dir = test_flag(ent.flags, ENT_FLAG.FACING_LEFT) and -1 or 1
  local bomb = get_entity(spawn(ENT_TYPE.ITEM_BOMB, x+0.4*dir, y, l, 0.25*dir, 0.075))
  bomb_spawn_sound:play()
  messpect(bomb.uid)
  bomb.last_owner_uid = ent.overlay.uid
end

local c_gun = c_ent_lib.new_custom_gun(mycustom_set, mycustom_update, mycustom_shoot, 60, 0.2, 0.05, ENT_TYPE.ITEM_FREEZERAY)
c_ent_lib.init()
c_ent_lib.add_custom_shop_chance(c_gun, c_ent_lib.CHANCE.LOW, {c_ent_lib.SHOP_TYPE.WEAPON_SHOP, c_ent_lib.SHOP_TYPE.SPECIALTY_SHOP, c_ent_lib.SHOP_TYPE.TUN, c_ent_lib.SHOP_TYPE.CAVEMAN}, true)
c_ent_lib.add_custom_container_chance(c_gun, c_ent_lib.CHANCE.LOW, ENT_TYPE.ITEM_CRATE)
messpect(c_gun)

set_callback(function()
    local x, y, l = get_position(players[1].uid)
    local uid = spawn(ENT_TYPE.ITEM_FREEZERAY, x, y, l, 0, 0)
    messpect(uid)
    c_ent_lib.set_custom_entity(uid, c_gun)
end, ON.LEVEL)
