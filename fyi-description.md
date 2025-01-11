## :toolbox: Install
**NOTE: This mod doesn't do anything by itself, it's required for mods that use it via `import`**
Also, only works on **Playlunky nightly** for now (until new stable release)
(if the mod doesn't indicate that you need it, you probably don't need to install this)

Simply install as any other mod and make sure to place other mods that use the library below it on the **Load Order** (or just place the library on top)

## :information_source: Details

A library to easily make new entities, focused on items (and mounts), but works with any entity.

## :computer: Short example (for basic custom entities)
First, import the lib and make a function that will be called when the custom entity is spawned or set
```lua
local celib = import("SereneRuby12/custom-entities-library")
--local celib = require "custom_entities" --You can use this one if you want to include the library in your mod rather than
--people having to download it, but might cause some issues with pickups,
--and would not be the most optimized way if the player uses more custom entities

local function custom_ent_set(entity)
    -- ... your code
    local my_entity_data = {
        --store anything that you want in a table, optional
    }
    return my_entity_data --make sure to return the table if you use it
end
```

Second, make a function that will be called on every frame for the custom entity
```lua
local function custom_ent_update(entity, custom_data) --custom_data is the table that you created on the set function
    -- ... your code
end
```

Third, make a new custom entity type
```lua
    local custom_caveman_id = celib.new_custom_entity(custom_ent_set, custom_ent_update, nil, ENT_TYPE.MONS_CAVEMAN) -- the function can take more parameters, check documentation
```

And then spawn it, or add chances to be in shops, container, etc.
```lua
    celib.set_custom_entity(spawn_on_floor(ENT_TYPE.MONS_CAVEMAN, x, y, l), custom_caveman_id )
    celib.spawn_custom_entity(custom_caveman_id , x, y, l, 0, 0)

    celib.add_custom_container_chance(custom_caveman_id , celib.CHANCE.LOW, ENT_TYPE.ITEM_CRATE)
```

There are two ways of spawning a custom entity, that are basically the same: using the spawn function from the lib, or spawning the entity and making it to be a custom entity.

**note:** the example was simplified, check the original one on the github [Readme](https://github.com/SereneRuby12/Custom-Entities-lib/blob/master/readme.md)

## :link: Useful links
- [Documentation](https://github.com/SereneRuby12/Custom-Entities-lib/blob/master/documentation.md)
- [Changelog](https://github.com/SereneRuby12/Custom-Entities-lib/blob/master/changelog.md)
### :abc: Examples
- [Some random custom entities](https://github.com/SereneRuby12/Custom-Entities-lib/blob/master/examples/example.lua)
- [Custom gun](https://github.com/SereneRuby12/Custom-Entities-lib/blob/master/examples/Grapple_gun/grapple_gun.lua)
- [Custom gun2](https://github.com/SereneRuby12/Custom-Entities-lib/blob/master/examples/lil_bomber_item_example/lil_bomber.lua)
- [Custom backpack](https://github.com/SereneRuby12/Custom-Entities-lib/blob/master/examples/ParachutePack.lua)
- [Custom pickup](https://github.com/SereneRuby12/Custom-Entities-lib/blob/master/examples/pickup.lua)
- [Another custom pickup](https://github.com/SereneRuby12/Custom-Entities-lib/blob/master/examples/playerghost_pickup.lua)
