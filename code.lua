    
    -- title:  simple collision detection
    -- author: Bear Thorne
    -- desc:   Detecting Collision for Grid Movement
    -- script: lua
    
    --VARIABLES

    KEYS={
    	["A"]=1,
    	["B"]=2,
    	["C"]=3,
    	["D"]=4,
    	["E"]=5,
    	["F"]=6,
    	["G"]=7,
    	["H"]=8,
    	["I"]=9,
    	["J"]=10,
    	["K"]=11,
    	["L"]=12,
    	["M"]=13,
    	["N"]=14,
    	["O"]=15,
    	["P"]=16,
    	["Q"]=17,
    	["R"]=18,
    	["S"]=19,
    	["T"]=20,
    	["U"]=21,
    	["V"]=22,
    	["W"]=23,
    	["X"]=24,
    	["Y"]=25,
    	["Z"]=26,
    	["0"]=27,
    	["1"]=28,
    	["2"]=29,
    	["3"]=30,
    	["4"]=31,
    	["5"]=32,
    	["6"]=33,
    	["7"]=34,
    	["8"]=35,
    	["9"]=36,
    	["-"]=37,
    	["="]=38,
    	["["]=39,
    	["]"]=40,
    	["\\"]=41,
    	[";"]=42,
    	["'"]=43,
    	[","]=45,
    	["."]=46,
    	["/"]=47,
    	[" "]=48
	}

	
    
    --sprite vars
    FLOOR=1  --the floor sprite will be stored in the 1 slot
    WALL=224  --the wall sprite will be stored in the 17 slot
    DUDE=16  --the player sprite will be stored in the 33 slot
	TREASURE=194 -- the treasure sprite will be stored in the __ slot
	
    --game constants
    SCREEN_X=29
    SCREEN_Y=16
    MOVEMENT_SPEED=15
    MOVEMENT_DELAY=0
	
	--colors
	TEXT_TYPED = 8
	TEXT_UNTYPED = 13
   
		
	possible_states = {
		title=1,
		chasing=2,
		typing=3
	}
	current_state= possible_states.chasing
	current_treasure=nil
    --FUNCTIONS    

	function start_game()
		trace("starting game")
		 --player object
		 p={
			x=3, --center of screen x
			y=1,
			score=0
		} --center of screen y
		
		treasure = {
			x=3,
			y=2,
			word="something",
			current_pos=1,
			score=100,
			tile=TREASURE,
			consumed=false
		}
	end
	
    --player movement
    --we'll use the btnp() function to detect a single button press
    function move_chasing()
    	x=p.x
    	y=p.y
        --player presses "up"
        if btnp(0,MOVEMENT_DELAY,MOVEMENT_SPEED) then 
         y=p.y-1 
        
        end
        --player presses "down"
    	if btnp(1,MOVEMENT_DELAY,MOVEMENT_SPEED) then 
         y=p.y+1 
        
        end
        --player presses "left"
    	if btnp(2,MOVEMENT_DELAY,MOVEMENT_SPEED) then 
         x=p.x-1 
        
        end
        --player presses "right"
    	if btnp(3,MOVEMENT_DELAY,MOVEMENT_SPEED) then 
         x=p.x+1 
        end
		next_tile = mget(x,y) 
		if treasure.x==x and treasure.y==y and treasure.consumed==false then 
			trace("treasure")
			current_state = possible_states.typing
			current_treasure = treasure
			music(0,0,-1, false)
		elseif next_tile==FLOOR then
        	p.x=x
			p.y=y
		end
		
    end
	
	function process_typing()
		local current_letter = string.upper(current_treasure.word:sub(current_treasure.current_pos,current_treasure.current_pos))
		    
        if keyp(KEYS[current_letter])==true then
			current_treasure.current_pos = current_treasure.current_pos+1

			
			if current_treasure.current_pos==string.len(current_treasure.word)+1 then
				current_treasure.consumed=true
                p.x=current_treasure.x
                p.y=current_treasure.y
				p.score=p.score+current_treasure.score
				current_treasure=nil
				current_state = possible_states.chasing
			end 
		end

	end

	function draw_typing()        
		--Draw rectangle
		rect (8,8,204,104,1)
		rect (10,10,200,100,0) 
		local typed_length = 0
		if current_treasure.current_pos~=1 then
			local typed_text = current_treasure.word:sub(1,current_treasure.current_pos-1)
			print (typed_text, 15, 15, TEXT_TYPED, true, 3 )
			typed_length = string.len(typed_text)
		end
		local untyped_text = current_treasure.word:sub(current_treasure.current_pos,string.len(current_treasure.word))
		print (untyped_text, 15+typed_length*20, 15, TEXT_UNTYPED, true, 3 )
	
	end
	
    --draw screen graphics
    function draw_chasing()
     cls()
     map(0,0,SCREEN_X+1,SCREEN_Y+1)
	
     --multiplying the player coors by 8 (the size of the map cells)
     --gives us grid movement
	 spr(DUDE,p.x*8,p.y*8,8)
	 if treasure.consumed==false then
		 spr(treasure.tile,treasure.x*8,treasure.y*8,8)
	 end
    end
	
	start_game()
	function TIC()
		
		if current_state==possible_states.chasing then
			move_chasing()
			draw_chasing()
		elseif current_state==possible_states.typing then
			process_typing()
            if current_state == possible_states.typing then
			   draw_typing()
            end
		end
    end