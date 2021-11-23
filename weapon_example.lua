local c_ent_lib = require "custom_entities"

local bomb_spawn_sound = get_sound(VANILLA_SOUND.ENEMIES_OLMEC_BOMB_SPAWN)

local function mycustom_set(ent, data)
    return {}
end

local function mycustom_update(ent, data)
    ent.color.r = ent.cooldown/124 + 0.5
    ent.color.g = 0.5
    ent.color.b = 0.5
end

local function mycustom_shoot(ent, data)
  local x, y, l = get_position(ent.uid)
  local dir = test_flag(ent.flags, ENT_FLAG.FACING_LEFT) and -1 or 1
  local bomb = get_entity(spawn(ENT_TYPE.ITEM_BOMB, x+0.5*dir, y, l, 0.25*dir, 0.075))
  bomb_spawn_sound:play()
  messpect(bomb.uid)
  bomb.last_owner_uid = ent:topmost_mount().uid
end

local c_gun = c_ent_lib.new_custom_gun(mycustom_set, mycustom_update, mycustom_shoot, 60, 0.2, 0.05)
c_ent_lib.init()
messpect(c_gun)

set_callback(function()
    local x, y, l = get_position(players[1].uid)
    local uid = spawn(ENT_TYPE.ITEM_SHOTGUN, x, y, l, 0, 0)
    messpect(uid)
    c_ent_lib.set_custom_entity(uid, c_gun)
end, ON.LEVEL)