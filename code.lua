    
    -- title:  simple collision detection
    -- author: Bear Thorne
    -- desc:   Detecting Collision for Grid Movement
    -- script: lua
    
    --VARIABLES

    KEYS={
    	A=1,
    	B=2,
    	C=3,
    	D=4,
    	E=5,
    	F=6,
    	G=7,
    	H=8,
    	I=9,
    	J=10,
    	K=11,
    	L=12,
    	M=13,
    	N=14,
    	O=15,
    	P=16,
    	Q=17,
    	R=18,
    	S=19,
    	T=20,
    	U=21,
    	V=22,
    	W=23,
    	X=24,
    	Y=26,
    	Z=27
	}
    
    --sprite vars
    FLOOR=1  --the floor sprite will be stored in the 1 slot
    WALL=224  --the wall sprite will be stored in the 17 slot
    DUDE=16  --the player sprite will be stored in the 33 slot
       
    --game constants
    SCREEN_X=29
    SCREEN_Y=16
    MOVEMENT_SPEED=15
    MOVEMENT_DELAY=0
    
    --player object
    p={
     x=3, --center of screen x
     y=1} --center of screen y
    	
    --FUNCTIONS    

    --player movement
    --we'll use the btnp() function to detect a single button press
    function move()
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

        if mget(x,y)==FLOOR then
        	p.x=x
        	p.y=y
        end
    end
    
    --draw screen graphics
    function draw()
     cls()
     map(0,0,SCREEN_X+1,SCREEN_Y+1)
	
     --multiplying the player coors by 8 (the size of the map cells)
     --gives us grid movement
     spr(DUDE,p.x*8,p.y*8,8)
    end
    
    function TIC()
        move()
    	draw()
    end