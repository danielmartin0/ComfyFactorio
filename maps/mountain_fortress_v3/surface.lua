local Global = require 'utils.global'
local Public = require 'maps.mountain_fortress_v3.table'
local surface_name = Public.scenario_name
local zone_settings = Public.zone_settings

local this = {
    active_surface_index = nil,
    surface_name = surface_name
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local function exclude_surface(surface)
    for _, force in pairs(game.forces) do
        force.set_surface_hidden(surface, true)
    end
end

function Public.create_surface()
    local map_gen_settings = {
        ['seed'] = math.random(10000, 99999),
        ['width'] = zone_settings.zone_width,
        ['water'] = 0.001,
        ['starting_area'] = 1,
        ['cliff_settings'] = { cliff_elevation_interval = 0, cliff_elevation_0 = 0 },
        ['default_enable_all_autoplace_controls'] = false,
        ['autoplace_settings'] = {
            ['entity'] = { treat_missing_as_default = false },
            ['tile'] = {
                settings = {
                    ['deepwater'] = { frequency = 1, size = 0, richness = 1 },
                    ['deepwater-green'] = { frequency = 1, size = 0, richness = 1 },
                    ['water'] = { frequency = 1, size = 0, richness = 1 },
                    ['water-green'] = { frequency = 1, size = 0, richness = 1 },
                    ['water-mud'] = { frequency = 1, size = 0, richness = 1 },
                    ['water-shallow'] = { frequency = 1, size = 0, richness = 1 }
                },
                treat_missing_as_default = true
            },
            ['decorative'] = { treat_missing_as_default = false }
        },
        property_expression_names = {
            cliffiness = 0,
            ['tile:water:probability'] = -10000,
            ['tile:deep-water:probability'] = -10000
        }
    }

    local mine = {}
    mine['control-setting:moisture:bias'] = 0.33
    mine['control-setting:moisture:frequency:multiplier'] = 1

    map_gen_settings.property_expression_names = mine
    map_gen_settings.default_enable_all_autoplace_controls = false


    if not this.active_surface_index then
        this.active_surface_index = game.surfaces.nauvis.index
        -- this.active_surface_index = game.planets['fulgora'].create_surface(surface_name, map_gen_settings).index
    else
        this.active_surface_index = Public.soft_reset_map(game.surfaces[this.active_surface_index], map_gen_settings).index
    end

    game.surfaces.nauvis.map_gen_settings = map_gen_settings


    -- this.soft_reset_counter = Public.get_reset_counter()

    return this.active_surface_index
end

function Public.create_landing_surface()
    local map_gen_settings = {
        autoplace_controls = {
            ['coal'] = { frequency = 25, size = 3, richness = 3 },
            ['stone'] = { frequency = 25, size = 3, richness = 3 },
            ['copper-ore'] = { frequency = 25, size = 3, richness = 3 },
            ['iron-ore'] = { frequency = 35, size = 3, richness = 3 },
            ['uranium-ore'] = { frequency = 25, size = 3, richness = 3 },
            ['crude-oil'] = { frequency = 80, size = 3, richness = 1 },
            ['trees'] = { frequency = 0.75, size = 3, richness = 0.1 },
            ['enemy-base'] = { frequency = 15, size = 0, richness = 1 }
        },
        cliff_settings = { cliff_elevation_0 = 1024, cliff_elevation_interval = 10, name = 'cliff' },
        height = 64,
        width = 256,
        peaceful_mode = false,
        seed = 42,
        starting_area = 'very-low',
        starting_points = { { x = 0, y = 0 } },
        terrain_segmentation = 'normal',
        water = 'normal'
    }

    local surface
    if not this.landing_surface_index then
        surface = game.create_surface('Init', map_gen_settings)
    end

    if not surface or not surface.valid then return end

    surface.always_day = true
    surface.request_to_generate_chunks({ 0, 0 }, 1)
    surface.force_generate_chunk_requests()

    exclude_surface(surface)

    local walls = {}
    local tiles = {}

    local area = { left_top = { x = -128, y = -32 }, right_bottom = { x = 128, y = 32 } }
    for x = area.left_top.x, area.right_bottom.x, 1 do
        for y = area.left_top.y, area.right_bottom.y, 1 do
            tiles[#tiles + 1] = { name = 'black-refined-concrete', position = { x = x, y = y } }
            if x == area.left_top.x or x == area.right_bottom.x or y == area.left_top.y or y == area.right_bottom.y then
                walls[#walls + 1] = { name = 'stone-wall', force = 'neutral', position = { x = x, y = y } }
            end
        end
    end
    surface.set_tiles(tiles)
    for _, entity in pairs(walls) do
        local e = surface.create_entity(entity)
        e.destructible = false
        e.minable = false
    end

    rendering.draw_text {
        text = '♦ Landing zone ♦',
        surface = surface,
        target = { 0, -50 },
        color = { r = 0.98, g = 0.66, b = 0.22 },
        scale = 10,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }

    return this.landing_surface_index
end

--- Returns the surface index.
function Public.get_active_surface()
    return this.active_surface
end

--- Returns the surface name.
function Public.get_surface_name()
    return this.surface_name
end

--- Returns the amount of times the server has soft restarted.
function Public.get_reset_counter()
    return this.soft_reset_counter
end

return Public
