local c_ent_lib = require "custom_entities"

local bomb_spawn_sound = get_sound(VANILLA_SOUND.ENEMIES_OLMEC_BOMB_SPAWN)
local lil_bomber_texture
do
    local texture_def = get_texture_definition(TEXTURE.DATA_TEXTURES_ITEMS_0)
    texture_def.texture_path = 'Lil_bomber.png'
    lil_bomber_texture = define_texture(texture_def)
end

local function mycustom_set(ent, data)
    ent:set_texture(lil_bomber_texture)
    add_custom_name(ent.uid, "Lil' Bomber")
    return {}
end

local function mycustom_update(ent, data)
    ent.color.r = 1
    ent.color.g = 1 - ent.cooldown/124
    ent.color.b = 1 - ent.cooldown/124
end

local function mycustom_shoot(weapon, data)
    local x, y, l = get_position(weapon.uid)
    messpect(weapon.uid, x, y, l)
    local dir = test_flag(weapon.flags, ENT_FLAG.FACING_LEFT) and -1 or 1
    local bomb = get_entity(spawn(ENT_TYPE.ITEM_BOMB, x+0.2*dir, y, l, 0.25*dir, 0.075))
    bomb_spawn_sound:play()
    messpect(bomb.uid)
    bomb.last_owner_uid = weapon:topmost_mount().uid
end

local c_gun = c_ent_lib.new_custom_gun2(mycustom_set, mycustom_update, mycustom_shoot, 60, 0, 0, ENT_TYPE.ITEM_FREEZERAY, false)--0.2, 0.05, ENT_TYPE.ITEM_FREEZERAY)

local function mycustom_set2(ent, data)
    add_custom_name(ent.uid, "Bomba")
    return {}
end

local function mycustom_update2(ent, data)
    ent.color.r = 1
    ent.color.g = 1 - ent.cooldown/124
    ent.color.b = 1 - ent.cooldown/124
end

local function mycustom_shoot2(weapon, data)
    local x, y, l = get_position(weapon.uid)
    messpect(weapon.uid, x, y, l)
    local dir = test_flag(weapon.flags, ENT_FLAG.FACING_LEFT) and -1 or 1
    local bomb = get_entity(spawn(ENT_TYPE.ITEM_BOMB, x+0.2*dir, y, l, 0.25*dir, 0.075))
    bomb_spawn_sound:play()
    messpect(bomb.uid)
    bomb.last_owner_uid = weapon:topmost_mount().uid
end

local c_gun = c_ent_lib.new_custom_gun2(mycustom_set, mycustom_update, mycustom_shoot, 60, 0, 0, ENT_TYPE.ITEM_FREEZERAY, true)--0.2, 0.05, ENT_TYPE.ITEM_FREEZERAY)
local c_gun2 = c_ent_lib.new_custom_gun2(mycustom_set2, mycustom_update2, mycustom_shoot2, 60, 0, 0, ENT_TYPE.ITEM_FREEZERAY, true)--0.2, 0.05, ENT_TYPE.ITEM_FREEZERAY)


c_ent_lib.init()
c_ent_lib.add_custom_shop_chance(c_gun, c_ent_lib.CHANCE.COMMON, c_ent_lib.SHOP_TYPE.WEAPON_SHOP)
c_ent_lib.add_custom_shop_chance(c_gun2, c_ent_lib.CHANCE.COMMON, c_ent_lib.SHOP_TYPE.WEAPON_SHOP)
messpect(c_gun)

set_callback(function()
    local x, y, l = get_position(players[1].uid)
    local uid = spawn(ENT_TYPE.ITEM_FREEZERAY, x, y, l, 0, 0)
    messpect(uid)
    c_ent_lib.set_custom_entity(uid, c_gun)
    local uid = spawn(ENT_TYPE.ITEM_FREEZERAY, x, y, l, 0, 0)
    messpect(uid)
    c_ent_lib.set_custom_entity(uid, c_gun2)
    spawn(ENT_TYPE.ITEM_FREEZERAY, x, y, l, 0, 0)
end, ON.LEVEL)