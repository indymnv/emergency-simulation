using Agents
using Random
using Distributions

@agent Area OSMAgent begin
    emergency::Bool
    probability::Float64
end

mutable struct Area <: AbstractAgent
    id::Int
    pos::Tuple{Int, Int, Float64}
    emergency::Bool
    probability::Float64
end

function initialise(seed = 1234)
    map_path = OSM.test_map()
    properties = Dict(:dt => 1/60)
    model = ABM(
        Area,
        OpenStreetMapSpace(map_path);
        properties = properties,
        rng = Random.MersenneTwister(seed)
    )
    for id in 1:100
        start = random_position(model) # At an intersection
        probability = 0.001#rand(1:2) # Random probability
        emergency = Area(id, start, false, probability)
        add_agent_pos!(emergency, model)
        OSM.plan_random_route!(emergency, model; limit = 50) # try 50 times to find a random route
    end
    # We'll add patient zero at a specific (longitude, latitude)
    start = OSM.nearest_road((9.9351811, 51.5328328), model)
    finish = OSM.nearest_node((9.945125635913511, 51.530876112711745), model)
    probability = rand(model.rng) # Random speed from 2-7kmph
    emergency = add_agent!(start, model, true, probability)
    plan_route!(emergency, finish, model)
    # This function call creates & adds an agent, see `add_agent!`
    return model
end

function agent_step!(agent, model)
    #distance_left = move_along_route!(agent, model, agent.probability * model.dt)
    #if is_stationary(agent, model) && rand(model.rng) < 0.1
        # When stationary, give the agent a 10% chance of going somewhere else
        #OSM.plan_random_route!(agent, model; limit = 50)
        # Start on new route, moving the remaining distance
        #move_along_route!(agent, model, distance_left)
    #end
    agent.emergency = rand(Bernoulli(agent.probability))
    if agent.emergency
        # Agents will be infected if they get too close (within 10m) to a zombie.
        map(i -> model[i].emergency = true, nearby_ids(agent, model, 0.01))
    end
    return
end

using InteractiveDynamics
using CairoMakie
CairoMakie.activate!() # hide
ac(agent) = agent.emergency ? :green : :black
as(agent) = agent.emergency ? 10 : 8
model = initialise()

abmvideo("emergency_system.mp4", model, agent_step!;
title = "Emergency in a city", framerate = 15, frames = 300, as, ac)

"""
@agent Zombie OSMAgent begin
    infected::Bool
    speed::Float64
end


mutable struct Zombie <: AbstractAgent
    id::Int
    pos::Tuple{Int,Int,Float64}
    infected::Bool
    speed::Float64
end

function initialise(; seed = 1234)
    map_path = OSM.test_map()
    properties = Dict(:dt => 1 / 60)
    model = ABM(
        Zombie,
        OpenStreetMapSpace(map_path);
        properties = properties,
        rng = Random.MersenneTwister(seed)
    )

    for id in 1:100
        start = random_position(model) # At an intersection
        speed = rand(model.rng) * 5.0 + 2.0 # Random speed from 2-7kmph
        human = Zombie(id, start, false, speed)
        add_agent_pos!(human, model)
        OSM.plan_random_route!(human, model; limit = 50) # try 50 times to find a random route
    end
    # We'll add patient zero at a specific (longitude, latitude)
    start = OSM.nearest_road((9.9351811, 51.5328328), model)
    finish = OSM.nearest_node((9.945125635913511, 51.530876112711745), model)

    speed = rand(model.rng) * 5.0 + 2.0 # Random speed from 2-7kmph
    zombie = add_agent!(start, model, true, speed)
    plan_route!(zombie, finish, model)
    # This function call creates & adds an agent, see `add_agent!`
    return model
end

function agent_step!(agent, model)
    # Each agent will progress along their route
    # Keep track of distance left to move this step, in case the agent reaches its
    # destination early
    distance_left = move_along_route!(agent, model, agent.speed * model.dt)

    if is_stationary(agent, model) && rand(model.rng) < 0.1
        # When stationary, give the agent a 10% chance of going somewhere else
        OSM.plan_random_route!(agent, model; limit = 50)
        # Start on new route, moving the remaining distance
        move_along_route!(agent, model, distance_left)
    end

    if agent.infected
        # Agents will be infected if they get too close (within 10m) to a zombie.
        map(i -> model[i].infected = true, nearby_ids(agent, model, 0.01))
    end
    return
end

using InteractiveDynamics
using CairoMakie
CairoMakie.activate!() # hide
ac(agent) = agent.infected ? :green : :black
as(agent) = agent.infected ? 10 : 8
model = initialise()

abmvideo("outbreak.mp4", model, agent_step!;
title = "Zombie outbreak", framerate = 15, frames = 200, as, ac)
"""

