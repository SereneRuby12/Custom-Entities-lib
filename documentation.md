# Functions (the ones in red arent made yet):

### :white_check_mark: void init()

inits the lib callbacks, defaults to use GAMEFRAME and enables custom entity cloning. Also doesn't start callbacks if the function was already called (and not stopped with stop()). This makes it better if the library comes to a library that must be installed as other mod and is used by different mods at the same time (exports).

### :white_check_mark: void custom_init(bool gameframe, bool disable_custom_entities_cloning)

inits lib callbacks, if the bool is true then the update callbacks will be called on ON.GAMEFRAME instead of ON.FRAME, note that using FRAME will stop the update of custom entities after death and won't work on camp or arena, could cause weird things like non-flammable backs to explode after death.

The disable_custom_entities_cloning disables the need of keeping track of clonegunshot, but obviously, custom entities won't be cloned correctly.

### :white_check_mark: void stop()

stops lib callbacks, currently doesn't stop all the callbacks, anyways, you probably won't use this.

### :white_check_mark: int id new_custom_entity(function(entity, transition_data, args) set_func, function(entity, custom_ent_info) updatefunc, optional\<CARRY_TYPE\> carry_type, optional\<int\> ent_type, optional\<UPDATE_TYPE\> update_type)

Set a new custom entity behiavour to be asigned in set_custom_entity()

The function should take care of items being taken to next levels, waddler, etc.

The set function can return a table that you can use for storing info about the entity, that will be passed to the updatefunc (custom_ent_info), and set_func (transition_data) if the entity can go through levels (items, mounts) or is cloned.

For carry_type, use CARRY_TYPE.HELD or .MOUNT

### :white_check_mark: void set_custom_entity(uid, custom_ent_id, args)

make a entity to be a custom one. The args are optional.

### :white_check_mark: void spawn_custom_entity(custom_ent_id, x, y, l, vel_x, vel_y, args)

spawn a custom entity. The args are optional. You could spawn a normal entity and use the set_custom_entity if you need to use any other spawn method like spawn_critical or spawn_on_floor, it would do the same thing.

(requires ent_type on custom_ent to be set)

### :white_check_mark: table get_custom_entity(uid, custom_ent_id)

returns the data of the entity, or nil if it isn't a custom entity

### :white_check_mark: void add_custom_container_chance(custon_ent_id, chance_type, container_type/s)

set the chance of being in a container (only crate, present and ghist present).

The `container_type` can be a a single value or a table of the entity types, use ENT_TYPE.

(requires ent_type on custom_ent to be set)

### :white_check_mark: void add_custom_shop_chance(custom_ent_id, chance_type, shop_type/s, optional\<only_one\>)

Add chance to be in a shop or shops, use `SHOP_TYPE` (that uses SHOP_TYPE and ROOM_TEMPLATE from the scripting api) and `CHANCE` from the library

The `shop_type` can be a a single value or a table of the shop types

Only replaces items, not hh or mounts.

`only_one` is for only allowing one item of that type to be on a shop

(requires ent_type on custom_ent to be set)

### :red_circle: void set_custom_entity_wall_chance(custom_ent_id, chance)

add chance to be incrusted in a block, change from 1 to 100 for the entity to spawn one time in the level

(requires ent_type on custom_ent to be set)

### :white_check_mark: void set_price(entity, base_price, inflation)

Sets the price of an entity for the level. Use this only in the set function for custom entities, this solves an error that shows when setting the price on the first frame.

### add_custom_entity_crust_chance(custom_id, chance)

Add chance for the custom entity type to spawn in crust (inside floor). The chance is from `0.0` to `1.0` and will only spawn it max one time per level.

### :white_check_mark: add_custom_entity_info(custom_id, name, texture_id, anim_frame, price, price_inflation)

Add info of the entity to the custom entity type. Can be used with `set_entity_info_from_custom_id` on the set function

### :white_check_mark: set_entity_info_from_custom_id(ent, custom_id)

Apply the entity info set on `add_custom_entity_info` (name, texture, animation frame, and price if has a price)

### :white_check_mark: define_custom_entity_tilecode(custom_id, tilecode_name, spawn_to_floor)

Define a tilecode for your custom entity in one line of code

### :white_check_mark: void add_after_destroy_callback(custom_ent_id, function(custom_ent_info) callback)
Set a function to be called after the entity stops existing. Only one function per custom entity.

### **CHANCE**
- `COMMON` "common" 30%
- `LOW` "low" 15%
- `LOWER` lower" 5%

### **SHOP_TYPE** 
- `GENERAL_STORE` 0
- `CLOTHING_SHOP` 1
- `WEAPON_SHOP` 2
- `SPECIALTY_SHOP` 3
- `HIRED_HAND_SHOP` 4
- `PET_SHOP` 5
- `DICESHOP` 75 (ROOM_TEMPLATE.DICESHOP)
- `TUSKDICESHOP` 83 (ROOM_TEMPLATE.TUSKDICESHOP)
- `TUN` 77 (ROOM_TEMPLATE.CURIOSHOP)
- `CAVEMAN` 79 (ROOM_TEMPLATE.CAVEMANSHOP)

### **CARRY_TYPE**
- `HELD` 1 (items and backpacks)
- `MOUNT` 2
- `POWERUP` 4
- Use nil if the entity isn't carried through levels

### **UPDATE_TYPE**
- `FRAME` 0
- `POST_STATEMACHINE` 1
- `PRE_STATEMACHINE` 2

### ALL_SHOPS

A table containing all the shop types

### ALL_CONTAINERS

A table containing crate, present, and ghist present containers

## Extras

### :white_check_mark: int id new_custom_gun(function(entity, transition_data) set_func, function(entity, custom_ent_info) updatefunc, function(entity, facing_left) firefunc, int cooldown, float recoil_x, float recoil_y, optional\<int\> ent_type) )

The script sets the gun cooldown to 2 to prevent the gun from shooting, then handles the cooldown with a variable.

The gun can't be shot by other entities than players.

### :white_check_mark: int id new_custom_gun2(function(entity, transition_data) set_func, function(entity, custom_ent_info) updatefunc, function(weapon_ent, facing_left) bulletfunc, optional\<int\> cooldown, float extra_recoil_x, float extra_recoil_y, ent_type, bool mute_sound)

The script replaces the bullets generated by the weapon, the recoil is the same of the base weapon used.

It can be used by any entity capable of using weapons (Including shopkeepers, hired hands, cavemen, etc.)

Using a shotgun will generate 6 bullets, calling the bulletfunc 6 times and aplying the recoil 6 times, so be careful if you apply an extra recoil to shotguns.

### :white_check_mark: int id new_custom_backpack(function(entity, transition_data) set_func, function(entity, custom_ent_info, holder) updatefunc, bool flammable)

Uses jetpack as base entity, sets the fuel to 0.

The holder is nil if it isn't being carried on the back of a player.

### :white_check_mark: int id new_custom_purchasable_back(function(entity) set_func, function(entity, custom_ent_info) updatefunc, int toreplace_custom_id, bool flammable)

Spawns a rock, and changes some of the properties to make it look like a backpack, spawns the toreplace entity when the item isn't a shop item anymore (bought, shopkeeper angered, etc.)

The custom item that will replace it must have a ent_type assinged (custom backpacks have ITEM_JETPACK by default).

### :white_check_mark: int id new_custom_powerup(function(entity, transition_data) set_func, function(entity, custom_ent_info) updatefunc,  int texture_id, int row, int column, optional\<Color\> color)

Create a new powerup for players, the last params (texture, row, etc.) are for the item rendering on the HUD. Make sure to use `set_powerup_drop()` after creating the pickup, it will spawn the pickup when a player dies and playing local multiplayer.

### :white_check_mark: void set_powerup_drop(int powerup_id, int pickup_id)

Sets the pickup that will be dropped when a player dies with the powerup on multiplayer.

### :white_check_mark: int id new_custom_pickup(function(entity, transition_data) set_func, function(entity, custom_ent_info, holder) updatefunc, function(entity, player, c_data, has_powerup) pickupfunc, int custom_powerup_id, entity_type)

Create a new pickup, you can use the function `do_pickup_effect()` to spawn the pickup effect easily on the pickup function.

### :white_check_mark: void do_pickup_effect(int player_uid, int texture_id, int animation_frame)

Spawn a FX_PICKUPEFFECT on player_uid, and set its texture and animation_frame. Returns the fx entity.

### :white_check_mark: int id new_custom_purchasable_pickup(function(entity, transition_data) set_func, function(entity, custom_ent_info) update_func, int custom_pickup_id)

I couldn't make the normal pickup to be purchasable without it giving the base pickup, so this spawns an entity that acts like a pickup, and manually handles buying it.

## Some examples
- [Some random custom entities](examples/example.lua)
- [Custom gun](examples/Grapple_gun/grapple_gun.lua)
- [Custom gun2](examples/lil_bomber_item_example/lil_bomber_custom_gun2.lua)
- [Custom backpack](examples/ParachutePack.lua)
- [Custom pickup](examples/pickup.lua)
- [Another custom pickup](examples/pickup2.lua)