local c_ent_lib = require "custom_entities"

local just_burnt, last_burn = 0, 0

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
    set_on_kill(ent.uid, function(ent)
        move_entity(ent.uid, 0, -123, 0, 0)
    end)
    ent.hitboxx = 0.300
    ent.hitboxy = 0.420
    ent.offsety = -0.01
    ent.width = 1.25
    ent.height = 1.25
    ent.flags = set_flag(ent.flags, ENT_FLAG.TAKE_NO_DAMAGE)
    return {}
end
set_pre_entity_spawn(function(entity_type, x, y, layer, overlay_entity, spawn_flags)
    if y == -123 then
        return spawn_entity_nonreplaceable(ENT_TYPE.ITEM_ROCK, x, y, layer, 0, 0)
    end
end, SPAWN_TYPE.SYSTEMIC, MASK.EXPLOSION, ENT_TYPE.FX_EXPLOSION)

set_vanilla_sound_callback(VANILLA_SOUND.ITEMS_BACKPACK_WARN, VANILLA_SOUND_CALLBACK_TYPE.STARTED, function(sound)
    if just_burnt > 0 and last_burn == get_frame()-1 then
        sound:stop()
        sound:set_volume(0)
        just_burnt = just_burnt - 1
    end
end)

local function parachute_back_update(ent, c_data)
    ent.color.r = 0.75
    ent.color.g = 0.75
    ent.color.b = 0.75
    if ent.overlay and ent.overlay.type.search_flags == MASK.PLAYER and ent.overlay.falling_timer > 34 and not ent.overlay:has_powerup(ENT_TYPE.ITEM_POWERUP_PARACHUTE) then
        ent.overlay:give_powerup(ENT_TYPE.ITEM_POWERUP_PARACHUTE)
    end
    if ent.explosion_trigger then
        ent.explosion_trigger = false
        ent.explosion_timer = 0
        just_burnt = just_burnt + 1
        last_burn = get_frame()
    end
    if ent.overlay and ent.overlay.type.search_flags == MASK.PLAYER and
    ent.overlay.state ~= CHAR_STATE.ENTERING and ent.overlay.state ~= CHAR_STATE.EXITING and ent.overlay.state ~= CHAR_STATE.CLIMBING and ent.overlay.state ~= 24 then
        if not test_flag(ent.flags, ENT_FLAG.PAUSE_AI_AND_PHYSICS) then
            ent.flags = set_flag(ent.flags, ENT_FLAG.PAUSE_AI_AND_PHYSICS)
            ent:set_draw_depth(26)
        else
            if test_flag(ent.overlay.flags, ENT_FLAG.FACING_LEFT) then
                ent.flags = set_flag(ent.flags, ENT_FLAG.FACING_LEFT)
                ent.x = 0.25
            else
                ent.flags = clr_flag(ent.flags, ENT_FLAG.FACING_LEFT)
                ent.x = -0.25
            end
        end
    else
        if test_flag(ent.flags, ENT_FLAG.PAUSE_AI_AND_PHYSICS) then
            ent.flags = clr_flag(ent.flags, ENT_FLAG.PAUSE_AI_AND_PHYSICS)
        end
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

local parachute_back = c_ent_lib.new_custom_entity(parachute_back_set, parachute_back_update, c_ent_lib.CARRY_TYPE.HELD, ENT_TYPE.ITEM_HOVERPACK)
local parachute_back_p = c_ent_lib.new_custom_purchasable_back(parachute_back_p_set, function() end, 43, parachute_back, false)
c_ent_lib.init(true)

c_ent_lib.add_custom_shop_chance(parachute_back_p, c_ent_lib.CHANCE.COMMON, c_ent_lib.ALL_SHOPS)
c_ent_lib.add_custom_container_chance(parachute_back, c_ent_lib.CHANCE.LOW, {ENT_TYPE.ITEM_CRATE, ENT_TYPE.ITEM_PRESENT})

set_callback(function()
    local x, y, l = get_position(players[1].uid)
    local uid = spawn(ENT_TYPE.ITEM_CAPE, x, y, l, 0, 0)
    c_ent_lib.set_custom_entity(spawn(ENT_TYPE.ITEM_HOVERPACK, x, y, l, 0, 0), parachute_back)
end, ON.START)