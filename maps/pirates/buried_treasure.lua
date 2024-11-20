-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Common = require('maps.pirates.common')
-- local Memory = require('maps.pirates.memory')
local Math = require('maps.pirates.math')
local _inspect = require('utils.inspect')
local Token = require('utils.token')

local Public = {}

function Public.pick_up_treasure_tick()
	if Common.activecrewcount() == 0 then
		return
	end

	local destination = Common.current_destination()
	if not destination then
		return
	end
	local dynamic_data = destination.dynamic_data
	local surface_name = destination.surface_name
	if not (surface_name and dynamic_data) then
		return
	end
	local surface = game.surfaces[surface_name]
	if not (surface and surface.valid) then
		return
	end

	local maps = dynamic_data.treasure_maps or {}
	local buried_treasure = dynamic_data.buried_treasure or {}

	for i = 1, #maps do
		local map = maps[i]

		if map.state == 'on_ground' then
			local p = map.position

			local nearby_characters = surface.find_entities_filtered({ position = p, radius = 3, name = 'character' })
			local nearby_characters_count = #nearby_characters
			if nearby_characters_count > 0 then
				local player
				local j = 1
				while j <= nearby_characters_count do
					if
						nearby_characters[j]
						and nearby_characters[j].valid
						and nearby_characters[j].player
						and Common.validate_player(nearby_characters[j].player)
					then
						player = nearby_characters[j].player
						break
					end
					j = j + 1
				end
				if player then
					local buried_treasure_candidates = {}
					for _, t in pairs(buried_treasure) do
						if not t.associated_to_map then
							buried_treasure_candidates[#buried_treasure_candidates + 1] = t
						end
					end
					if #buried_treasure_candidates == 0 then
						break
					end
					local chosen = buried_treasure_candidates[Math.random(#buried_treasure_candidates)]

					chosen.associated_to_map = true
					local p2 = chosen.position
					map.buried_treasure_position = p2

					map.state = 'picked_up'
					map.mapobject_rendering.destroy()

					Common.notify_force_light(player.force, { 'pirates.find_map', player.name })
				end
			end
		end
	end
end

function Public.buried_treasure_tick()
	if Common.activecrewcount() == 0 then
		return
	end

	-- local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	local remaining = destination.dynamic_data.treasure_remaining

	if
		not (
			remaining
			and remaining > 0
			and destination.surface_name
			and destination.dynamic_data.buried_treasure
			and #destination.dynamic_data.buried_treasure > 0
		)
	then
		return
	end

	local surface = game.surfaces[destination.surface_name]
	local treasure_table = destination.dynamic_data.buried_treasure

	for i = 1, #treasure_table do
		local treasure = treasure_table[i]
		if not treasure then
			break
		end

		local t = treasure.treasure

		if t then
			local p = treasure.position
			local free = surface.can_place_entity({ name = 'wooden-chest', position = p })

			if free then
				local inserters = {
					surface.find_entities_filtered({
						type = 'inserter',
						position = { x = p.x - 1, y = p.y },
						radius = 0.1,
						direction = defines.direction.east,
					}),
					surface.find_entities_filtered({
						type = 'inserter',
						position = { x = p.x + 1, y = p.y },
						radius = 0.1,
						direction = defines.direction.west,
					}),
					surface.find_entities_filtered({
						type = 'inserter',
						position = { x = p.x, y = p.y - 1 },
						radius = 0.1,
						direction = defines.direction.south,
					}),
					surface.find_entities_filtered({
						type = 'inserter',
						position = { x = p.x, y = p.y + 1 },
						radius = 0.1,
						direction = defines.direction.north,
					}),
				}

				for j = 1, 4 do
					if inserters[j] and inserters[j][1] then
						local ins = inserters[j][1]

						if
							destination.dynamic_data.treasure_remaining > 0
							and ins.held_stack.count == 0
							and ins.status == defines.entity_status.waiting_for_source_items
						then
							surface.create_entity({
								name = 'item-on-ground',
								position = p,
								stack = { name = t.name, count = 1 },
							})
							t.count = t.count - 1
							destination.dynamic_data.treasure_remaining = destination.dynamic_data.treasure_remaining
								- 1

							if destination.dynamic_data.treasure_remaining == 0 then
								-- destroy all
								local buried_treasure = destination.dynamic_data.buried_treasure
								for k, _ in pairs(buried_treasure) do
									buried_treasure[k] = nil
								end

								local maps = destination.dynamic_data.treasure_maps
								for k, m in pairs(maps) do
									if m.state == 'on_ground' then
										m.mapobject_rendering.destroy()
									end
									maps[k] = nil
								end
							elseif t.count <= 0 then
								treasure.treasure = nil

								local maps = destination.dynamic_data.treasure_maps
								for _, m in pairs(maps) do
									if
										m.state == 'picked_up'
										and m.buried_treasure_position
										and m.buried_treasure_position == p
									then
										m.state = 'inactive'
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function Public.revealed_buried_treasure_distance_check()
	local destination = Common.current_destination()
	if Common.activecrewcount() == 0 then
		return
	end

	if destination.dynamic_data.some_player_was_close_to_buried_treasure then
		return
	end

	local maps = destination.dynamic_data.treasure_maps or {}
	for _, map in pairs(maps) do
		if map.state == 'picked_up' then
			for _, player in pairs(Common.crew_get_crew_members()) do
				if player.character and player.character.valid then
					if Math.distance(player.character.position, map.buried_treasure_position) <= 20 then
						destination.dynamic_data.some_player_was_close_to_buried_treasure = true
					end
				end
			end
		end
	end
end

function Public.get_picked_up_treasure_maps()
	local destination = Common.current_destination()
	if not destination then
		return {}
	end

	local maps = destination.dynamic_data.treasure_maps
	if not maps then
		return {}
	end

	local ret = {}

	for _, m in pairs(maps) do
		if m.state == 'picked_up' then
			ret[#ret + 1] = m
		end
	end

	return ret
end

function Public.spawn_treasure_map_at_position(position)
	local destination = Common.current_destination()
	if not destination then
		return
	end

	local surface = game.surfaces[destination.surface_name]
	if not surface then
		return
	end

	local map = {}
	map.position = position
	map.mapobject_rendering = rendering.draw_sprite({
		surface = surface,
		target = position,
		sprite = 'utility/gps_map_icon',
		render_layer = 'corpse',
		x_scale = 2.4,
		y_scale = 2.4,
	})
	map.state = 'on_ground'
	map.id = tostring(Token.uid())

	destination.dynamic_data.treasure_maps[#destination.dynamic_data.treasure_maps + 1] = map
end

return Public
