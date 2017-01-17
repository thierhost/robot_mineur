/**
* Name: robotmineur2
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model robot

/* Insert your model definition here */
global {
	
	float evaporation_trace <- 5.0 min: 0.0 max: 240.0 parameter: 'Evaporation des traces' ;
	
	float difusion_trace <- 1.0 min: 0.0 max: 1.0 parameter: 'Diffusion des traces:' ;
	int gridsize <- 100 parameter: 'Taille de lenviroennement:';
	//nombre de robot
	int robot_number <- 5 min: 1 parameter: 'Nombre de robot robot:';
	// frequence de mise a jour de lenvironnement
	int grid_frequency <- 1 min: 1 max: 100 parameter: 'Mise a jour de lenvironnement apres:';
	//nombre de minerai
	int number_of_minerai <- 20 min: 1 parameter: 'Nombre de minerai:';
	float grid_transparency <- 1.0;
	file robot_non_porteur const: true <- file('../images/mineur.png') ;
	image_file robot_porteur const: true <- file('../images/mineur.png');
	//definition de la base
	point base const: true <- { 5, 17 };
	
	 
	int minerai_capture <- 1;
	int minerai_placed <- 1;
	rgb background const: true <- rgb(#red);
	rgb minerai_color const: true <- rgb(#yellow);
	rgb nest_color const: true <- rgb(#white); 

	geometry shape <- square(gridsize);
	init {
		// creation des minerai
		create minerai;
		//creation des robots
		create robot number: robot_number with: (location: one_of(robot_grid).location);
	}
	//Reflexion qui permet de degager les traces a la prise dun monerai
	reflex diffuse {
      diffuse var:road on:robot_grid proportion: difusion_trace radius:3 propagation: gradient method:convolution;
   }
  
}
// Environement
grid robot_grid width: gridsize height: gridsize neighbors: 8 frequency: grid_frequency use_regular_agents: false use_individual_shapes: false{
	bool is_nest const: true <- (topology(robot_grid) distance_between [self, base]) < 4;
	float road <- 0.0 max: 240.0 update: (road <= evaporation_trace) ? 0.0 : road - evaporation_trace;
	rgb color <- is_nest ? nest_color : ((mine > 0) ? minerai_color : ((road < 0.001) ? background : rgb(#009900) + int(road * 5))) update: is_nest ? nest_color : ((mine > 0) ?
	minerai_color : ((road < 0.001) ? background : rgb(#009900) + int(road * 5)));
	int mine <- 0;
}

//agent robot
species robot skills:[moving]  control: fsm{
		bool porteur <- false;
		
		point point_suivant {
		container list_places <- robot_grid(location).neighbors;
		if (list_places count (each.mine > 0)) > 0 {
			return point(list_places first_with (each.mine > 0));
		} else {
			list_places <- (list_places where ((each.road > 0) and ((each distance_to base) > (self distance_to base)))) sort_by (each.road);
			return point(last(list_places));
		}

		}
	
		state wandering initial: true {
			do wander(amplitude: 90 );
			float pr <- (robot_grid(location)).road;
			transition to: transporter when: porteur=true;
			transition to: suivre_trace when: (pr > 0.05) and (pr < 4);
		}
		//Etat de transport du minerai
		state transporter {
			do goto(target: base);
			transition to: wandering when: porteur=false;
		}
		//Etat permettant de suivre les traces des autres robots
		state suivre_trace {
			point next_place <- point_suivant();
			float pr <- (robot_grid(location)).road;
			location <- next_place;
			transition to: transporter when: porteur=true;
			transition to: wandering when: (pr < 0.05) or (next_place = nil);
		}


			
		action deposer_minerai {
			minerai_capture <- minerai_capture + 1;
			porteur <- false;
			heading <- heading - 180;
		}

		reflex prendre_minerai when: porteur=false and (robot_grid(location)).mine > 0 {
			porteur <- true;
			robot_grid place <- robot_grid(location);
			place.mine <- place.mine - 1;	
			
		}	
		
		// comportement permettant de laisser des traces a la saisie dun minerai
		reflex diffuse_road when: porteur=true{
		 robot_grid(location).road <- robot_grid(location).road + 100.0;
		}
		//Reflexe de deposer le minerai a la base
		reflex deposer_minerai when: porteur=true and (robot_grid(location)).is_nest {
			do deposer_minerai();
		}
		aspect info {
		draw circle(1) empty: !porteur color: #red;
		if (destination != nil) {
			draw line([location + {0,0,0.5}, destination + {0,0,0.5}]) + 0.1 color: #white border: false;
		}

	    draw circle(4) empty: true color: #white;
		draw string(self as int) color: #white font: font("Helvetica", 12 * #zoom, #bold) at: my location - {1, 1, -0.5};
		draw state color: #yellow  font: font("Helvetica", 10 * #zoom, #plain) at: my location + { 1, 1, 0.5 } perspective: false;
	}

	aspect icon {
		draw robot_non_porteur  size: {7,5};
	}

	aspect default {
		draw square(1) empty: !porteur color: #blue;
	}
		
}

// agent minerai
species minerai {
	init {
		loop times: number_of_minerai {
			point loc <- { rnd(gridsize - 10) + 5, rnd(gridsize - 10) + 5 };
			list<robot_grid> minerai_places <- robot_grid(loc);
			ask minerai_places {
				if mine = 0 {
					mine <- 1;
					minerai_places <- minerai_places + 1;
					color <- minerai_color;  
				}                                           
			}
		}
	}
	
}

// simulation
experiment exp type: gui {
	parameter 'Nombre de robots:' var: robot_number  ;
	parameter 'Nombre de minerais:' var: number_of_minerai ;

	// Experimentator

	output {
		display Robot_Simulation {
			image '../images/map.png' position: { 0.05, 0.05 } size: { 0.9, 0.9 };
			agents "agents" transparency: 0.7 position: { 0.05, 0.05 } size: { 0.9, 0.9 } value: (robot_grid as list) where ((each.mine > 0) or (each.road > 0) or (each.is_nest)) ;
			species robot position: { 0.05, 0.05 }  aspect: icon;		
		}
		inspect "Les robots"  value: robot attributes: ['name', 'location', 'heading','state'];
	}
}

