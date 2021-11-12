# Idea:

Make custom entities easy to implement: items, weapons, pickups, monster etc.

# Functions (most of those don't work yet):

### :white_check_mark: void init(bool gameframe) 

inits lib callbacks, if the bool is true then the update callbacks will be called on ON.GAMEFRAME instead of ON.FRAME

### :white_check_mark: void stop()

stops lib callbacks

### :white_check_mark: int id new_custom_entity(function(entity, transition_data) set_func, function(entity, custom_ent_info) updatefunc, bool is_item, bool is_mount, optional\<int\> ent_type) 

Set a new custom entity behiavour to be asigned in set_custom_entity()
The function should take care of items being taken to next levels, waddler, etc.
**The set function must return a table** for storing info about the entity, that will be passed to the updatefunc.
Also, the spawn function recives the table of the info when passed through a level
is_item and is_mount are for taking care about items going through level transition.

### :white_check_mark: void set_custom_entity(uid, custom_ent_id)

make a entity to be a custom one

### :red_circle: void spawn_custom_entity(custom_ent_id)

spawn a custom entity
(requires ent_type on custom_ent to be used)

### :red_circle: void set_custom_entity_replace_chance(custom_ent_id, ent_type, chance, spawn_type?)

I don't know if I will add this one.
set the chances to make a specific entity a custom one

### :red_circle: void set_custom_entity_crate_chance(custon_ent_id, chance)

set the chance of being in a crate

### :red_circle: void set_custom_entity_shop_chance(custom_ent_id, chance, shop_type)

add chance to be in a shop
(requires ent_type on custom_ent to be used)

### :red_circle: void set_custom_entity_wall_chance(custom_ent_id)

add chance to be incrusted in a block
(requires ent_type on custom_ent to be used)



## Extras

### :red_circle: int id set_custom_gun(function(info) set_func, function() updatefunc, function(weapon_uid, facing_left) firefunc, int cooldown, float recoil_x, float recoil_y, optional\<int\> ent_type) )

The script sets the gun cooldown to 2 to prevent the gun from shooting, then handles the cooldown with a variable.

### :red_circle: int id set_custom_pickup(function() set_func, function() update_holder, optional\<int\> ent_type)

Used for custom pickups, idk if I should add also an update function for updating the item itself.


### Notes for myself:

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

