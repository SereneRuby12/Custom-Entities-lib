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

(requires ent_type on custom_ent to be set)

### :red_circle: void set_custom_entity_crate_chance(custon_ent_id, chance_type)

set the chance of being in a crate

(requires ent_type on custom_ent to be set)

### :white_check_mark: void add_custom_shop_chance(custom_ent_id, chance_type, shop_type/s)

Add chance to be in a shop or shops, use `SHOP_TYPE` (that uses SHOP_TYPE and ROOM_TEMPLATE from the scripting api) and `CHANCE` from the library

The `shop_type` can be a a single value or a table of the shop types

Only replaces items, not hh or mounts.

(requires ent_type on custom_ent to be set)

### :red_circle: void set_custom_entity_wall_chance(custom_ent_id)

add chance to be incrusted in a block

(requires ent_type on custom_ent to be set)

### **CHANCE**
- `COMMON` "common"
- `LOW` "low"
- `LOWER` lower"

### **SHOP_TYPE** 
- `GENERAL_STORE` 0
- `CLOTHING_SHOP` 1
- `WEAPON_SHOP` 2
- `SPECIALTY_SHOP` 3
- `HIRED_HAND_SHOP` 4
- `PET_SHOP` 5
- `DICE_SHOP` 6
- `TUSK_DICE_SHOP` 13
- `TUN` 77
- `CAVEMAN` 79

### ALL_SHOPS

A table containing all the shop types

## Extras

### :white_check_mark: int id set_custom_gun(function(info) set_func, function() updatefunc, function(weapon_uid, facing_left) firefunc, int cooldown, float recoil_x, float recoil_y, optional\<int\> ent_type) )

The script sets the gun cooldown to 60 to prevent the gun from shooting, then handles the cooldown with a variable.

### :red_circle: int id set_custom_pickup(function() set_func, function() update_holder, optional\<int\> ent_type)

Used for custom pickups, idk if I should add also an update function for updating the item itself.


### Notes for myself:

https://github.com/spelunky-fyi/overlunky/blob/main/examples/customized_crate_drops.lua

