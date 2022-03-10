# Custom entities library

A library to easily make new entities, focused on items (and mounts), but works with any entity.

## Short example (for basic custom entities)

### First, import the lib and make a function when the custom entity will be spawned
```lua
local celib = import("estebanfer/custom-entities-library")
--local celib = require "custom_entities" --You can use this one if you want to include the library in your mod rather than people having to download it, but might cause some issues with pickups, and would not be the most optimized way if the player uses more custom entities

local function custom_ent_set(entity)
    local max_health = math.random(3, 6)
    my_entity_data = {
        max_health = max_health,
        recover_health_timer = 5*60
    } --store anything that you want in a table, optional
    entity.color.g = 0.75
    entity.color.b = 0.75
    return my_entity_data --make sure to return the table if you use it
end
```

### Second, make a function that will be called on every frame
```lua
local function custom_ent_update(entity, custom_data) --custom_data is the table that you created on the set function
    if entity.health < custom_data.max_health and entity.move_state ~= 6 then
        if custom_data.recover_health_timer <= 0 then
            local pickup_fx = get_entity(spawn_entity_over(ENT_TYPE.FX_PICKUPEFFECT, entity.uid, 0, 0))
            pickup_fx:set_texture(TEXTURE.DATA_TEXTURES_FX_SMALL_0)
            pickup_fx.animation_frame = 63
            entity.health = entity.health + 1
            custom_data.recover_health_timer = 5*60
        else
            custom_data.recover_health_timer = custom_data.recover_health_timer - 1
        end
    end
end
```

### Third, make a new custom entity type
```lua
    local health_caveman_id = celib.new_custom_entity(custom_ent_set, custom_ent_update, nil, ENT_TYPE.MONS_CAVEMAN) -- the function can take more parameters, check documentation
```

### And then spawn it, or add chances to be in shops, container, etc.
```lua
    celib.set_custom_entity(spawn_on_floor(ENT_TYPE.MONS_CAVEMAN, x, y, l), health_caveman_id)
    celib.spawn_custom_entity(health_caveman_id, x, y, l, 0, 0)

    celib.add_custom_container_chance(health_caveman_id, celib.CHANCE.LOW, ENT_TYPE.ITEM_CRATE)
```

There are two ways of spawning a custom entity, that are basically the same: using the spawn function from the lib, or spawning the entity and making it to be a custom entity.

## Check the documentation page there:
[Documentation](https://github.com/estebanfer/Custom-Entities-lib/blob/master/documentation.md)

## Check the changelog there:
[Changelog](https://github.com/estebanfer/Custom-Entities-lib/blob/master/changelog.md)

## And look for the examples there:
- [Some random custom entities](examples/example.lua)
- [Custom gun](examples/Grapple_gun/grapple_gun.lua)
- [Custom gun2](examples/lil_bomber_item_example/lil_bomber.lua)
- [Custom backpack](examples/ParachutePack.lua)
- [Custom pickup](examples/pickup.lua)
- [Another custom pickup](examples/pickup2.lua)