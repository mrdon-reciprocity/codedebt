    
    -- title:  simple collision detection
    -- author: Bear Thorne
    -- desc:   Detecting Collision for Grid Movement
    -- script: lua
    
    --VARIABLES
    
    --sprite vars
    FLOOR=1  --the floor sprite will be stored in the 1 slot
    WALL=224  --the wall sprite will be stored in the 17 slot
    DUDE=16  --the player sprite will be stored in the 33 slot
    
    --game constants
    SCREEN_X=29
    SCREEN_Y=16
    
    --player object
    p={
     x=3, --center of screen x
     y=1} --center of screen y
    	
    --FUNCTIONS    

    --player movement
    --we'll use the btnp() function to detect a single button press
    function move()
        --player presses "up"
        if btnp(0) then 
         p.y=p.y-1 
        
        end
        --player presses "down"
    	if btnp(1) then 
         p.y=p.y+1 
        
        end
        --player presses "left"
    	if btnp(2) then 
         p.x=p.x-1 
        
        end
        --player presses "right"
    	if btnp(3) then 
         p.x=p.x+1 
        end
    end
    
    --draw screen graphics
    function draw()
     cls()
     map(0,0,SCREEN_X+1,SCREEN_Y+1)
	
     --multiplying the player coors by 8 (the size of the map cells)
     --gives us grid movement
     spr(DUDE,p.x*8,p.y*8,0)
    end
    
    function TIC()
     move()
    	draw()
    end