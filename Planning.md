# Idea:

Make custom entities easy to implement: items, weapons, pickups, monster etc.

# Functions:

<!--- ### void set_on_gameframe(bool gameframe)
Set custom ents to be called on ON.GAMEFRAME --->

### void init(bool gameframe) 

inits lib callbacks, if the bool is true then the update callbacks will be called on ON.GAMEFRAME instead of ON.FRAME

### void stop()

stops lib callbacks

### int id new_custom_entity(function(entity, transition_data) set_func, function(entity, custom_ent_info) updatefunc, bool is_item, boole is_mount, optional\<int\> ent_type) 

Set a new custom entity behiavour to be asigned in set_custom_entity()
The function should take care of items being taken to next levels, waddler, etc.
**The set function must return a table** for storing info about the entity, that will be passed to the updatefunc.
Also, the spawn function recives the table of the info when passed through a level
is_item and is_mount are for taking care about items going through level transition.

### void set_custom_entity(uid, custom_ent_id)

make a entity to be a custom one

### void spawn_custom_entity(custom_ent_id)

spawn a custom entity
(requires ent_type on custom_ent to be used)

### void set_custom_entity_replace_chance(custom_ent_id, ent_type, chance, spawn_type?)

set the chances to make a specific entity a custom one

### void set_custom_entity_crate_chance(custon_ent_id, chance)

set the chance of being in a crate

### void set_custom_entity_procedural(custom_ent_id, ...)

I'm not very convinced of using this one
add procedural chances for a custom entity to spawn
(requires ent_type on custom_ent to be used)

### void set_custom_entity_shop_chance(custom_ent_id, chance, shop_type)

add chance to be in a shop
(requires ent_type on custom_ent to be used)

### void set_custom_entity_wall_chance(custom_ent_id)

add chance to be incrusted in a block
(requires ent_type on custom_ent to be used)



## Extras

### int id set_custom_gun(function(info) set_func, function() updatefunc, function(weapon_uid, facing_left) firefunc, int cooldown, float recoil_x, float recoil_y, optional\<int\> ent_type) )

The script sets the gun cooldown to 2 to prevent the gun from shooting, then handles the cooldown with a variable.

### int id set_custom_pickup(function() set_func, function() update_holder, optional\<int\> ent_type)

Used for custom pickups, idk if I should add also an update function for updating the item itself.

Notes:

example code for replacing shop items from rando2:

```lua
set_pre_entity_spawn(function(type, x, y, l, overlay)
    local rx, ry = get_room_index(x, y)
    local roomtype = get_room_template(rx, ry, l)
    if has(shop_rooms, roomtype) and options.shop then
        local eid = pick(shop_mounts)
        local etype = get_type(eid)
        if etype.description > 1900 then
            etype.description = prng:random(1804, 1858)
        end
        return spawn_entity_nonreplaceable(eid, x, y, l, 0, 0)
    end
    return spawn_entity_nonreplaceable(type, x, y, l, 0, 0)
end, SPAWN_TYPE.LEVEL_GEN, MASK.MOUNT, shop_mounts)
```

https://github.com/spelunky-fyi/overlunky/blob/main/examples/customized_crate_drops.lua

