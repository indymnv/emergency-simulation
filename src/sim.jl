using Agents
using Random
using Distributions

@agent Area OSMAgent begin
    emergency::Bool
    probability::Float64
    is_ambulance::Bool
    speed::Float64
end

mutable struct Area <: AbstractAgent
    id::Int
    pos::Tuple{Int, Int, Float64}
    emergency::Bool
    probability::Float64
    is_ambulance::Bool
    speed::Float64
end


function initialise(seed = 1234, n_areas = 100)
    #Set space
    map_path = OSM.test_map()
    properties = Dict(:dt => 1/60)
    model = ABM(
        Union{Area, Ambulance},
        OpenStreetMapSpace(map_path);
        properties = properties,
        rng = Random.MersenneTwister(seed)
    )
    #Develop initial states for each node
    for id in 1:n_areas
        start = random_position(model) # At an intersection
        probability = 0.001#rand(1:2) # Random probability
        emergency = Area(id, start, false, probability, false, 0.0)
        add_agent!(emergency, model)
        OSM.plan_random_route!(emergency, model; limit = 50) # try 50 times to find a random route
    end

    # We'll add patient zero at a specific (longitude, latitude)
    start = OSM.nearest_road((9.9351811, 51.5328328), model)
    #finish = OSM.nearest_node((9.945125635913511, 51.530876112711745), model)
    speed = rand(model.rng) * 50.0 + 20.0 # Random speed from 20-70kmph
    ambulance = add_agent!(start, model, false, probability, true, speed)

    # We'll add an ambulance at a specific (longitude, latitude)
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
        # Agents will be activated because of an emergency
        map(i -> model[i].emergency = true, nearby_ids(agent, model, 0.01))
        #map(i -> model[i].in_operation = true,)
    end
    return
end

using InteractiveDynamics
using CairoMakie
CairoMakie.activate!() # hide
#ac(agent) = Area.emergency ? :yellow : :black
ac(agent) = agent.in_operation ? :red : :black
as(agent) = agent.emergency ? 10 : 8
model = initialise()

abmvideo("emergency_system.mp4", model, agent_step!;
title = "Emergency in a city", framerate = 15, frames = 300, as, ac)

