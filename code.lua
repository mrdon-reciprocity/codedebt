
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
        ["_"]=44,
    	[","]=45,
    	["."]=46,
    	["/"]=47,
    	[" "]=48
	}

    KEYS_BY_CODE = {}
    for k, v in pairs(KEYS) do
        KEYS_BY_CODE[v] = k
    end
    
    --sprite vars
    FLOOR=1  --the floor sprite will be stored in the 1 slot
    WALL=224  --the wall sprite will be stored in the 17 slot
    DUDE=16  --the player sprite will be stored in the 33 slot
	TREASURE=194 -- the treasure sprite will be stored in the __ slot
    EXIT=196 -- exit door end game
    BAG_GUY=96

    --game constants
    SCREEN_X=29
    SCREEN_Y=16
    WINDOW_X=240
    WINDOW_Y=136
    MOVEMENT_SPEED=15
    MOVEMENT_DELAY=0
	
	--colors
	TEXT_TYPED = 8
	TEXT_UNTYPED = 13
	TEXT_BAD = 9
    SCORE_LINE = 2
    SCORE_TIMELOW = 6
   
    --math.randomseed(os.time())
		
	possible_states = {
		menu=1,
		chasing=2,
		typing=3,
        gameover=4        
	}
	current_state= possible_states.menu
	current_treasure=nil

	exit_door = {
		x=28,
		y=3,
		tile=EXIT
	}

    --FUNCTIONS    

	function start_game()
		trace("starting game")
		 --player object
		 p={
			x=3, --center of screen x
			y=1,
			score=0
		} --center of screen y
		
        

        treasures = {}
	treasure_words = {
		"ServiceNow",
		"Blocker",
		"Reccurrence",
		"Fix bug",
		"Coffee",
		"Meeting",
		"Another meeting",
		"Vulnerability",
		"GitHub is down",
		"Audit Wizard",
		"Fix bug"
	}
        for x=1,10,1 do
            local tx = 0
            local ty = 0
            while tx == 0 do
                tx = math.random(SCREEN_X)
                ty = math.random(SCREEN_Y)
                if mget(tx, ty) ~= FLOOR then
                    tx = 0
                end
            end
            treasures[x] =  {
                x=tx,
                y=ty,
                word=treasure_words[x],
                current_pos=1,
                current_char_code=KEYS["_"],
                score=100,
                tile=TREASURE,
                consumed=false
            }
        end

        game_start_time = time()
        current_state = possible_states.chasing
        generate_bad_guys()
    end
    
    function generate_bad_guys()
        bad_guys={}
        for x=1,5,1 do
            local bx = 0
            local by = 0
            while bx == 0 do
                bx = math.random(SCREEN_X)
                by = math.random(SCREEN_Y)
                if mget(bx, by) ~= FLOOR then
                    bx = 0
                end
                for pos=1,#treasures,1 do
                    local treasure = treasures[pos]
                    if treasure.x==bx and treasure.y==by then 
                        bx = 0
                    end
                end
            end
            bad_guys[x] =  {
                x=bx,
                y=by,
                score=100,
                tile=BAG_GUY,
                consumed=false
            }
        end
    end
	
    --player movement
    --we'll use the btnp() function to detect a single button press
    function move_chasing()
        time_in_game = (time() - game_start_time) / 1000


    	x=p.x
    	y=p.y
        --player presses "up"
        if btnp(0,MOVEMENT_DELAY,MOVEMENT_SPEED) then 
         y=p.y-1
	 music(3, 0, -1, false)
        
        end
        --player presses "down"
    	if btnp(1,MOVEMENT_DELAY,MOVEMENT_SPEED) then 
         y=p.y+1 
         music(3, 0, -1, false)

        
        end
        --player presses "left"
    	if btnp(2,MOVEMENT_DELAY,MOVEMENT_SPEED) then 
         x=p.x-1 
         music(3, 0, -1, false)

        end
        --player presses "right"
    	if btnp(3,MOVEMENT_DELAY,MOVEMENT_SPEED) then 
         x=p.x+1 
         music(3, 0, -1, false)

        end
		next_tile = mget(x,y) 

        local found=false
        for pos=1,#treasures,1 do
            local treasure = treasures[pos]
    		if treasure.x==x and treasure.y==y and treasure.consumed==false then 
    			trace("treasure")
    			current_state = possible_states.typing
    			current_treasure = treasure
    			music(0,0,-1, false)
                found=true
    		end
        end
        
        for pos=1,#bad_guys,1 do
            local bad_guy = bad_guys[pos]
    		if bad_guy.x==x and bad_guy.y==y and bad_guy.consumed==false then 
                music(0,0,-1, false)
                bad_guy.consumed=true
                p.score = p.score - bad_guy.score
                found=true
    		end
		end

		if found == false then
			if exit_door.x==x and exit_door.y==y then 
				current_state= possible_states.gameover
                music(2, 0, -1, false)
				p.score= p.score+500
			elseif next_tile==FLOOR then
                p.x=x
                p.y=y
            end
        end
    end
	
	function process_typing()
		local current_letter = string.upper(current_treasure.word:sub(current_treasure.current_pos,current_treasure.current_pos))
		    
        if keyp(KEYS[current_letter])==true then
			current_treasure.current_pos = current_treasure.current_pos+1
            current_treasure.current_char_code = KEYS["_"]
		elseif btnp(0, 10, 10) then
            current_treasure.current_char_code = current_treasure.current_char_code + 1
            if current_treasure.current_char_code > 48 then
                current_treasure.current_char_code = 1
            end
        elseif btnp(1, 10, 10) then
            current_treasure.current_char_code = current_treasure.current_char_code - 1
            if current_treasure .current_char_code < 1 then
                current_treasure.current_char_code = 48
            end
        end
        if KEYS_BY_CODE[current_treasure.current_char_code] == current_letter then
            current_treasure.current_pos = current_treasure.current_pos + 1
            current_treasure.current_char_code = KEYS["_"]
        end
        if current_treasure.current_pos==string.len(current_treasure.word)+1 then
            current_treasure.consumed=true
            p.x=current_treasure.x
            p.y=current_treasure.y
            p.score=p.score+current_treasure.score
            current_treasure=nil
            current_state = possible_states.chasing
            music(1, 0, -1, false)
        end 
	end

	function draw_typing()        
		--Draw rectangle
		rect (8,8,204,104,1)
		rect (10,10,200,100,0) 

        print (current_treasure.word, 15, 15, TEXT_UNTYPED, true, 3)       


		local typed_length = 0
		if current_treasure.current_pos~=1 then
			local typed_text = current_treasure.word:sub(1,current_treasure.current_pos-1)
			
			print (typed_text, 15, 35, TEXT_TYPED, true, 3 )
			typed_length = string.len(typed_text)
		end

        print(KEYS_BY_CODE[current_treasure.current_char_code], 15 + typed_length * 18, 35, TEXT_UNTYPED, true, 3)
	end

	function game_over_menu()
        game_over_menu_cursor = 1
        game_over_menu_options = {"Play again", "Quit"}
    end
	
	function draw_game_over()
        cls()
        for x=1,14,2 do
            rectb(2+x, 1+x, 240-4-x, 136-2-x,x)
        end

		local offset = 40
		local text_color = TEXT_TYPED
		local text_ = "Success"
		if p.score <= 600 then
			text_color = TEXT_BAD
			text_ = "No release"
		end
		print(text_, 30, 30, text_color, false, 3)
		print("Your score: "..p.score, 30, 50, TEXT_TYPED, false, 1)
        for k, v in pairs(game_over_menu_options) do
            if k == game_over_menu_cursor then
                print(v, 50, offset * k + 30, TEXT_TYPED, false, 2)
            else
                print(v, 50, offset * k + 30, TEXT_UNTYPED, false, 1.5)
            end
        end
	end

	function game_over_process_menu()
        if btnp(0) then 
            game_over_menu_cursor = game_over_menu_cursor - 1
            if game_over_menu_cursor < 1 then
                game_over_menu_cursor = #menu_game_over_menu_options
            end
        elseif btnp(1) then
            game_over_menu_cursor = game_over_menu_cursor + 1
            if game_over_menu_cursor > #game_over_menu_options then 
                game_over_menu_cursor = 1
            end
        elseif btnp(4) or keyp(50)then
			if game_over_menu_cursor == 1 then
				current_state = possible_states.chasing
                start_game()
            elseif game_over_menu_cursor == 2 then
                exit()
            end
        end
    end

    function start_menu()
        menu_cursor = 1
        menu_options = {"Play", "Quit"}
        current_state = possible_states.menu
    end

    function draw_menu()
        cls()
        local offset = math.floor(time() / 1000) % 5
        
        for x=1,5,1 do
            local color = x + offset
            if color > 7 then
                color = color -7
            end
            local xoffset = 
            rectb(2+(2*x), 1+(2*x), WINDOW_X-(2*x)-4, WINDOW_Y-(2*x)-2,color)
        end

        local offset = 40
        print("Code Debt", 30, 30, TEXT_TYPED, false, 3)
        for k, v in pairs(menu_options) do
            if k == menu_cursor then
                print(v, 50, offset * k + 30, TEXT_TYPED, false, 2)
            else
                print(v, 50, offset * k + 30, TEXT_UNTYPED, false, 1.5)
            end
        end
    end

    function process_menu()
        if btnp(0) then 
            menu_cursor = menu_cursor - 1
            if menu_cursor < 1 then
                menu_cursor = #menu_options
            end
        elseif btnp(1) then
            menu_cursor = menu_cursor + 1
            if menu_cursor > #menu_options then 
                menu_cursor = 1
            end
        elseif btnp(4) or keyp(50)then
            if menu_cursor == 1 then
                start_game()
            elseif menu_cursor == 2 then
                exit()
            end
        end
    end
	
    --draw screen graphics
    function draw_chasing()
     cls()
     map(0,0,SCREEN_X+1,SCREEN_Y+1)
	
     --multiplying the player coors by 8 (the size of the map cells)
     --gives us grid movement
	 spr(DUDE,p.x*8,p.y*8,8)

     for pos=1,#treasures,1 do
         local treasure = treasures[pos]
    	 if treasure.consumed==false then
    		 spr(treasure.tile,treasure.x*8,treasure.y*8,8)
    	 end
     end
     

     local secs_in_game = math.floor((time() - game_start_time) / 1000)
     local time_left = 0
     if secs_in_game < 30 then
        time_left = 30 - secs_in_game
     end
     local timer_color = SCORE_LINE
     if time_left < 4 then
        timer_color = SCORE_TIMELOW
	 end
	 
	 if time_left==0 then
		current_state=possible_states.gameover
	 end
     
     if time_left<=28 then
        for pos=1,#bad_guys,1 do
            local bad_guy = bad_guys[pos]
            if bad_guy.consumed==false then
                local bad_guy = bad_guys[pos]
                spr(bad_guy.tile,bad_guy.x*8,bad_guy.y*8,8)
            end
        end
    end
	 print("Time left: "..time_left, 10, WINDOW_Y - 10, timer_color, false, 1)
     print("Score: "..p.score, WINDOW_X/2, WINDOW_Y - 10, SCORE_LINE, false, 1)
    end
	
	start_menu()
	game_over_menu()
	function TIC()
		
        if current_state == possible_states.menu then
            process_menu()
            draw_menu()
		elseif current_state==possible_states.chasing then
			move_chasing()
			draw_chasing()
		elseif current_state==possible_states.typing then
			process_typing()
            if current_state == possible_states.typing then
			   draw_typing()
			end
		elseif current_state == possible_states.gameover then
			game_over_process_menu()
			draw_game_over()
		end
    end
