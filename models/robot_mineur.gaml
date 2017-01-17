/**
* Name: robotmineur
* Author: macbookpro
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model robotmineur

/* Insert your model definition here */

global{
	 
	// definition des variables globale
	int nbr_minerais <-10;  
	int nbr_robots <- 10;
	int nbr_minerais_restants <- nbr_minerais;
	int nbr_minerais_ala_base <- 0;
	int grid_size <- 15;  
	float vitesse <- 0.0002;
	float amplitude <- 0.05;
	int nb_robot_port <- 0 ;
	// base de depot des minerais
	environnement base <- environnement[1,2];
	
	// initialisation t=0		
	init{
		create robot number:nbr_robots;	
		create minerais number:nbr_minerais;
		base.color <-  #red;		 
	}
	
	// comportement de fin de la simulation
	reflex fin when: nbr_minerais_ala_base = nbr_minerais{
		do pause;
	} 
	reflex write_results {
	save [cycle, nbr_minerais_restants,  nbr_minerais_ala_base] type: csv to: "result.csv";
	}
	
}
	// Definition de l'environnement 
	grid environnement width:grid_size height: grid_size  neighbors: 4{
		rgb color <- rgb(255,255,255);
		list<environnement> voisins  <- (self neighbors_at 2);
	}
	
	// definition de l'agent robot mineur
	species robot skills:[moving]  control: fsm{
		bool porteur <- false;
		environnement position <- one_of(environnement);
		list<minerais> mines update: minerais inside(position);
		minerais mine;
		
		init {
		location <- position.location; // positionnement initial dans l'environnement
		}
	
		// comportement de deplacement par defaut
		state moving initial: true {
			do wander amplitude:amplitude  speed: vitesse;
		}
	
		
		// comportement de deplacement en fonction des voisins
		reflex move { 
		position <- one_of (position.voisins);
		location <- position.location ;
		}
		
		// comportement de  saisie du minerai
		reflex prendre when: porteur=false{
			if (empty(mines)){
				porteur<-false;
				}
			else{
				mine <- one_of(mines);
					if(mine.a_la_base=false){
					porteur<-true;
					mine.a_la_base<-true;
					nb_robot_port <- nb_robot_port + 1 ;
					}
				}
		}
		
		// comportement de transport
		reflex porter when: porteur=true{
			position<-one_of (position.voisins );
			location  <- any_location_in(position);
			mine.location  <-location;
		}
		
		// comportement de depot
		reflex deposer when: position = base {
			if(porteur=true){
				porteur <- false;
				nbr_minerais_restants <- nbr_minerais_restants-1 ;
				nbr_minerais_ala_base<-nbr_minerais_ala_base+1;
				nb_robot_port <- nb_robot_port - 1 ;
			}
		}
		
		// aspect de l'agent
		aspect default{
			//draw circle(50/grid_size) color: color;
			draw  file("../images/mineur.png") size:6 ;
		}
		
		
	
	
}
	// definition de l'agent minerai
	species minerais{	
		
		environnement position <- one_of(environnement);
		bool a_la_base <- false;	
		
		init {
		location <- position.location;
		}
		
		aspect default{
			draw  file("../images/minerai.png") size:3 ;
		}
	}
	
	//Experience (simulation)
	experiment robot_mineur type:gui{
		//inputs modifiable a  partir de la plateforme
		parameter "Nombre de robot mineurs: " var: nbr_robots;
		parameter "Nombre de minerais: " var: nbr_minerais;
		parameter "Vitesse: " var: vitesse;
		parameter "Amplitude: " var: amplitude;			
		
		// rendu
		output{
			
			// fonction d'affichage de l'environnement et des agents
			display main_display{
				grid environnement;
				image  file:"../images/map.png";
				species robot aspect: default;
				species minerais aspect: default;		
			} 
			
			// courbe d'evolution 
		display diag_display {
				chart "Evolution de la recuperation des minerais" type: series {
				data "Nombre de minerais restants" value: nbr_minerais_restants color: rgb("red");
				data "Nombre de minerais deposes" value: nbr_minerais_ala_base color: rgb("green");
				data "Nombre de robots porteurs de mines" value: nb_robot_port color: rgb("blue");
				}
				}
				monitor "Nombre de minerais restants" value: nbr_minerais_restants;
				monitor "Nombre de minerais deposes" value: nbr_minerais_ala_base;
				}	
			
		}
	
