local Ai = require("maps.biter_battles_v2.ai")
local BenchmarkingBlueprints = require("benchmarking.blueprints")
local Event = require("utils.event")
local Feeding = require "maps.biter_battles_v2.feeding"
local InstantMapReset = require("commands.instant_map_reset")
local Profiler = require("utils.profiler")


---@param bp_string string
---@param surface LuaSurface
---@param offset MapPosition
---@param force string
local function build_blueprint_from_string(bp_string, surface, offset, force)
	local bp_entity = surface.create_entity { name = "item-on-ground", position = offset, stack = "blueprint" }
	if bp_entity then
		bp_entity.stack.import_stack(bp_string)
		local bp_entities = bp_entity.stack.get_blueprint_entities()
		bp_entity.destroy()
		for _, entity in pairs(util.table.deepcopy(bp_entities)) do
			local offset_pos = { entity.position.x + offset.x, entity.position.y + offset.y }
			local clashing_entities = surface.find_entities_filtered({
				position = offset_pos,
				radius = 3,
			})
			for _, clashing_entity in pairs(clashing_entities) do
				if clashing_entity.name ~= "rocket-silo" then
					clashing_entity.destroy()
				end
			end
		end
		for _, entity in pairs(util.table.deepcopy(bp_entities)) do
			local offset_pos = { entity.position.x + offset.x, entity.position.y + offset.y }
			entity.position = offset_pos
			entity.force = force
			surface.create_entity(entity)
		end
	end
end

Event.add(
	defines.events.on_tick,
	---@param event EventData.on_tick
	function (event)
		---Preparation step 1
		---Initial setup tick, set the map so the bp fits perfectly, and then place it
		if event.tick == 100 then
			---@type CustomCommandData
			local cmd_input = {
				name = "instant_map_reset",
				tick = 100,
				parameter = "123465",
			}
			global.bb_settings["bb_map_reveal_toggle"] = false
			InstantMapReset.instant_map_reset(cmd_input, game.players[1])
			game.speed = 10
			game.forces["north"].research_all_technologies()
			local surface = game.get_surface(global.bb_surface_name)
			if surface then
				local offset = { x = 0, y = 0 }
				local force = "north"
				build_blueprint_from_string(BenchmarkingBlueprints.north_defense_001, surface, offset, force)
				local width = 300 -- for one side
				local height = 600 -- for one side
				for x = 16, width, 32 do
					for y = 16, height, 32 do
						game.forces["spectator"].chart(surface, { { -x, -y }, { -x, -y } })
						game.forces["spectator"].chart(surface, { { x, -y }, { x, -y } })
						game.forces["spectator"].chart(surface, { { -x, y }, { -x, y } })
						game.forces["spectator"].chart(surface, { { x, y }, { x, y } })
					end
				end
			end

			---Preparation step 2
			---Give a short amount of ticks for the map to be charted
			---Then send the science to let all hell loose.
			---We send science in 2 batches to make sure it's not just all
			---boss biters.
		elseif event.tick == 4500 then
			global.training_mode = true
			global.benchmark_mode = true
			Feeding.do_raw_feed(200, "automation-science-pack", "north_biters")
			Feeding.do_raw_feed(2000, "space-science-pack", "north_biters")
			global.max_group_size["north_biters"] = 200
			global.bb_threat["north_biters"] = 10000000
			local surface = game.get_surface(global.bb_surface_name)
			if surface then
				for _ = 1, 5, 1 do
					Ai.pre_main_attack()
					Ai.perform_main_attack()
					Ai.perform_main_attack()
					Ai.perform_main_attack()
					Ai.perform_main_attack()
					Ai.perform_main_attack()
				end
			end

			Feeding.do_raw_feed(5000, "space-science-pack", "north_biters")
			global.max_group_size["north_biters"] = 200
			global.bb_threat["north_biters"] = 10000000
			if surface then
				for _ = 1, 5, 1 do
					Ai.pre_main_attack()
					Ai.perform_main_attack()
					Ai.perform_main_attack()
					Ai.perform_main_attack()
					Ai.perform_main_attack()
					Ai.perform_main_attack()
				end
			end

			---Preparation step 3
			---Give the biters some time to arrive
			---Determined manually by watching them.
			---Save the server so that we can load it into the factorio commandline
			---bencharking mode.  After this tick, the server will shutdown by the
			---run_benchmark.sh script.
		elseif event.tick == 12000 then
			game.speed = 1
			game.server_save("abcdefg")

			---Benchmarking step
			---At this point we have a save 'abcdefg' which is loaded at or
			---near tick 12000, we give 100 ticks of fudge-space.
			---The profiler code stops itself at 60*60 ticks after the provided
			---tick.  You need to be careful to manage this with the run_benchmark.sh
			---script which sets --benchmark-ticks.
			---Since the benchmark mode at least starts at 12000, we anticipate
			---the server to stop around tick 15100. (benchmark-ticks=3100)
			---In this case, we expected the start tick to be near 12000, but unsure
			---what tick exactly, so we wait 100 ticks to be sure.
			---Then we set the profiler to stop 60 ticks before that. (end tick
			--- minus 60 times 61 instead of 60)
		elseif event.tick == 12100 then
			local end_tick = 12100 + 3000
			local profiler_tick = end_tick - (60 * 61)
			Profiler.Start(true, true, profiler_tick)
		end
	end
)
