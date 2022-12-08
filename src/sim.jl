using Agents
using Random
using Distributions

@agent Area OSMAgent begin
    emergency::Bool
    probability::Float64
    #is_ambulance::Bool
    #speed::Float64
end

mutable struct Area <: AbstractAgent
    id::Int
    pos::Tuple{Int, Int, Float64}
    emergency::Bool
    probability::Float64
    #is_ambulance::Bool
    #speed::Float64
end

@agent Ambulance OSMAgent begin
    speed::Float64
end

mutable struct Ambulance <: AbstractAgent
    id::Int
    pos::Tuple{Int, Int, Float64}
    speed::Float64
end

function initialise(seed = 1234, n_areas = 100, n_ambulances =2)
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
        emergency = Area(id, start, false, probability,)
        add_agent!(emergency, model)
    end
    #Allocate ambulance at random
    for id in 1:n_ambulances 
        start = random_position(model)
        speed = rand(model.rng) + 60.0
        ambulances = Ambulance(id+n_areas, start, speed)
        add_agent!(ambulances, model)
    end
    return model
end

function dispatch_ambulance(agent::Ambulance, position, model)
    plan_route(agent, position, model, return_trip = true)
end

function agent_step!(agent::Area, model)
    #If every area nothing happen then launch a random bernoully distribution otherwise keep 
    #the emergency activated
    if agent.emergency == false
        agent.emergency = rand(Bernoulli(agent.probability))
    end
    # if there is a emergency, move one ambulance to the destiny and comeback to the place
    if agent.emergency
        plan_route!(agent , agent.pos, model, return_trip = true )
        # Agents will be controlled because of an emergency 
        map(i -> model[i].emergency = false, nearby_ids(agent, model, 0.01))
        #map(i -> model[i].in_operation = true,)
    end
    return
end

using InteractiveDynamics
using CairoMakie
CairoMakie.activate!() # hide
ac(agent::Area) = agent.emergency ? :red : :black 
ac(agent::Ambulance) = :green  
#as(agent::Area) = agent.emergency ? 10 : 8

#ac(agent) = agent.type == :Area and ? :yellow : :black 
#ac(Ambulance) = ambulances.speed > 0.0 ? :green : :black
as(agent) =  10
model = initialise()

abmvideo("emergency_system.mp4", model, agent_step!; 
title = "Emergency in a city", framerate = 5, frames = 300, as, ac)

