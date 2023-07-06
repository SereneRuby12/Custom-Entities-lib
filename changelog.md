# Version Changelog

## `1.1`
- Added functions `add_custom_item_to_arena`, `enable_arena_customization_settings` and `draw_custom_arena_item_settings` to add custom items to arena easily, with settings through ImGUI
- Updated `new_custom_gun` to use `pre_trigger_action`, making other entities able to use the weapon
- Fixed bug on waddler levels
- Fixed some issues with powerups on death with ankh
- Fixed an issue with the pickup example
- Fixed issue when using instant restart while holding a custom item
- Lil bomber now only spawns big bombs when having powerpack as backitem
- Note: This update should be fully compatible with previous versions

## `1.0b`
- Changed `ON.LOADING` callback to `ON.PRE_LOAD_SCREEN`, custom entities shouldn't be lost on transition due to frame drops
- Warping to another level (no transition) now preserves the custom entities
- Custom powerups won't render in HUD if it's invisible

## `1.0a`
- Added `unset_custom_entity` function
- Optimized some functions by replacing `get_entities_by_type` with `get_entities_by`
- Changed `#table > 0` with `table[1] ~= nil`, should be faster
- Fixed bug on held entities update
- Removed some comments
- Updated docs and examples

## `1.0`
- Fixed custom entities that were updated on post or pre statemachine not being removes from custom_type entities table, and adding a after_destroy_callback will actually call it on_kill and pass entity as second param (entities that update on frame will still be the same)
- Other small change
- Updated examples

## `1.0-rc2`
- Added various functions:
- `add_custom_entity_crust_chance` for making custom entities to have a change to spawn in crust, uses ALIVE_EMBED_ON_ICE, so it needs the `texture_id` and `animation_frame` to be defined using new function `add_custom_entity_info`
- `add_custom_entity_info` add some info of the entity to the custom entity type (name, texture, animation frame, and optional price), and you can use `set_entity_info_from_custom_id` on the set function
- `set_entity_info_from_custom_id` applies the entity info that is added on `set_entity_info_from_custom_id`
- `define_custom_entity_tilecode` to add a custom tilecode for the custom entity.
- Modified params of the set function, added custom_type_id as third param, and moved args to fourth param
- Fixed containers only spawing a custom item only one time ever (until restarting the mod)
- Curio (Tun) and caveman shop now are checked by shop type instead of by room template
- Removed messpect that will probably never be used

## `1.0-rc1`
- This version might have some issues due to having exports, if you want to use exports and have the lib as a mod, use something like `local celib = import("Estebanfer/custom-entities-library")`, or if you want to have the lib in your mod folder, remove the line of exports as said below to prevent possible issues
- Returning a table should no longer be required on the custom entity set function
- Fixed some bugs: args not being passed on some extra custom entities, and custom backitems showing errors when entering a portal
- Added UPDATE_TYPE, as last parameter of new_custom_entity, you can just ignore it to use the normal update on frame, or use POST_STATEMACHINE or PRE_STATEMACHINE, and the update function will be called on the one you chose
- Added exports, if you want to use the lib as something included on your mod, you should remove the line that's almost at the end `exports = module`
- Some optimizations to extra custom entities functions

## `0.9.1a`
- Fixed warnings from new spel2.lua
- Fixed standing_uid to standing_on_uid (correct variable name)

## `0.9.1`
- Moved init to custom_init, now init doesn't take parameters and just calls custom_init with default values (`true, false`), shouldn't break anything on previous scripts, but those might unnecesary parameters.

## `0.9 - 2`
- Added `only_one` parameter to `add_shop_chance`, use to only allow one of that item per shop

## `0.9 - 1`
- Fixed and changed transition info of hired hands (previously didn't work with many hired hands)

## There are versions previous to those, but most don't change anything important 