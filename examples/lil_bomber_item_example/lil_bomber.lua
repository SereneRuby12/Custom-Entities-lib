meta = {
    name = "Lil Bomber",
    version = "1.0",
    author = "Estebanfer",
    description = "Adds Lil bomber from EtG"
}

local c_ent_lib = import("estebanfer/custom-entities-library")
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

local function mycustom_set(ent, _, gun_id)
    c_ent_lib.set_entity_info_from_custom_id(ent, gun_id)
end

local function mycustom_update(ent)
    ent.color.r = 1
    ent.color.g = 1 - ent.cooldown/124
    ent.color.b = 1 - ent.cooldown/124
end

local function mycustom_shoot(weapon)
    local x, y, l = get_position(weapon.uid)
    local dir = test_flag(weapon.flags, ENT_FLAG.FACING_LEFT) and -1 or 1
    ---@type Bomb
    local bomb = get_entity(spawn(ENT_TYPE.ITEM_BOMB, x+0.2*dir, y, l, 0.25*dir, 0.075))
    bomb_spawn_sound:play()
    local backitem_uid = weapon.overlay:worn_backitem()
    if backitem_uid ~= -1 then
        bomb.width = 1.875
        bomb.height = 1.875
        bomb.scale_hor = 1.875
        bomb.scale_ver = 1.875
        bomb.is_big_bomb = true
    end
    bomb.last_owner_uid = weapon.overlay.uid
end

local c_gun = c_ent_lib.new_custom_gun(mycustom_set, mycustom_update, mycustom_shoot, 60, 0.2, 0.05, ENT_TYPE.ITEM_FREEZERAY)
c_ent_lib.add_custom_entity_info(c_gun, "Lil Bomber", lil_bomber_texture_id, 0, 15000, 1500)

c_ent_lib.add_custom_shop_chance(c_gun, c_ent_lib.CHANCE.LOW, {c_ent_lib.SHOP_TYPE.TUN, c_ent_lib.SHOP_TYPE.CAVEMAN}, true)
c_ent_lib.add_custom_shop_chance(c_gun, c_ent_lib.CHANCE.LOWER, {c_ent_lib.SHOP_TYPE.WEAPON_SHOP, c_ent_lib.SHOP_TYPE.SPECIALTY_SHOP, c_ent_lib.SHOP_TYPE.DICESHOP, c_ent_lib.SHOP_TYPE.TUSKDICESHOP}, true)
c_ent_lib.add_custom_container_chance(c_gun, c_ent_lib.CHANCE.LOW, {ENT_TYPE.ITEM_GHIST_PRESENT, ENT_TYPE.ITEM_PRESENT})
c_ent_lib.add_custom_container_chance(c_gun, c_ent_lib.CHANCE.LOWER, ENT_TYPE.ITEM_CRATE)

c_ent_lib.add_custom_entity_crust_chance(c_gun, 0.05)
c_ent_lib.define_custom_entity_tilecode(c_gun, "lil_bomber", true)

c_ent_lib.init()

register_option_button('lil_bomber_spawn', 'spawn lil bomber', '', function()
    local x, y, l = get_position(players[1].uid)
    c_ent_lib.set_custom_entity(spawn(ENT_TYPE.ITEM_FREEZERAY, x, y, l, 0, 0), c_gun)
end)