using Agents
using Random
using Distributions

@agent Area OSMAgent begin
    emergency::Bool
    probability::Float64
end

@agent Ambulance OSMAgent begin
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
        scheduler = Schedulers.randomly,
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
        speed = rand(model.rng) + 6.0
        ambulances = Ambulance(id+n_areas, start, speed)
        add_agent!(ambulances, model)
    end
    return model
end

function control_emergency!(area::Area, ambulance::Ambulance, model)
    nothing
    #If emergency is true and there is a ambulance near, then set to false
end

function alarm_emergency(pos, model)
    near_ids = nearby_ids(pos, model, 2.00)
    j = findfirst(id -> model[id] isa Area && model[id].emergency == true , near_ids)
    isnothing(j) ? nothing : model[near_ids[j]]::Area
end

#alarm_emergency(agent::)
function agent_step!(ambulance::Ambulance, model)
    position = alarm_emergency(ambulance.pos, model)
    OSM.plan_route!(ambulance, position,  model, return_trip=true)
    return
end

function agent_step!(area::Area, model)
    #If every area nothing happen then launch a random bernoully distribution otherwise keep 
    #the emergency activated
    #ambulance = ambulance_agent(agent::Ambulance, model)
    if area.emergency == false
        area.emergency = rand(Bernoulli(area.probability))
    end
    # if there is a emergency, move one ambulance to the destiny and comeback to the place
    alarm_emergency(area, model)
    #if agent.emergency
        #plan_route!(ambulance , area.pos, model, return_trip = true)
        # Agents will be controlled because of an emergency 
    #    map(i -> model[i].emergency = false, nearby_ids(agent, model, 0.01))
        #map(i -> model[i].in_operation = true,)
    #end
    return
end

using InteractiveDynamics
using CairoMakie
CairoMakie.activate!() # hide
ac(agent::Area) = agent.emergency ? :red : :black 
ac(agent::Ambulance) = :green  
as(agent) =  10
model = initialise()

abmvideo("emergency_system.mp4", model, agent_step!; 
title = "Emergency in a city", framerate = 15, frames = 300, as, ac)
