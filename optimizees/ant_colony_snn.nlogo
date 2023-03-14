;; L2L optimization of Ant Colony NetLogo + NEST
;; Author: C Jimenez-Romero - Forschungszentrum Jülich - 2022

extensions [ py ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Demo: Artificial insect related code:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [testcreatures testcreature]
breed [visualsensors visualsensor]
breed [pheromonesensors pheromonesensor]
breed [nestsensors nestsensor]

testcreatures-own [

  creature_label
  creature_id
  reward_neuron
  pain_neuron
  move_neuron
  rotate_left_neuron
  rotate_right_neuron
  pheromone_neuron
  nest_neuron
  creature_sightline
  last_nest_collision
  last_food_collision
  carrying_food_amount
  fitness

]

pheromonesensors-own [
  sensor_id
  relative_rotation
  left_sensor_attached_to_neuron
  middle_sensor_attached_to_neuron
  right_sensor_attached_to_neuron
  attached_to_creature
]

nestsensors-own [
  sensor_id
  relative_rotation
  left_sensor_attached_to_neuron
  middle_sensor_attached_to_neuron
  right_sensor_attached_to_neuron
  attached_to_creature
]

visualsensors-own [

  sensor_id
  perceived_stimuli
  distance_to_stimuli
  relative_rotation ;;Position relative to front
  attached_to_colour
  attached_to_neuron
  attached_to_creature

]

patches-own [
  chemical             ;; amount of chemical on this patch
  food                 ;; amount of food on this patch (0, 1, or 2)
  nest?                ;; true on nest patches, false elsewhere
  nest-scent           ;; number that is higher closer to the nest
  food-source-number   ;; number (1, 2, or 3) to identify the food sources
  visual_object       ;; type (0 = empty, 1= wall, 2= obstacle, 3=food)
]

;;;
;;; Global variables including SpikingLab internals
;;;
globals [

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;World globals;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  min_x_boundary ;;Define initial x coordinate of simulation area
  min_y_boundary ;;Define initial y coordinate of simulation area
  max_x_boundary ;;Define final x coordinate of simulation area
  max_y_boundary ;;Define final y coordinate of simulation area
  nestx
  nesty
  noxious_red
  noxious_white
  noxious_green

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;GA Globals;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  fitness_value
  simulation_end_signal
  ;;;;;;;;;;;;;;;;;;;;;;;;;;Ants Globals;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  simulation_area
  raw_weight_data
  raw_plasticity_data
  raw_delay_data
  weight_data
  delay_data
  plasticity_data

  ;;;;;;;;;;;;;;;;;;;;;;Python interface globals;;;;;;;;;;;;;;;;;;;;;;;
  reset_command_string
  final_nest_command_string
  global_recorders_list
  collected-food

]

to create_nest_network
  (py:run
"import nest"
"import numpy as np"
"import pandas as pd"
"cns_size = 10"
"def connect_nodes(ant_index, input_w, input_d, heartbeat_w, heartbeat_d, nodes_w, nodes_d,"
"                  output_w, output_d):"
"    syn_spec_dict_nodes = {"
"        'weight': nodes_w,"
"        'delay': nodes_d"
"    }"
"    syn_spec_dict_heartbeat = {"
"        'weight': heartbeat_w,"
"        'delay': heartbeat_d"
"    }"
"    syn_spec_dict_input = {"
"        'weight': input_w,"
"        'delay': input_d"
"    }"
"    syn_spec_dict_output = {"
"        'weight': output_w,"
"        'delay': output_d"
"    }"
"    conn_dict = {'rule': 'all_to_all',"
"                 'allow_autapses': False}"
"    # Connect nodes"
"    # connection in the new way requires to have a matrix of target - source"
"    # Note the column is taken for the connection"
"    # nest.Connect(heartbeat, nodes, conn_dict,"
"    #               syn_spec=syn_spec_dict_heartbeat)"
"    connect_manually(heartbeat[ant_index:ant_index + 1], nodes[ant_index*cns_size:ant_index*cns_size+cns_size], heartbeat_w, heartbeat_d)"
"    # nest.Connect(inpt, nodes, conn_dict, syn_spec=syn_spec_dict_input)"
"    connect_manually(inpt[ant_index*11:ant_index*11+11], nodes[ant_index*cns_size:ant_index*cns_size+cns_size], input_w, input_d)"
"    # nest.Connect(nodes, outpt, conn_dict, syn_spec=syn_spec_dict_output)"
"    connect_manually(nodes[ant_index*cns_size:ant_index*cns_size+cns_size], outpt[ant_index*4:ant_index*4+4], output_w, output_d)"
"    i = 0"
"    for source in range(cns_size):"
"        for target in range(cns_size):"
"            if source != target:"
"                w = nodes_w[i]"
"                d = nodes_d[i]"
"                syn_spec_nodes = {'weight': w, 'delay': d}"
"                nest.Connect(nodes[ant_index*cns_size+source], nodes[ant_index*cns_size+target], 'one_to_one',"
"                             syn_spec=syn_spec_nodes)"
"                i += 1"
"def reset_generators_and_recorders():"
"    for i in range(11*15):"
"        nest.SetStatus(activator[i], [{'amplitude': 0.0}])"
"    for i in range(4*15):"
"        nest.SetStatus(spike_detector[i], [{'n_events': 0}])"
"def get_all_spike_recorders():"
"    return_list = []"
"    for i in range(4*15):"
"        return_list.append(nest.GetStatus(spike_detector[i], 'n_events'))"
"    return return_list"
"def connect_manually(sources, targets, weights, delays):"
"    i = 0"
"    for source in range(len(sources)):"
"        for target in range(len(targets)):"
"            w = weights[i]"
"            d = delays[i]"
"            syn_spec = {'weight': w, 'delay': d}"
"            nest.Connect(sources[source], targets[target], 'one_to_one',"
"                         syn_spec=syn_spec)"
"            i += 1"
"def check_connections():"
"    l = []"
"    for i in range(11):"
"        for j in range(cns_size):"
"            l.append(nest.GetStatus(nest.GetConnections(inpt[i], nodes[j]))[0]['weight'])"
"    for i in range(1):"
"        for j in range(cns_size):"
"            l.append(nest.GetStatus(nest.GetConnections(heartbeat[i], nodes[j]))[0]['weight'])"
"    for i in range(cns_size):"
"        for j in range(cns_size):"
"            if i != j:"
"                l.append(nest.GetStatus(nest.GetConnections(nodes[i], nodes[j]))[0]['weight'])"
"    for i in range(cns_size):"
"        for j in range(4):"
"            l.append(nest.GetStatus(nest.GetConnections(nodes[i], outpt[j]))[0]['weight'])"
"    return all(weights == l)"
"def connect_synapses():"
"    # Connect synapses"
"    # syn_spec = {'weight': weights, 'delay': delays}"
"    nest.CopyModel('static_synapse', 'random_synapse')  # syn_spec=syn_spec)"
"nest.ResetKernel()"
"nest.set_verbosity('M_ERROR')"
"nest.SetKernelStatus("
"    {"
"        'resolution': 1.0,"
"        'rng_seed': 1,"
"    })"
"# TODO: adapt here parameters"
"sim_time = 1000000."
"dt = 1."
"heartbeat_interval = 2."
"heartbeat = nest.Create('spike_generator', 1 * 15, params={'spike_times': np.linspace("
"    1, sim_time, int(sim_time/heartbeat_interval * dt)).round()})"
"# Activator activates the input neurons, will be manipulated by NetLogo"
"activator = nest.Create('dc_generator', 11 * 15, params={'amplitude': 400000.})"
"rng = np.random.default_rng(0)"
"# Create nodes"
"params = {'t_ref': 1.0}"
"inpt = nest.Create('iaf_psc_alpha', 11 * 15, params=params)"
"nodes = nest.Create('iaf_psc_alpha', cns_size * 15, params=params)"
"outpt = nest.Create('iaf_psc_alpha', 4 * 15, params=params)"
"spike_detector = nest.Create('spike_recorder', 4 * 15)"
"middle_spike_detector = nest.Create('spike_recorder', cns_size * 15)"
"input_detector = nest.Create('spike_recorder', 11 * 15)"
"for ant_i in range(15):"
"    # connect spike generator to input"
"    nest.Connect(activator[ant_i*11:ant_i*11+11], inpt[ant_i*11:ant_i*11+11], 'one_to_one')"
"    nest.Connect(outpt[ant_i*4:ant_i*4+4], spike_detector[ant_i*4:ant_i*4+4], 'one_to_one')"
"    nest.Connect(nodes[ant_i*cns_size:ant_i*cns_size+cns_size], middle_spike_detector[ant_i*cns_size:ant_i*cns_size+cns_size], 'one_to_one')"
"    nest.Connect(inpt[ant_i*11:ant_i*11+11], input_detector[ant_i*11:ant_i*11+11], 'one_to_one')"
"# Connect synapses"
"connect_synapses()"
"csv_file = 'individual_config.csv'"
"csv = pd.read_csv(csv_file, header=None, na_filter=False)"
"weights = csv.iloc[0].values.astype(float) * 100.0"
"delays = csv.iloc[1].values.astype(float).astype(int)"
"# 220 neurons from input to middle layer,  all to all connection 110"
"w_input2nodes = weights[:11*cns_size] # :220 .reshape(11, 20).T"
"# 20 heartbeat synapses connected to middle layer in all to all manner 10"
"w_heartbeat2nodes = weights[11*cns_size:11*cns_size+cns_size] # weights[220:240] .reshape(1, 20).T"
"w_nodes2nodes = weights[12*cns_size:(12*cns_size)+cns_size*(cns_size-1)] #weights[240:620]"
"w_nodes2output = weights[(12*cns_size)+cns_size*(cns_size-1):] # weights[620:].reshape(20, 4).T"
"d_input2nodes = delays[:11*cns_size] # .reshape(11, 20).T"
"d_heartbeat2nodes = delays[11*cns_size:11*cns_size+cns_size] # .reshape(1, 20).T"
"d_nodes2nodes =  delays[12*cns_size:(12*cns_size)+cns_size*(cns_size-1)]"
"d_nodes2output = delays[(12*cns_size)+cns_size*(cns_size-1):] # .reshape(20, 4).T"
"for i in range(15):"
"    connect_nodes(i, w_input2nodes, d_input2nodes, w_heartbeat2nodes,"
"                  d_heartbeat2nodes, w_nodes2nodes, d_nodes2nodes, w_nodes2output,"
"                  d_nodes2output)"
"print(nest.GetStatus(spike_detector[1]))"
"print(nest.GetStatus(input_detector[2]))"
)

let visual_dcgenerator_red 0
let visual_dcgenerator_green 1
let pheromone_dcgenerator_left 2
let pheromone_dcgenerator_middle 3
let pheromone_dcgenerator_right 4
let nociceptive_dcgenerator 5
let rewarding_dcgenerator 6
let nest_dcgenerator_left 7
let nest_dcgenerator_middle 8
let nest_dcgenerator_right 9
let on_nest_dcgenerator 10

let move_actuator_recorder 0
let rotate_actuator_left_recorder 1
let rotate_actuator_right_recorder 2
let pheromone_actuator_recorder 3

let input_offset 0
let actuator_offset 0
let agent_index 0
repeat 15 [
   create_nest_agent agent_index nest_dcgenerator_left nest_dcgenerator_middle nest_dcgenerator_right pheromone_dcgenerator_left pheromone_dcgenerator_middle pheromone_dcgenerator_right visual_dcgenerator_red visual_dcgenerator_green rewarding_dcgenerator nociceptive_dcgenerator move_actuator_recorder rotate_actuator_left_recorder rotate_actuator_right_recorder pheromone_actuator_recorder on_nest_dcgenerator
   set input_offset input_offset + 11
   set actuator_offset actuator_offset + 4

   set visual_dcgenerator_red visual_dcgenerator_red + 11
   set visual_dcgenerator_green visual_dcgenerator_green + 11
   set pheromone_dcgenerator_left pheromone_dcgenerator_left + 11
   set pheromone_dcgenerator_middle pheromone_dcgenerator_middle + 11
   set pheromone_dcgenerator_right pheromone_dcgenerator_right + 11
   set nociceptive_dcgenerator nociceptive_dcgenerator + 11
   set rewarding_dcgenerator rewarding_dcgenerator + 11
   set nest_dcgenerator_left nest_dcgenerator_left + 11
   set nest_dcgenerator_middle nest_dcgenerator_middle + 11
   set nest_dcgenerator_right nest_dcgenerator_right + 11
   set on_nest_dcgenerator on_nest_dcgenerator + 11

   set move_actuator_recorder move_actuator_recorder + 4
   set rotate_actuator_left_recorder rotate_actuator_left_recorder + 4
   set rotate_actuator_right_recorder rotate_actuator_right_recorder + 4
   set pheromone_actuator_recorder pheromone_actuator_recorder + 4
   set agent_index agent_index + 1
]

end


to-report get-node-attribute [ #nodeid #attribute ]
  let command_string ( word "nest.GetStatus([" #nodeid "], '" #attribute "')" )
  let nest_value py:runresult command_string ;"nest.GetStatus([5], "V_m")"
  report nest_value
end

to set-node-attribute [ #nodeid #attribute #value ]
  let command_string ( word "nest.SetStatus([" #nodeid "], {'" #attribute "':" #value "})")
  py:run command_string ;"nest.GetStatus([5], "V_m")"
end

to-report get_nest_spike_recorder [ #rec_index ]
  let command_string ( word "nest.GetStatus(spike_detector[" #rec_index "], 'n_events')"  )
  let nest_value py:runresult command_string
  report item 0 nest_value
end

to-report get_nest_spike_recorder_from_list [ #rec_number ]
  let recorder_number item #rec_number global_recorders_list
  let recorder_event item 0 recorder_number
  report recorder_event
end

to-report get_nest_all_spike_recorder
  let nest_value py:runresult "get_all_spike_recorders()"
  report nest_value
end


to reset_nest_spike_recorder [ #rec_index ]

  let command_string ( word "nest.SetStatus(spike_detector[" #rec_index "], [{'n_events': 0}])" )
  (py:run
    command_string
  )
end

to submit_nest_commands [ #nest_commands ]
  (py:run
    #nest_commands
  )
end

to prepare_reset_nest_spike_recorder [ #rec_index ]
  let command_string ( word "nest.SetStatus(spike_detector[" #rec_index "], [{'n_events': 0}]); " )
  set final_nest_command_string ( word final_nest_command_string command_string )
end


to set_nest_dc_generator [ #dc_index #dc_amplitude]

  let command_string ( word "nest.SetStatus(activator[" #dc_index "], [{'amplitude': " #dc_amplitude ".0}])" )
  (py:run
    command_string
  )
end

to prepare_set_nest_dc_generator [ #dc_index #dc_amplitude]

  set final_nest_command_string ( word final_nest_command_string "nest.SetStatus(activator[" #dc_index "], [{'amplitude': " #dc_amplitude ".0}]); " )

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Patches procedures:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-patches
  ask patches
  [ setup-nest
    setup-food
    recolor-patch ]
end

to setup-nest  ;; patch procedure
  if visual_object != 0 [ set nest? false stop ]
  ;; set nest? variable to true inside the nest, false elsewhere
  set nest? (distancexy nestx nesty) < nest_size ;82 30
  ;; spread a nest-scent over the whole world -- stronger near the nest
  set nest-scent 200 - distancexy nestx nesty
end

to update-patches
  ask patches
  [ set chemical chemical * (100 - evaporation-rate) / 100  ;; slowly evaporate chemical
    recolor-patch ]
end

;;;
;;; Set global variables with their initial values
;;;
to initialize-global-vars

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;Simulation area globals;;;;;;;;;;;;;;;;;;;;;;;;
  set min_x_boundary 60  ;;Define initial x coordinate of simulation area
  set min_y_boundary 1   ;;Define initial y coordinate of simulation area
  set max_x_boundary 100 ;;Define final x coordinate of simulation area
  set max_y_boundary 60  ;;Define final y coordinate of simulation area

  set nestx 72 + random(14)
  set nesty 18 + random(18)
  set noxious_red true
  set noxious_white true
  set noxious_green false
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Genetic Algorithm ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  set fitness_value 0
  set weight_data[]
  set delay_data[]
  set plasticity_data[]
  set simulation_end_signal false
  set reset_command_string ""
  set final_nest_command_string ""
  set global_recorders_list[]
  set collected-food 0

end


;;;
;;; Create insect agent
;;;
to-report create-creature [#xpos #ypos #creature_label #reward_neuron_label #pain_neuron_label #move_neuron_label #rotate_left_neuron_label #rotate_right_neuron_label #pheromone_neuron_label #on_nest_input_neuron ]

  let reward_neuron_id  #reward_neuron_label
  let pain_neuron_id  #pain_neuron_label
  let move_neuron_id  #move_neuron_label
  let rotate_left_neuron_id  #rotate_left_neuron_label
  let rotate_right_neuron_id  #rotate_right_neuron_label
  let pheromone_neuron_id  #pheromone_neuron_label
  let on_nest_input_neuron_id  #on_nest_input_neuron
  let returned_id nobody
  create-testcreatures 1 [
    set shape "bug"
    setxy #xpos #ypos
    set size 2
    set color yellow
    set creature_label #creature_label
    set reward_neuron reward_neuron_id
    set pain_neuron pain_neuron_id
    set move_neuron move_neuron_id
    set rotate_left_neuron rotate_left_neuron_id
    set rotate_right_neuron rotate_right_neuron_id
    set pheromone_neuron pheromone_neuron_id
    set nest_neuron on_nest_input_neuron_id
    set creature_id who
    set returned_id creature_id
    set last_nest_collision 0
    set last_food_collision 0
    set carrying_food_amount 0
    set fitness 0
  ]
  report  returned_id

end


to check-creature-on-nest-or-food
  let food_amount 0
  let on_nest? false
  ask patch-here [ set food_amount food set on_nest? nest?]
  ifelse on_nest? [
    set last_nest_collision ticks
    set carrying_food_amount 0
    prepare_set_nest_dc_generator nest_neuron input_dc_amplitude
  ]
  [
    if food_amount > 0 and carrying_food_amount < 1 [
      update-fitness 1.5
      prepare_set_nest_dc_generator reward_neuron input_dc_amplitude
      set last_food_collision ticks
      set food food - 1
      ifelse bring_food_to_nest? [
        set carrying_food_amount carrying_food_amount + 1 ;; Don't eat food and carry it to the nest
      ]
      [
        set carrying_food_amount 0 ;; Eat food immediately and don't carry it to the nest
      ]
      if food = 0 [ set visual_object 0 ]
    ]
  ]
end

;;;
;;; Check if agent returned food to nest and update its fitness
;;;
to compute-creature-fitness
  if last_nest_collision > last_food_collision and last_food_collision > 0 [
    set fitness_value fitness_value + return_food_reward
    set last_nest_collision 0
    set last_food_collision 0
    set collected-food collected-food + 1
  ]
end

to compute-swarm-fitness
  ask testcreatures [ set fitness_value fitness_value + fitness]
end

;;;
;;; Create photoreceptor and attach it to insect
;;;
to create-visual-sensor [ #psensor_id #pposition #colour_sensitive #attached_neuron_label #attached_creature] ;;Called by observer

  let attached_neuron_id #attached_neuron_label
  create-visualsensors 1 [
     set sensor_id #psensor_id
     set relative_rotation #pposition ;;Degrees relative to current heading - Left + Right 0 Center
     set attached_to_colour #colour_sensitive
     set attached_to_neuron attached_neuron_id
     set attached_to_creature #attached_creature
     ht
  ]

end

;;;
;;; Create pheromonereceptor and attach it to insect
;;;
to create-pheromone-sensor [ #psensor_id #pposition #left_sensor_attached_neuron_label #middle_sensor_attached_neuron_label #right_sensor_attached_neuron_label #attached_creature] ;;Called by observer

  let left_sensor_attached_neuron_id #left_sensor_attached_neuron_label
  let middle_sensor_attached_neuron_id #middle_sensor_attached_neuron_label
  let right_sensor_attached_neuron_id #right_sensor_attached_neuron_label
  create-pheromonesensors 1 [
     set sensor_id #psensor_id
     set relative_rotation #pposition ;;Degrees relative to current heading - Left + Right 0 Center
     set left_sensor_attached_to_neuron left_sensor_attached_neuron_id
     set middle_sensor_attached_to_neuron middle_sensor_attached_neuron_id
     set right_sensor_attached_to_neuron right_sensor_attached_neuron_id
     set attached_to_creature #attached_creature
     ht
  ]

end

;;;
;;; Ask pheromonereceptor if there is pheromone nearby
;;;
to sense-pheromone
  ;;;;;;;;;;;;;;;Take same position and heading of creature:;;;;;;;;;;;;;;;
  let creature_px 0
  let creature_py 0
  let creature_heading 0
  ask  testcreature attached_to_creature [set creature_px xcor set creature_py ycor set creature_heading heading];
  set xcor creature_px
  set ycor creature_py
  set heading creature_heading
  rt relative_rotation
  fd 1
  ;;;;;;;;;;;;;;;Sense
  let scent-ahead chemical-scent-at-angle   0
  let scent-right chemical-scent-at-angle  45
  let scent-left  chemical-scent-at-angle -45
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ifelse (scent-right > scent-ahead) and (scent-right > scent-left)
  [
    ;;activate right neuron
    prepare_set_nest_dc_generator right_sensor_attached_to_neuron input_dc_amplitude
  ]
  [
    ifelse (scent-left > scent-ahead) and (scent-left > scent-right)
    [
      ;;activate left neuron
      prepare_set_nest_dc_generator left_sensor_attached_to_neuron input_dc_amplitude
    ]
    [
      ;;activate middle neuron
      prepare_set_nest_dc_generator middle_sensor_attached_to_neuron input_dc_amplitude
    ]
  ]
end

;;;
;;; Check amount of pheromone at [angle], called by pheromonereceptor
;;;
to-report chemical-scent-at-angle [angle]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]
  report [chemical] of p
end

;;;
;;; Create pheromonereceptor and attach it to insect
;;;
to create-nest-sensor [ #psensor_id #pposition #left_sensor_attached_neuron_label #middle_sensor_attached_neuron_label #right_sensor_attached_neuron_label #attached_creature] ;;Called by observer

  let left_sensor_attached_neuron_id #left_sensor_attached_neuron_label
  let middle_sensor_attached_neuron_id #middle_sensor_attached_neuron_label
  let right_sensor_attached_neuron_id #right_sensor_attached_neuron_label
  create-nestsensors 1 [
     set sensor_id #psensor_id
     set relative_rotation #pposition ;;Degrees relative to current heading - Left + Right 0 Center
     set left_sensor_attached_to_neuron left_sensor_attached_neuron_id
     set middle_sensor_attached_to_neuron middle_sensor_attached_neuron_id
     set right_sensor_attached_to_neuron right_sensor_attached_neuron_id
     set attached_to_creature #attached_creature
     ht
  ]

end

;;;
;;; Ask smell-receptor if there is nest scent nearby
;;;
to sense-nest
  ;;;;;;;;;;;;;;;Take same position and heading of creature:;;;;;;;;;;;;;;;
  let creature_px 0
  let creature_py 0
  let creature_heading 0
  ask  testcreature attached_to_creature [set creature_px xcor set creature_py ycor set creature_heading heading];
  set xcor creature_px
  set ycor creature_py
  set heading creature_heading
  rt relative_rotation
  fd 1
  ;;;;;;;;;;;;;;;Sense
  let scent-ahead nest-scent-at-angle   0
  let scent-right nest-scent-at-angle  45
  let scent-left  nest-scent-at-angle -45
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ifelse (scent-right > scent-ahead) and (scent-right > scent-left)
  [
    ;;activate right neuron
    prepare_set_nest_dc_generator right_sensor_attached_to_neuron input_dc_amplitude
  ]
  [
    ifelse (scent-left > scent-ahead) and (scent-left > scent-right)
    [
      ;;activate left neuron
      prepare_set_nest_dc_generator left_sensor_attached_to_neuron input_dc_amplitude
    ]
    [
      ;;activate middle neuron
      prepare_set_nest_dc_generator middle_sensor_attached_to_neuron input_dc_amplitude
    ]
  ]
end

;;;
;;; Check amount of pheromone at [angle], called by pheromonereceptor
;;;
to-report nest-scent-at-angle [angle]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]
  report [nest-scent] of p
end

;;;
;;; Ask photoreceptor if there is a patch ahead (within insect_view_distance) with a perceivable colour (= attached_to_colour)
;;;
to view-world-ahead ;;Called by visualsensors

  let itemcount 0
  let foundobj 0
  ;;;;;;;;;;;;;;;Take same position and heading of creature:;;;;;;;;;;;;;;;
  let creature_px 0
  let creature_py 0
  let creature_heading 0
  ask  testcreature attached_to_creature [set creature_px xcor set creature_py ycor set creature_heading heading];
  set xcor creature_px
  set ycor creature_py
  set heading creature_heading
  rt relative_rotation
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  let view_distance insect_view_distance
  let xview 0
  let yview 0
  while [itemcount <= view_distance and foundobj = 0]
  [
    set itemcount itemcount + 0.5 ;0.34;1
    ask patch-ahead itemcount [
       set foundobj visual_object
       set xview pxcor
       set yview pycor
    ]

  ]

  ifelse (foundobj = attached_to_colour) ;;Found perceivable colour?
  [
    set distance_to_stimuli 1 ;Do not take into account the distance. itemcount
    set perceived_stimuli foundobj
  ]
  [
    set distance_to_stimuli 0
    set perceived_stimuli 0
  ]

end


;;;
;;; Process Nociceptive, reward and visual sensation
;;;
to perceive-world ;;Called by testcreatures

 let nextobject 0
 let distobject 0
 let onobject 0
 ;; Get color of current position
 ask patch-here [ set onobject visual_object ] ;;visual_object 1:  type (1= wall, 2= obstacle, 3=food)
 ifelse (onobject = 1)
 [
    ifelse (noxious_white) ;;is White attached to a noxious stimulus
    [
      prepare_set_nest_dc_generator pain_neuron input_dc_amplitude
      update-fitness -5.5
    ]
    [
        update-fitness sense_food_fitness_reward
        prepare_set_nest_dc_generator reward_neuron input_dc_amplitude
    ]
 ]
 [
    ifelse (onobject = 2)
    [
      ifelse (noxious_red) ;;is Red attached to a noxious stimulus
      [
        update-fitness -5.5
        prepare_set_nest_dc_generator pain_neuron input_dc_amplitude
      ]
      [
          update-fitness sense_food_fitness_reward
          prepare_set_nest_dc_generator reward_neuron input_dc_amplitude
      ]
    ]
    [
      if (onobject = 3)
      [
         ifelse (noxious_green) ;;is Green attached to a noxious stimulus
         [
           update-fitness -5.5
           prepare_set_nest_dc_generator pain_neuron input_dc_amplitude
         ]
         [
             update-fitness sense_food_fitness_reward
             ;prepare_set_nest_dc_generator reward_neuron input_dc_amplitude
         ]
      ]
    ]
 ]

end

;;;
;;; Move or rotate according to the active motoneuron
;;;
to do-actuators ;;Called by Creature

 let dorotation_left? false
 let dorotation_right? false
 let domovement? false
 let dopheromone? false
 let left_rotation_counter get_nest_spike_recorder_from_list ( rotate_left_neuron ); creature_label * rotate_left_neuron; get_nest_spike_recorder
 let right_rotation_counter get_nest_spike_recorder_from_list ( rotate_right_neuron ); get_nest_spike_recorder
 let move_counter get_nest_spike_recorder_from_list ( move_neuron ); get_nest_spike_recorder
 let pheromone_counter get_nest_spike_recorder_from_list ( pheromone_neuron ); get_nest_spike_recorder

 ifelse left_rotation_counter > right_rotation_counter [
    set dorotation_left? true
 ]
 [
   if right_rotation_counter > left_rotation_counter [
      set dorotation_right? true
   ]
 ]

 if move_counter >= 1 [
    set domovement? true
 ]
 if pheromone_counter >= 1 [
    set dopheromone? true
 ]
 if (dorotation_left?)
 [
   update-fitness  -1 * rotation_cost
   rotate-creature -6
 ]

 if (dorotation_right?)
 [
    update-fitness  -1 * rotation_cost
    rotate-creature 6
 ]

 if (domovement?)
 [
   update-fitness -1 * movement_cost
   move-creature 1.0 ;0.6
 ]

 if (dopheromone?)
 [
   update-fitness -1 * pheromone_cost ;-0.001 ;
   set chemical chemical + 60
 ]

end

;;;
;;; Photoreceptor excitates the connected input neuron
;;;
to propagate-visual-stimuli ;;Called by visual sensor
  if (attached_to_colour = perceived_stimuli) ;;Only produce an action potential if the corresponding associated stimulus was sensed
  [
     prepare_set_nest_dc_generator attached_to_neuron input_dc_amplitude
  ]

end

;;;
;;; Move insect (#move_units) patches forward
;;;
to move-creature [#move_units]
  fd #move_units
end

;;;
;;; Rotate insect (#rotate_units) degrees
;;;
to rotate-creature [#rotate_units]
  rt #rotate_units
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;End of insect related code;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report parse_csv_line [ #csv-line ]
  let parameter_end true
  let parameters_line #csv-line
  let current_parameter ""
  let parameters_list[]
  while [ parameter_end != false ]
  [
    set parameter_end position "," parameters_line
    if ( parameter_end != false ) [
      set current_parameter substring parameters_line 0 parameter_end
      set parameters_line substring parameters_line ( parameter_end + 1 ) ( (length parameters_line));
      ;;add current_parameter to destination list
      ;parameters_list
      set parameters_list lput (read-from-string current_parameter) parameters_list
    ]
  ]
  if ( length parameters_line ) > 0 [ ;;Get last parameter
    ;;add current_parameter to destination list
    set parameters_list lput (read-from-string parameters_line) parameters_list
  ]

 report parameters_list
end


to create_nest_agent [ #agent_id #nest_input_neuron_left #nest_input_neuron_middle #nest_input_neuron_right #pheromone_input_neuron_left #pheromone_input_neuron_middle #pheromone_input_neuron_right #visual_input_neuron_red #visual_input_neuron_green #rewarding_input_neuron  #nociceptive_input_neuron #move_actuator_neuron #rotate_actuator_left_neuron #rotate_actuator_right_neuron #pheromone_neuron #on_nest_input_neuron]
  let creatureid create-creature nestx nesty #agent_id #rewarding_input_neuron  #nociceptive_input_neuron #move_actuator_neuron  #rotate_actuator_left_neuron #rotate_actuator_right_neuron #pheromone_neuron #on_nest_input_neuron ;;[#xpos #ypos #creature_id #reward_input_neuron #pain_input_neuron #move_neuron #rotate_neuron_left #rotate_neuron_right #pheromone_neuron]
  ;;;;;;;;;;Create Visual sensors and attach neurons to them;;;;;;;;;
  create-visual-sensor  2 0  1  #visual_input_neuron_red creatureid;[ psensor_id pposition colour_sensitive attached_neuron attached_creature]
  create-visual-sensor  3 0  3  #visual_input_neuron_green creatureid;[ psensor_id pposition colour_sensitive attached_neuron attached_creature]
  let sensors_id 0
  create-pheromone-sensor sensors_id 0 #pheromone_input_neuron_left #pheromone_input_neuron_middle #pheromone_input_neuron_right creatureid ;;Called by observer
  create-nest-sensor sensors_id 0 #nest_input_neuron_left #nest_input_neuron_middle #nest_input_neuron_right creatureid

end

to update-fitness [ #fitness_change ]
  set fitness_value fitness_value + #fitness_change
end

;;;
;;; Create neural circuit, insect and world
;;;
to setup

  clear-all

  RESET-TICKS

  let config_file "individual_config.csv"
  read_l2l_config config_file
  let time_seed  (read-from-string( substring date-and-time 3 5 ) + 1) * 100
  print time_seed
  random-seed time_seed
  if used_random_seed != 0 [ random-seed used_random_seed ]
  initialize-global-vars
  py:setup py:python3
  print "Creating network..."
  create_nest_network
  ;;;;;;;;;;Draw world with green and red patches;;;;;;;;
  draw-world
  stop

end

to read_l2l_config [ #filename ]

  file-close-all
  carefully [
    file-open #filename
    set raw_weight_data file-read-line
    set raw_delay_data file-read-line
  ]
  [
    print error-message
  ]
end

to write_l2l_results [ #filename ]
  file-close-all
  file-open #filename
  file-print raw_weight_data
  ;file-print plasticity_data
  file-print raw_delay_data
  file-print fitness_value
  file-flush
  file-close-all

end

;;;
;;; Generate insect world with 3 types of patches
;;;
to draw-world
   ask patches [set visual_object 0 set nest? false set food 0]
   ;;;;;;;;;;Create a grid of white patches representing walls in the virtual worls
   ask patches with [ pxcor >= min_x_boundary and pycor = min_y_boundary and pxcor <= max_x_boundary ] [ set pcolor red  ]
   ask patches with [ pxcor >= min_x_boundary and pycor = max_y_boundary ] [ set pcolor red ]
   ask patches with [ pycor >= min_y_boundary and pxcor = min_x_boundary and pxcor <= max_x_boundary] [ set pcolor red ]
   ask patches with [ pycor >= min_y_boundary and pxcor = max_x_boundary ] [ set pcolor red ]
   let ccolumns 0

  set simulation_area patches with [ pxcor >= min_x_boundary and pxcor <= max_x_boundary and pycor >= min_y_boundary and pycor <= max_y_boundary ]
  ask n-of 2 simulation_area with [ ( distancexy 82 30) > 10 and ( distancexy 82 30) < 18 ][ set pcolor green set food 1 ]
  ask simulation_area [set visual_object 0 set nest? false]
  ask simulation_area with [ pcolor = red ][set visual_object 1]       ;; type (1= wall, 3= food)
  ask simulation_area with [ pcolor = green ][set visual_object 3]
  ask simulation_area [ setup-food setup-nest ]

end

to setup-food  ;; patch procedure
  if visual_object = 1 [ stop ]
  ;; setup food source one on the right
  if (distancexy (0.65 * max-pxcor) 53 ) < food_source_size
  [ set food-source-number 1 set visual_object 3 ]
  ;; setup food source two on the lower-left
  if (distancexy (0.65 * max-pxcor) 6 ) < food_source_size
  [ set food-source-number 2 set visual_object 3 ]
  ;; setup food source three on the upper-left
  if (distancexy (0.96 * max-pxcor) 30 ) < food_source_size
  [ set food-source-number 3 set visual_object 3 ]
  ;; set "food" at sources to either 1 or 2, randomly
  if food-source-number > 0
  [ set food food_source_amount ] ;one-of [2 4] ]

end

to recolor-patch  ;; patch procedure
  if visual_object = 1 [ stop ]
  ;; give color to nest and food sources
  ifelse nest?
  [ set pcolor violet ]
  [ ifelse food > 0
    [
      set pcolor green
    ] ;blue
    ;; scale color to show chemical concentration
    [ set pcolor scale-color blue chemical 0.1 5 ]
  ]
end


;;;
;;; Don't allow the insect to go beyond the world boundaries
;;;
to check-boundaries
  ask testcreatures [
     ifelse (xcor < (min_x_boundary + 2)) [
        set xcor ( min_x_boundary + 2)
     ]
     [
        if (xcor > ( max_x_boundary - 2)) [ set xcor ( max_x_boundary - 2) ]
     ]
     ifelse (ycor < (min_y_boundary + 2)) [
        set ycor ( min_y_boundary + 2)
     ]
     [
        if (ycor >  (max_y_boundary - 2)) [ set ycor ( max_y_boundary - 2)]
     ]

  ]
end


to send_python_reset_generators_and_recorders
  let command_string "reset_generators_and_recorders()"
  (py:run
    command_string
  )
end

to request_reset_generators_and_recorders
  set final_nest_command_string ""
  let agent_index 0
  repeat 15 [
    let generator_index 0
    repeat 11 [
       prepare_set_nest_dc_generator agent_index * 11 + generator_index 0.0
       set generator_index generator_index + 1
    ]
    let recorder_index 0
    repeat 4 [
       prepare_reset_nest_spike_recorder agent_index * 4 + recorder_index
       set recorder_index recorder_index + 1
    ]
    set agent_index agent_index + 1
  ]

  submit_nest_commands final_nest_command_string
end

;;;
;;; Run simulation
;;;
to go

 set final_nest_command_string ""
 ask visualsensors [ view-world-ahead propagate-visual-stimuli ] ;;Feed visual sensors at first
 ask nestsensors [ sense-nest ]
 ask testcreatures [ perceive-world check-creature-on-nest-or-food ]; sense touch information
 submit_nest_commands final_nest_command_string
 (py:run
 "nest.Simulate(20)"
 )
 set global_recorders_list ( get_nest_all_spike_recorder )
 set final_nest_command_string ""
 ask testcreatures [ do-actuators compute-creature-fitness]
 send_python_reset_generators_and_recorders

 if ticks mod 7 = 0 [
    if (count simulation_area with [pcolor = green]) < 1 [
       if (count testcreatures with [carrying_food_amount > 0] < 1) [
        update-fitness (2000 - ticks) * 30
         write_l2l_results "individual_result.csv"
         set simulation_end_signal true
         stop
      ]
    ]
   diffuse chemical (diffusion-rate / 100)
   ask simulation_area
   [
     set chemical chemical * (100 - evaporation-rate) / 100  ;; slowly evaporate chemical
     recolor-patch
   ]
 ]

 check-boundaries
 update-fitness -1 * resting_cost
 if ticks = 2000 [
    write_l2l_results "individual_result.csv"
    set simulation_end_signal true
    stop
  ]
 tick

end
@#$#@#$#@
GRAPHICS-WINDOW
154
23
970
520
-1
-1
8.0
1
10
1
1
1
0
0
0
1
0
100
0
60
0
0
1
ticks
30.0

BUTTON
9
27
84
61
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
102
130
136
go one-step
go
NIL
1
T
OBSERVER
NIL
G
NIL
NIL
1

BUTTON
10
65
130
99
go-forever
go
T
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
10
139
130
175
relocate insect
;ask patches with [ pxcor = 102 and pycor = 30 ] [set pcolor green]\nask testcreatures [setxy 82 30]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
3
183
151
216
insect_view_distance
insect_view_distance
1
32
5.0
1
1
NIL
HORIZONTAL

MONITOR
1002
93
1129
138
NIL
fitness_value
2
1
11

SLIDER
4
224
151
257
evaporation-rate
evaporation-rate
0
20
1.0
1
1
NIL
HORIZONTAL

SLIDER
4
258
151
291
diffusion-rate
diffusion-rate
0.0
99.0
20.0
1.0
1
NIL
HORIZONTAL

SLIDER
985
157
1250
190
sense_food_fitness_reward
sense_food_fitness_reward
0.0
4.0
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
987
381
1255
414
input_dc_amplitude
input_dc_amplitude
1000.0
150000.0
20000.0
1000.0
1
NIL
HORIZONTAL

SLIDER
988
427
1161
460
food_source_size
food_source_size
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
988
474
1161
507
nest_size
nest_size
1
10
3.0
1
1
NIL
HORIZONTAL

SWITCH
988
545
1178
578
bring_food_to_nest?
bring_food_to_nest?
0
1
-1000

INPUTBOX
990
593
1106
653
used_random_seed
0.0
1
0
Number

SLIDER
1176
428
1373
461
return_food_reward
return_food_reward
0
500
220.0
1
1
NIL
HORIZONTAL

SLIDER
985
195
1125
228
rotation_cost
rotation_cost
0
1
0.02
0.01
1
NIL
HORIZONTAL

SLIDER
986
232
1142
265
movement_cost
movement_cost
0
5
0.25
0.25
1
NIL
HORIZONTAL

SLIDER
987
269
1149
302
pheromone_cost
pheromone_cost
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
988
306
1160
339
resting_cost
resting_cost
0
5
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
1177
472
1380
505
food_source_amount
food_source_amount
1
5
2.0
1
1
NIL
HORIZONTAL

MONITOR
1143
92
1247
137
collected-food
collected-food
2
1
11

@#$#@#$#@
## WHAT IS IT?

The presented Spiking Neural Network (SNN) model is built in the framework of generalized Integrate-and-fire models which recreate to some extend the phenomenological dynamics of neurons while abstracting the biophysical processes behind them. 


## CREDITS AND REFERENCES

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:


* Cristian Jimenez-Romero, David Sousa-Rodrigues, Jeffrey H. Johnson, Vitorino Ramos
 A Model for Foraging Ants, Controlled by Spiking Neural Networks and Double Pheromonesin UK Workshop on Computational Intelligence 2015, University of Exeter, September 2015.


* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment1" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>collected-food</metric>
    <steppedValueSet variable="used_random_seed" first="1" step="1" last="100"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
