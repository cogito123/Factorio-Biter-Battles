local Public = {}
local math_random = math.random
local math_floor = math.floor

Public.TYPE_BITER = 1
Public.TYPE_SPITTER = 2
Public.TYPE_MIXED = 3
Public.TYPE_WORM = 4

local SIZE_SMALL = 1
local SIZE_MEDIUM = 2
local SIZE_BIG = 3
local SIZE_BEHEMOTH = 4

local ENEMY = {
    [Public.TYPE_BITER] = {
        [SIZE_SMALL] = 'small-biter',
        [SIZE_MEDIUM] = 'medium-biter',
        [SIZE_BIG] = 'big-biter',
        [SIZE_BEHEMOTH] = 'behemoth-biter',
    },
    [Public.TYPE_SPITTER] = {
        [SIZE_SMALL] = 'small-spitter',
        [SIZE_MEDIUM] = 'medium-spitter',
        [SIZE_BIG] = 'big-spitter',
        [SIZE_BEHEMOTH] = 'behemoth-spitter',
    },
    [Public.TYPE_WORM] = {
        [SIZE_SMALL] = 'small-worm-turret',
        [SIZE_MEDIUM] = 'medium-worm-turret',
        [SIZE_BIG] = 'big-worm-turret',
        [SIZE_BEHEMOTH] = 'behemoth-worm-turret',
    },
}

local function get_enemy_name(size, type)
    return ENEMY[type][size]
end

local function get_raffle_table(level)
    local raffle = {
        [SIZE_SMALL] = 1000 - level * 1.75,
        [SIZE_MEDIUM] = -250 + level * 1.5,
        [SIZE_BIG] = 0,
        [SIZE_BEHEMOTH] = 0,
    }

    if level > 500 then
        raffle[SIZE_MEDIUM] = 500 - (level - 500)
        raffle[SIZE_BIG] = (level - 500) * 2
    end
    if level > 900 then
        raffle[SIZE_BEHEMOTH] = (level - 900) * 8
    end

    for k, _ in pairs(raffle) do
        if raffle[k] < 0 then
            raffle[k] = 0
        end
    end
    return raffle
end

local function roll(evolution_factor, type)
    local raffle = get_raffle_table(math_floor(evolution_factor * 1000))
    local max_chance = 0
    for _, v in pairs(raffle) do
        max_chance = max_chance + v
    end
    local r = math_random(0, math_floor(max_chance))
    local current_chance = 0
    for k, v in pairs(raffle) do
        current_chance = current_chance + v
        if r <= current_chance then
            return get_enemy_name[type][k]
        end
    end
end

local function get_biter_name(evolution_factor)
    return roll(evolution_factor, Public.TYPE_BITER)
end

local function get_spitter_name(evolution_factor)
    return roll(evolution_factor, Public.TYPE_SPITTER)
end

local function get_worm_raffle_table(level)
    local raffle = {
        [SIZE_SMALL] = 1000 - level * 1.75,
        [SIZE_MEDIUM] = level,
        [SIZE_BIG] = 0,
        [SIZE_BEHEMOTH] = 0,
    }

    if level > 500 then
        raffle[SIZE_MEDIUM] = 500 - (level - 500)
        raffle[SIZE_BIG] = (level - 500) * 2
    end
    if level > 900 then
        raffle[SIZE_BEHEMOTH] = (level - 900) * 3
    end
    for k, _ in pairs(raffle) do
        if raffle[k] < 0 then
            raffle[k] = 0
        end
    end
    return raffle
end

local function get_worm_name(evolution_factor)
    local raffle = get_worm_raffle_table(math_floor(evolution_factor * 1000))
    local max_chance = 0
    for _, v in pairs(raffle) do
        max_chance = max_chance + v
    end
    local r = math_random(0, math_floor(max_chance))
    local current_chance = 0
    for k, v in pairs(raffle) do
        current_chance = current_chance + v
        if r <= current_chance then
            return get_enemy_name[Public.TYPE_WORM][k]
        end
    end
end

local function get_unit_name(evolution_factor)
    if math_random(1, 3) == 1 then
        return get_spitter_name(evolution_factor)
    else
        return get_biter_name(evolution_factor)
    end
end

local type_functions = {
    [Public.TYPE_BITER] = get_biter_name,
    [Public.TYPE_MIXED] = get_unit_name,
    [Public.TYPE_SPITTER] = get_spitter_name,
    [Public.TYPE_WORM] = get_worm_name,
}

function Public.roll(entity_type, evolution_factor)
    if not entity_type then
        return
    end
    if not type_functions[entity_type] then
        return
    end
    local evo = evolution_factor
    if not evo then
        evo = game.forces.enemy.get_evolution_factor(storage.bb_surface_name)
    end
    return type_functions[entity_type](evo)
end

return Public
