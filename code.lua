-- title:  QUEST FOR GLORY
-- author: Deck http://deck.itch.io
-- desc:   roguelike game
-- script: lua
-- input:  gamepad

-- constants
local CAM_W=240
local CAM_H=136
local MAP_W=1920
local MAP_H=1088
local CELL=8
local foo=2

local tiles={
	KEY=176,
	HEART=177,
	POTION=178,
	SPIKES_HARMLESS=192,
	SPIKES_HARM=193,
	CLOSED_COFFER=194,
	OPENED_COFFER=195,
	CLOSED_DOOR=196,
	OPENED_DOOR=197,
	CLOSED_GRATE=198,
	OPENED_GRATE=199,
	SKULL=208,
	DESK=209,
	STATUE_1=210,
	COLUMN=211,
	CRACK=212,
	MIMIC_HARMLESS=213,
	MIMIC_HARM=214,
	KEY_FLOOR=215,
	ALTAR=217,
	CHAIR=218,
	STATUE_2=219,
	KEY_FLOOR_PICKED_UP=216,
	WALL_1=224,
	WALL_2=225,
	VINE_1=226,
	VINE_2=227,
	VINE_3=228,
	FOOTBOARD_DOWN=229,
	FOOTBOARD_UP=230,
	MAGIC_FLUID_1=237,
	MAGIC_FLUID_2=238,
	MAGIC_FLUID_3=239,
	CRYSTAL_WHOLE=251,
	CRYSTAL_BROKEN=252,
	LAVA_1=253,
	LAVA_2=254,
	LAVA_3=255
}

-- global variables
local t=0	-- global time, used in TIC() method
local cam={x=0,y=0}
local mobs={}
local animTiles={}
local traps={}
local bullets={}
local firstRun=true

	
-- debug utilities
local function PrintDebug(object)
	for i,v in pairs(object) do
		-- printable elements
		if type(v)~="table" and type(v)~="boolean" and type(v)~="function" and v~=nil then
			trace("["..i.."] "..v)
		-- boolean
		elseif type(v)=="boolean" then
			trace("["..i.."] "..(v and "true" or "false"))
		-- table, only ids
		elseif type(v)=="table" then
			local txt="["
			for y,k in pairs(v) do
				txt=txt..(y..",")
			end
			txt=txt.."]"
			trace("["..i.."] "..txt)
		-- function
		elseif type(v)=="function" then
			trace("["..i.."] ".."function")
		end
	end		
	trace("------------------")
end

------------------------------------------
-- collision class
local Collision={}

function Collision:GetEdges(x,y,w,h)
	local w=w or CELL-1
	local h=h or CELL-1
	local x=x+(CELL-w)/2
	local y=y+(CELL-h)/2
	
	-- get the map ids in the edges	
	local topLeft=mget(x/CELL,y/CELL)
	local topRight=mget((x+w)/CELL,y/CELL)
	local bottomLeft=mget(x/CELL,(y+h)/CELL)
	local bottomRight=mget((x+w)/CELL,(y+h)/CELL)
	
	return topLeft,topRight,bottomLeft,bottomRight
end

function Collision:CheckSolid(indx)
	return indx==tiles.WALL_1 or					
			  indx==tiles.WALL_2 or
			  indx==tiles.CLOSED_GRATE or
			  indx==tiles.MIMIC_HARM or
			  indx==tiles.COLUMN or
			  indx==tiles.DESK or
			  indx==tiles.STATUE_1 or
			  indx==tiles.STATUE_2 or
			  indx==tiles.ALTAR or
			  indx==tiles.CRYSTAL_WHOLE or
			  indx==tiles.CLOSED_DOOR or		
			  indx==tiles.CLOSED_COFFER	or	
			  indx==tiles.OPENED_COFFER
end

function Collision:CheckDanger(indx)
	return indx==tiles.LAVA_1 or
			  indx==tiles.LAVA_2 or
			  indx==tiles.LAVA_3 or
			  indx==tiles.MIMIC_HARM or
			  indx==tiles.SPIKES_HARM or
			  indx==tiles.FOOTBOARD_DOWN
end

------------------------------------------
-- animation class
local function Anim(span,frames,loop)
	local s={
		span=span or 60,
		frame=0,
		loop=loop==nil and true or false, -- this code sucks!
		tick=0,
		indx=0,
		frames=frames or {},
		ended=false
	}
	
	function s.Update(time)	
		if time>=s.tick and #s.frames>0 then
			if s.loop then
				s.indx=(s.indx+1)%#s.frames
				s.frame=s.frames[s.indx+1]
				s.ended=false
			else
				s.indx=s.indx<#s.frames and s.indx+1 or #s.frames
				s.frame=s.frames[s.indx]
				if s.indx==#s.frames then s.ended=true end
			end
			s.tick=time+s.span
		end 
	end
	
	function s.RandomIndx()
		s.indx=math.random(#s.frames)
	end
	
	function s.Reset()
			s.indx=0
			s.ended=false
	end
	
	return s
end

------------------------------------------
-- animated tile class
local function AnimTile(cellX,cellY,anim)
	local s={
		cellX=cellX or 0,
		cellY=cellY or 0,
		anim=anim
	}
	
	function s.Display(time)
		if s.anim==nil then return end
		s.anim.Update(time)
		mset(s.cellX,s.cellY,s.anim.frame)
	end
	
	return s
end

------------------------------------------
-- trap class
local function Trap(cellX,cellY,idSafe,idDanger)
	local s={
		cellX=cellX or 0,
		cellY=cellY or 0,
		timeSafe=180,
		timeDanger=120,
		idSafe=idSafe,
		idDanger=idDanger,
		dangerous=math.random(2)-1==0,
		frame=nil,
		tick=0
	}
	
	function s.Update(time)
		if time>=s.tick and s.dangerous then
			s.frame=s.idSafe
			s.dangerous=false
			s.tick=time+s.timeSafe
		elseif time>=s.tick and not s.dangerous then
			s.frame=s.idDanger
			s.dangerous=true
			s.tick=time+s.timeDanger
		end
	end
	
	function s.Display(time)
		mset(s.cellX,s.cellY,s.frame)
	end
	
	return s
end

------------------------------------------
-- bullet class
local function Bullet(x,y,vx,vy)
	local s={
		tag="bullet",
		x=x or 0,
		y=y or 0,
		vx=vx or 0,
		vy=vy or 0,
		anims={},	-- move, collided
		alpha=8,
		died=false,
		range=4*CELL,
		power=1,
		player=nil,
		xStart=x or 0,
		yStart=y or 0,
		curAnim=nil,
		flip=false,
		collided=false,
		visible=true
	}

	function s.Move()	
		-- detect flip
		if s.vx~=0 then s.flip=s.vx<0 and 1 or 0 end
		
		-- next position
		local nx=s.x+s.vx
		local ny=s.y+s.vy
		
		-- check the collision on the edges
		local tl,tr,bl,br=Collision:GetEdges(nx,ny,CELL-3,CELL-3)
		
		if not Collision:CheckSolid(tl) and not
				 Collision:CheckSolid(tr) and not
				 Collision:CheckSolid(bl) and not
				 Collision:CheckSolid(br) then
			s.x=nx
			s.y=ny
			if not s.collided then s.curAnim=s.anims.move end
		else
			s.Collide()
		end
	
    	-- bounds
		if s.x<0 then s.x=0 end
		if s.x>MAP_W-CELL then s.x=MAP_W-CELL end
		if s.y<0 then s.y=0 end
		if s.y>MAP_H-CELL then s.y=MAP_H-CELL end	
	end
	
	function s.Collide()
		if not s.collided then
			s.curAnim=s.anims.collided
			s.curAnim.Reset()
			s.collided=true
		end
	end
	
	function s.Update(time)
		-- detect if we are in the camera bounds
		s.visible=s.x>=cam.x and s.x<=cam.x+CAM_W-CELL and s.y>=cam.y and s.y<=cam.y+CAM_H-CELL

		-- do something at the end of the animation
		-- for the bullet means that it is in collided state
		if s.curAnim~=nil and s.curAnim.ended then
			s.died=true
			s.visible=false
		end
		
		-- block the movement with these conditions
		if s.died or s.collided then return end
		
		s.Move()
		
		-- detect collisions with the player
		local dx=s.player.x-s.x
		local dy=s.player.y-s.y
		local dst=math.sqrt(dx^2+dy^2)
		if dst<=CELL then
			s.Collide()
			s.player.Damaged(s.power)
		end

		-- if the range is exceeded, ends the life of the bullet
		local dx=s.x-s.xStart
		local dy=s.y-s.yStart
		if math.sqrt(dx^2+dy^2)>s.range then s.Collide() end		
	end
	
	function s.Display(time)
		if s.curAnim==nil then return end
		s.curAnim.Update(time)
		-- arrangement to correctly display it in the map
		local x=(s.x-cam.x)%CAM_W
		local y=(s.y-cam.y)%CAM_H
		if s.visible then
			spr(s.curAnim.frame,x,y,s.alpha,1,s.flip)
			-- rectb(x,y,CELL,CELL,14)
		end		
	end
	
	return s
end

------------------------------------------
-- mob class
local function Mob(x,y,player)
	local s={
		tag="mob",
		x=x or 0,
		y=y or 0,
		alpha=8,
		anims={},	-- idle, walk, attack, die, damaged
		health=3,
		power=1,
		fov=6*CELL,
		proximity=CELL-2,		
		died=false,
		dx=0,
		dy=0,
		flip=false,
		visible=true,
		curAnim=nil,
		attack=false,
		damaged=false,
		tick=0,
		player=player,
		damageable=true,	-- affected by traps or dangerous fluids
		minAttackDelay=30,
		maxAttackDelay=100,
		score=0,
		speed=0.3+math.random()*0.1
	}
	
	function s.Move(dx,dy)
		-- block movement with these conditions
		if s.died or s.attack then return end
	
		-- store deltas, they could be useful
		s.dx=dx
		s.dy=dy
		
		-- detect flip
		if dx~=0 then s.flip=dx<0 and 1 or 0 end
		
		-- next position
		local nx=s.x+dx
		local ny=s.y+dy
	
		-- check the collision on the edges
		local tl,tr,bl,br=Collision:GetEdges(nx,ny,CELL-2,CELL-2)
		
		if not Collision:CheckSolid(tl) and not
				 Collision:CheckSolid(tr) and not
				 Collision:CheckSolid(bl) and not
				 Collision:CheckSolid(br) then
			s.x=nx
			s.y=ny
			if not s.damaged then s.curAnim=s.anims.walk end
		end
	
    	-- bounds
		if s.x<0 then s.x=0 end
		if s.x>MAP_W-CELL then s.x=MAP_W-CELL end
		if s.y<0 then s.y=0 end
		if s.y>MAP_H-CELL then s.y=MAP_H-CELL end
	end
	
	function s.Attack()
		if not s.attack then
			if s.player~=nil then s.player.Damaged(s.power) end
			s.curAnim=s.anims.attack
			s.curAnim.Reset()
			s.attack=true
		end
	end
	
	function s.Damaged(amount)
		if not s.damaged and not s.died then
			s.curAnim=s.anims.damaged
			s.curAnim.Reset()
			s.damaged=true
			local amt=amount or 1
			s.health=s.health-amt
			if s.health<=0 then s.Die() end
		end
	end
	
	function s.Die()
		if not s.died then
			s.curAnim=s.anims.die
			s.curAnim.Reset()
			s.died=true
			if player~=nil then player.points=player.points+s.score end
		end
	end
	
	function s.Update(time)
		-- detect if we are in the camera bounds
		s.visible=s.x>=cam.x and s.x<=cam.x+CAM_W-CELL and s.y>=cam.y and s.y<=cam.y+CAM_H-CELL
		
		-- do something at the end of the animation
		-- int the case of the mob stop to stay in particular states
		if s.curAnim~=nil and s.curAnim.ended then
			-- s.died=false
			s.attack=false
			s.damaged=false
		end
	
		-- prevent update if it is in particular states
		if s.died or s.attack then return end
		
		-- default: idle
		if not s.died and not s.damaged then s.curAnim=s.anims.idle end
		
		-- move closer to the player if in range
		if s.player~=nil then
			local dx=s.player.x-s.x
			local dy=s.player.y-s.y
			local dst=math.sqrt(dx^2+dy^2)
			if dst<s.fov then
				if dst>=s.proximity then
					if math.abs(dx)>=s.speed then s.Move(dx>0 and s.speed or -s.speed,0) end
					if math.abs(dy)>=s.speed then s.Move(0,dy>0 and s.speed or -s.speed) end
				end
			end
			
			-- try to attack the player
			if dst<=s.proximity then
				s.flip=(s.x-s.player.x) > 0 and 1 or 0
				if time>s.tick then
					s.Attack()
					s.tick=time+math.random(s.minAttackDelay,s.maxAttackDelay)
				end
			-- first contact
			else
				s.tick=time+math.random(0,s.maxAttackDelay)
			end
		end
		
		-- check if damaged
		if s.damageable then
			local tl,tr,bl,br=Collision:GetEdges(s.x-s.dx,s.y-s.dy,2,2)
			if Collision:CheckDanger(tl) or
			   Collision:CheckDanger(tr) or
			   Collision:CheckDanger(bl) or
			   Collision:CheckDanger(br) then
				s.Damaged()
			end
		end
	end
	
	function s.Display(time)
		if s.curAnim==nil then return end
		s.curAnim.Update(time)
		-- arrangement to correctly display it in the map
		local x=(s.x-cam.x)%CAM_W
		local y=(s.y-cam.y)%CAM_H
		if s.visible then
			spr(s.curAnim.frame,x,y,s.alpha,1,s.flip)
			-- rectb(x,y,CELL,CELL,14)
		end		
	end

	return s
end

------------------------------------------
-- mob caster:mob class
local function MobCaster(x,y,player)
	local s=Mob(x,y,player)
	s.tag="mob_caster"
	s.minAttackDelay=90
	s.maxAttackDelay=180
	s.fov=8*CELL
	s.proximity=4*CELL
	s.CreateBullet=function(x,y,vx,vy) return nil end	-- override, must return a Bullet object
	
	function s.Attack()
		if not s.attack then
			-- calculate the direction
			local speed=0.3
			local angle=math.atan2(s.y-(s.player.y+CELL/2),s.x-(s.player.x+CELL/2))
			local dir=(s.x-s.player.x)>0 and -4 or 4
			-- create bullet object
			local b=s.CreateBullet(s.x+dir,s.y,-speed*math.cos(angle),-speed*math.sin(angle))
			table.insert(bullets,b)
			-- update the animation
			s.curAnim=s.anims.attack
			s.curAnim.Reset()
			s.attack=true
		end
	end
	
	return s
end

------------------------------------------
-- boss:mob caster class
local function Boss(x,y,player)
	local s=MobCaster(x,y,player)
	s.tag="boss"
	s.minAttackDelay=40
	s.maxAttackDelay=120
	s.health=10
	s.score=15
	s.damageable=false
	
	s.anims={
		idle=Anim(25,{128,129,130,131}),
		walk=Anim(15,{128,129,130,131}),	
		attack=Anim(15,{132,133,128},false),
		die=Anim(5,{132,137,138,139,140,141},false),
		damaged=Anim(20,{142,128},false)
	}
	
	function s.CreateBullet(x,y,vx,vy)
		local b=Bullet(x,y,vx,vy)
		b.player=s.player
		b.power=s.power
		b.anims={
			move=Anim(5,{118,119,120}),
			collided=Anim(15,{134,135,136},false)
		}
		return b
	end
	
	function s.Attack()
		if not s.attack then
			-- create bullets objects
			local num=6
			for i=1,num do
				-- the boss randomly spawn 6 bullets from his staff
				local speed=0.3
				local angle=math.random()*2*math.pi
				local dir=(s.x-s.player.x)>0 and -3 or 3
				-- create bullet object
				local b=s.CreateBullet(s.x+dir,s.y-CELL-2,-speed*math.cos(angle),-speed*math.sin(angle))
				table.insert(bullets,b)
			end
			-- update the animation
			s.curAnim=s.anims.attack
			s.curAnim.Reset()
			s.attack=true
		end
	end
	
	function s.Move(dx,dy)
		-- block movement with these conditions
		if s.died or s.attack then return end
	
		-- store deltas, they could be useful
		s.dx=dx
		s.dy=dy
		
		-- detect flip
		if dx~=0 then s.flip=dx<0 and 1 or 0 end
		
		-- next position
		local nx=s.x+dx
		local ny=s.y+dy
	
		-- check the collision on the edges
		local tl1,tr1,bl1,br1=Collision:GetEdges(nx,ny,CELL-2,CELL-2)
		local tl2,tr2,bl2,br2=Collision:GetEdges(nx,ny-CELL,CELL-2,CELL-2)
		
		if not Collision:CheckSolid(tl1) and not
				 Collision:CheckSolid(tr1) and not
				 Collision:CheckSolid(bl1) and not
				 Collision:CheckSolid(br1) and not
				 Collision:CheckSolid(tl2) and not
				 Collision:CheckSolid(tr2) and not
				 Collision:CheckSolid(bl2) and not
				 Collision:CheckSolid(br2) then
			s.x=nx
			s.y=ny
			if not s.damaged then s.curAnim=s.anims.walk end
		end
	end
	
	function s.Display(time)
		if s.curAnim==nil then return end
		s.curAnim.Update(time)
		-- arrangement to correctly display it in the map
		local x=(s.x-cam.x)%CAM_W
		local y=(s.y-cam.y)%CAM_H
		if s.visible then
			spr(s.curAnim.frame,x,y,s.alpha,1,s.flip)
			spr(s.curAnim.frame-16,x,y-CELL,s.alpha,1,s.flip)
		end		
	end
	
	return s
end

------------------------------------------
-- player:mob class
local function Player(x,y)
	local s=Mob(x,y)
	s.tag="player"
	s.keys=0
	s.potions=0
	s.health=5
	s.maxHealth=5
	s.points=0
	
	s.anims={
		idle=Anim(60,{16,17}),
		walk=Anim(15,{18,19}),	
		attack=Anim(15,{20,17},false),
		die=Anim(5,{21,22,23,24,25},false),
		damaged=Anim(20,{26,17},false)
	}
	
	-- store the super method
	local supMove=s.Move
	
	function s.Move(dx,dy)
		-- call super.move
		supMove(dx,dy)
		
		-- flip
		if dx~=0 then s.flip=dx<0 and 1 or 0 end
		
		-- detect collisions with special elements
		CheckDoors(dx,dy)
		CheckCoffers(dx,dy)
		CheckKeys(dx,dy)
	end
	
	function s.Update(time)		
		s.dx=0
		s.dy=0
		
		-- do something at the end of the animation
		-- in the case of player stop to stay in particular states
		if s.curAnim~=nil and s.curAnim.ended then
			-- s.died=false
			s.attack=false
			s.damaged=false
		end
		
		-- prevent update in these particular states
		if s.died or s.attack then return end	
		
		-- default: idle
		if not s.damaged then s.curAnim=s.anims.idle end
		
		-- manage the user input
		-- arrows [0,1,2,3].......movement
		-- z [4].........................attack
		-- x [5].........................healing
		if btn(5) and s.health<s.maxHealth and s.potions>0 then
			s.health=s.maxHealth
			s.potions=s.potions-1
			if s.health > s.maxHealth then s.health=s.maxHealth end
		end
		if btn(4) then s.Attack() end
		if btn(0) then s.Move(0,-1) end
		if btn(1) then s.Move(0,1) end
		if btn(2) then s.Move(-1,0) end
		if btn(3) then s.Move(1,0)	end
		
		-- check if damaged
		if s.damageable then
			local tl,tr,bl,br=Collision:GetEdges(s.x-s.dx,s.y-s.dy,2,2)
			if Collision:CheckDanger(tl) or
			   Collision:CheckDanger(tr) or
			   Collision:CheckDanger(bl) or
			   Collision:CheckDanger(br) then
				s.Damaged()
			end
		end
		
		-- check enemies
		for i,mob in pairs(mobs) do
			-- collision detected
			if math.abs(s.x-mob.x)<CELL and math.abs(s.y-mob.y)<CELL then
				-- if attacked then damaged
				if s.attack then mob.Damaged(s.power) end
			end
		end
	end
	
	function s.Display(time)
		if s.curAnim==nil then return end
		s.curAnim.Update(time)
		-- assure that the player is always in the camera bounds
		spr(s.curAnim.frame,s.x%(CAM_W-CELL),s.y%(CAM_H-CELL),s.alpha,1,s.flip)
		-- rectb(s.x+s.dx*3+(CELL-2)/2,s.y+s.dy*3+(CELL-2)/2,2,2,14)
	end
	
	function CheckDoors(dx,dy)
		-- open door if have the key
		tl,tr,bl,br=Collision:GetEdges(s.x+dx,s.y+dy)
		if tl==tiles.CLOSED_DOOR and s.keys>0 then
			s.keys=s.keys-1
			mset((s.x+dx)/CELL,(s.y+dy)/CELL,tiles.OPENED_DOOR)
		elseif tr==tiles.CLOSED_DOOR and s.keys>0 then
			s.keys=s.keys-1
			mset((s.x+dx+CELL-1)/CELL,(s.y+dy)/CELL,tiles.OPENED_DOOR)
		elseif bl==tiles.CLOSED_DOOR and s.keys>0 then
			s.keys=s.keys-1
			mset((s.x+dx)/CELL,(s.y+dy+CELL-1)/CELL,tiles.OPENED_DOOR)
		elseif br==tiles.CLOSED_DOOR and s.keys>0 then
			s.keys=s.keys-1
			mset((s.x+dx+CELL-1)/CELL,(s.y+dy+CELL-1)/CELL,tiles.OPENED_DOOR)
		end
	end
	
	function CheckCoffers(dx,dy)
		-- collect the potions in the coffers
		tl,tr,bl,br=Collision:GetEdges(s.x+dx,s.y+dy)
		local probability=70
		
		if tl==tiles.CLOSED_COFFER then
			mset((s.x+dx)/CELL,(s.y+dy)/CELL,tiles.OPENED_COFFER)
			if math.random(100)<probability then s.potions=s.potions+1 end			
		elseif tr==tiles.CLOSED_COFFER then
			mset((s.x+dx+CELL-1)/CELL,(s.y+dy)/CELL,tiles.OPENED_COFFER)
			if math.random(100)<probability then s.potions=s.potions+1 end			
		elseif bl==tiles.CLOSED_COFFER then
			mset((s.x+dx)/CELL,(s.y+dy+CELL-1)/CELL,tiles.OPENED_COFFER)
			if math.random(100)<probability then s.potions=s.potions+1 end
		elseif br==tiles.CLOSED_COFFER then
			mset((s.x+dx+CELL-1)/CELL,(s.y+dy+CELL-1)/CELL,tiles.OPENED_COFFER)
			if math.random(100)<probability then s.potions=s.potions+1 end
		end
		-- limit the amount of potions
		if s.potions>5 then s.potions=5 end
	end
	
	function CheckKeys(dx,dy)
		-- collect the keys
		tl,tr,bl,br=Collision:GetEdges(s.x+dx,s.y+dy)
		if tl==tiles.KEY_FLOOR then
			s.keys=s.keys+1
			mset((s.x+dx)/CELL,(s.y+dy)/CELL,tiles.KEY_FLOOR_PICKED_UP)			
		elseif tr==tiles.KEY_FLOOR then
			s.keys=s.keys+1
			mset((s.x+dx+CELL-1)/CELL,(s.y+dy)/CELL,tiles.KEY_FLOOR_PICKED_UP)
		elseif bl==tiles.KEY_FLOOR then
			s.keys=s.keys+1
			mset((s.x+dx)/CELL,(s.y+dy+CELL-1)/CELL,tiles.KEY_FLOOR_PICKED_UP)
		elseif br==tiles.KEY_FLOOR then
			s.keys=s.keys+1
			mset((s.x+dx+CELL-1)/CELL,(s.y+dy+CELL-1)/CELL,tiles.KEY_FLOOR_PICKED_UP)
		end
	end
	
	return s
end

------------------------------------------
-- HUD
local function DisplayHUD(player)
	-- format the score
	if player.points<=9 then print("score:"..player.points,CAM_W-43,0) end
	if player.points>9 and player.points<=99 then print("score:"..player.points,CAM_W-49,0) end
	if player.points>99 then print("score:"..player.points,CAM_W-55,0) end
	-- draw the player stats and equipment
	for i=0,player.health do spr(tiles.HEART,CAM_W-CELL*i,CELL,player.alpha) 	end
	for i=0,player.potions do spr(tiles.POTION,CAM_W-CELL*i,2*CELL,player.alpha) end
	for i=0,player.keys do spr(tiles.KEY,CAM_W-CELL*i,3*CELL,player.alpha) end
end

local function DisplayMessages(player,boss)
	-- if player is dead show message
	if player.died and not boss.died then
		spr(154,CAM_W/2-CELL*2,CAM_H/2-CELL*2,8,2)
		spr(155,CAM_W/2,CAM_H/2-CELL*2,8,2)
		spr(170,CAM_W/2-CELL*2,CAM_H/2,8,2)
		spr(171,CAM_W/2,CAM_H/2,8,2)
		print("YOU DIED",CAM_W/2-22,CAM_H/2+18)
		print("PRESS X TO RESTART",CAM_W/2-54,CAM_H/2+26)
	end
	
	-- if boss is dead show message
	if boss.died then
		spr(152,CAM_W/2-CELL*2,CAM_H/2-CELL*2,8,2)
		spr(153,CAM_W/2,CAM_H/2-CELL*2,8,2)
		spr(168,CAM_W/2-CELL*2,CAM_H/2,8,2)
		spr(169,CAM_W/2,CAM_H/2,8,2)
		print("YOU WIN",CAM_W/2-20,CAM_H/2+18)
		print("PRESS X TO RESTART",CAM_W/2-54,CAM_H/2+26)
	end
end

------------------------------------------
-- spawners
local function SpawnBlob(cellX,cellY,player)
	local m=Mob(cellX*CELL,cellY*CELL,player)
	m.tag="blob"
	m.anims={
		idle=Anim(20,{32,33,34}),
		walk=Anim(8,{34,35,36,37,38}),	
		attack=Anim(5,{39,40,41,32},false),
		die=Anim(5,{42,43,44},false),
		damaged=Anim(20,{45,32},false),
	}
	m.health=2
	m.score=1
	m.damageable=false
	return m
end

local function SpawnGoblin(cellX,cellY,player)
	local m=Mob(cellX*CELL,cellY*CELL,player)
	m.tag="goblin"
	m.score=2
	m.anims={
		idle=Anim(60,{48,49}),
		walk=Anim(15,{50,51}),	
		attack=Anim(15,{52,49},false),
		die=Anim(5,{53,54,55,56},false),
		damaged=Anim(20,{57,49},false),
	}
	return m
end

local function SpawnWraith(cellX,cellY,player)
	local m=MobCaster(cellX*CELL,cellY*CELL,player)
	m.tag="wraith"
	m.anims={
		idle=Anim(25,{80,81,82,81}),
		walk=Anim(15,{80,81,82,81}),	
		attack=Anim(20,{83,80},false),
		die=Anim(5,{90,91,92,93},false),
		damaged=Anim(20,{94,95,80},false)
	}
	m.health=6
	m.score=4
	m.power=2
	m.damageable=false
	
	function m.CreateBullet(x,y,vx,vy)
		local b=Bullet(x,y,vx,vy)
		b.player=m.player
		b.power=m.power
		b.anims={
			move=Anim(5,{84,85,86}),
			collided=Anim(15,{87,88,89},false)
		}
		return b	
	end
	
	return m
end

local function SpawnGolem(cellX,cellY,player)
	local m=Mob(cellX*CELL,cellY*CELL,player)
	m.tag="golem"
	m.health=7
	m.score=6
	m.power=2
	m.fov=4*CELL
	m.anims={
		idle=Anim(60,{64,65}),
		walk=Anim(15,{66,67}),	
		attack=Anim(15,{68,69,70,64},false),
		die=Anim(20,{71,72,73,74},false),
		damaged=Anim(20,{75,64},false),
	}
	return m
end

local function SpawnKnight(cellX,cellY,player)
	local m=Mob(cellX*CELL,cellY*CELL,player)
	m.tag="knight"
	m.health=10
	m.power=1
	m.score=7
	m.fov=7*CELL
	m.anims={
		idle=Anim(50,{96,97}),
		walk=Anim(15,{98,99}),	
		attack=Anim(15,{100,97},false),
		die=Anim(5,{101,102,103,104,105},false),
		damaged=Anim(20,{106,97},false)
	}
	return m
end

------------------------------------------
-- init
local p1,boss,golem1,golem2

local function Init()
	-- detect if run for the fisrt time
	if not firstRun then return end
	firstRun=false
	
	-- clear tables
	mobs={}
	animTiles={}
	traps={}
	bullets={}
	
	-- create player
	p1=Player(8*CELL,6*CELL)

	-- create boss
	boss=Boss(124*CELL,24*CELL,p1)
	table.insert(mobs,boss)

	-- create monsters
	table.insert(mobs,SpawnBlob(16,23,p1))
	table.insert(mobs,SpawnBlob(17,24,p1))
	table.insert(mobs,SpawnBlob(18,26,p1))
	table.insert(mobs,SpawnBlob(7,25,p1))
	table.insert(mobs,SpawnBlob(6,28,p1))

	table.insert(mobs,SpawnGoblin(40,9,p1))
	table.insert(mobs,SpawnGoblin(38,4,p1))

	table.insert(mobs,SpawnGoblin(63,13,p1))
	table.insert(mobs,SpawnGoblin(67,12,p1))
	table.insert(mobs,SpawnBlob(76,7,p1))
	table.insert(mobs,SpawnBlob(75,8,p1))
	table.insert(mobs,SpawnBlob(79,9,p1))
	table.insert(mobs,SpawnBlob(82,7,p1))
	table.insert(mobs,SpawnBlob(77,11,p1))
	table.insert(mobs,SpawnBlob(87,14,p1))

	table.insert(mobs,SpawnBlob(82,26,p1))
	table.insert(mobs,SpawnBlob(77,24,p1))
	table.insert(mobs,SpawnBlob(68,26,p1))

	table.insert(mobs,SpawnGoblin(73,40,p1))
	table.insert(mobs,SpawnGoblin(81,46,p1))

	table.insert(mobs,SpawnWraith(34,41,p1))

	table.insert(mobs,SpawnGoblin(37,55,p1))

	table.insert(mobs,SpawnBlob(15,56,p1))
	table.insert(mobs,SpawnBlob(11,61,p1))
	table.insert(mobs,SpawnBlob(14,63,p1))
	table.insert(mobs,SpawnBlob(14,63,p1))
	table.insert(mobs,SpawnBlob(17,57,p1))

	table.insert(mobs,SpawnWraith(56,73,p1))
	table.insert(mobs,SpawnWraith(48,81,p1))

	table.insert(mobs,SpawnGoblin(69,96,p1))
	table.insert(mobs,SpawnGoblin(74,100,p1))
	table.insert(mobs,SpawnGoblin(72,103,p1))

	table.insert(mobs,SpawnGolem(76,108,p1))

	table.insert(mobs,SpawnBlob(97,101,p1))
	table.insert(mobs,SpawnBlob(102,103,p1))
	table.insert(mobs,SpawnGoblin(93,107,p1))

	-- golems chamber
	golem1=SpawnGolem(119,103,p1)
	table.insert(mobs,golem1)
	golem2=SpawnGolem(119,108,p1)
	table.insert(mobs,golem2)

	table.insert(mobs,SpawnBlob(95,86,p1))
	table.insert(mobs,SpawnBlob(96,90,p1))

	table.insert(mobs,SpawnKnight(102,69,p1))

	table.insert(mobs,SpawnKnight(131,60,p1))
	table.insert(mobs,SpawnKnight(131,65,p1))

	table.insert(mobs,SpawnWraith(121,42,p1))
	
	-- just for curiosity
	local maxScore=0
	for i,mob in pairs(mobs) do 
		maxScore=maxScore+mob.score
	end
	-- trace("maxScore:"..maxScore)
	
	-- cycle the map and manage the special elements
	for y=0,MAP_W/CELL do
		for x=0,MAP_H/CELL do	
			-- animated tiles
			if mget(x,y)==tiles.LAVA_1 or mget(x,y)==tiles.LAVA_2 or mget(x,y)==tiles.LAVA_3 then
				local tile=AnimTile(x,y,Anim(30,{tiles.LAVA_1,tiles.LAVA_2,tiles.LAVA_3}))
				tile.anim.RandomIndx()
				table.insert(animTiles,tile)
			end
			if mget(x,y)==tiles.MAGIC_FLUID_1 or mget(x,y)==tiles.MAGIC_FLUID_2 or mget(x,y)==tiles.MAGIC_FLUID_3 then
				local tile=AnimTile(x,y,Anim(30,{tiles.MAGIC_FLUID_1,tiles.MAGIC_FLUID_2,tiles.MAGIC_FLUID_3}))
				tile.anim.RandomIndx()
				table.insert(animTiles,tile)
			end
			if mget(x,y)==tiles.VINE_1 or mget(x,y)==tiles.VINE_2 or mget(x,y)==tiles.VINE_3 then
				local tile=AnimTile(x,y,Anim(20,{tiles.VINE_1,tiles.VINE_2,tiles.VINE_3}))
				tile.anim.RandomIndx()
				table.insert(animTiles,tile)
			end
			-- traps
			if mget(x,y)==tiles.SPIKES_HARMLESS or mget(x,y)==tiles.SPIKES_HARM then
				local trap=Trap(x,y,tiles.SPIKES_HARMLESS,tiles.SPIKES_HARM)
				trap.timeDanger=math.random(40,80)
				trap.timeSafe=math.random(40,80)
				table.insert(traps,trap)
			end
			if mget(x,y)==tiles.MIMIC_HARMLESS or mget(x,y)==tiles.MIMIC_HARM then
				local trap=Trap(x,y,tiles.MIMIC_HARMLESS,tiles.MIMIC_HARM)
				trap.timeDanger=math.random(40,60)
				trap.timeSafe=math.random(40,120)
				table.insert(traps,trap)
			end
			if mget(x,y)==tiles.FOOTBOARD_UP or mget(x,y)==tiles.FOOTBOARD_DOWN then
				local trap=Trap(x,y,tiles.FOOTBOARD_UP,tiles.FOOTBOARD_DOWN)
				trap.timeDanger=math.random(40,60)
				trap.timeSafe=math.random(210,240)
				table.insert(traps,trap)
			end
			-- reset doors
			if mget(x,y)==tiles.OPENED_DOOR then mset(x,y,tiles.CLOSED_DOOR) end
			-- reset coffers
			if mget(x,y)==tiles.OPENED_COFFER then mset(x,y,tiles.CLOSED_COFFER) end
			-- reset keys
			if mget(x,y)==tiles.KEY_FLOOR_PICKED_UP then mset(x,y,tiles.KEY_FLOOR) end
			-- reset golems chamber
			mset(110,105,tiles.CRYSTAL_BROKEN)
			-- reset boss grate
			mset(124,32,tiles.OPENED_GRATE)
		end
	end
end

local function SpecialEvents()
	-- when enter in the golems chamber close the entrance
	-- until both golems are died
	if p1.x>=111*CELL-1 and p1.x<=112*CELL+1 and p1.y>=104*CELL-1 and p1.y<=105*CELL+1 then
		mset(110,105,tiles.CRYSTAL_WHOLE)
	end
	
	if golem1.died and golem2.died then
		mset(110,105,tiles.CRYSTAL_BROKEN)
	end
	
	-- when player reach the boss close the grate
	if p1.x>=124*CELL-1 and p1.x<=125*CELL+1 and p1.y>=30*CELL-1 and p1.y<=31*CELL+1 then
		mset(124,32,tiles.CLOSED_GRATE)
	end
end

------------------------------------------				
-- main
function TIC()
	-- runs only the first time or to reset the game
	Init()
	-- reset the game if the player is died and is pressed x
	if btn(5) and p1.died then firstRun=true end
	if btn(5) and boss.died then firstRun=true end
	
	-- set the camera and draw the background
	cam.x=p1.x-p1.x%(CAM_W-CELL)
	cam.y=p1.y-p1.y%(CAM_H-CELL)
	-- cls(3)
	map(cam.x/CELL,cam.y/CELL,CAM_W/CELL,CAM_H/CELL)
		
	------------- UPDATE -------------
	SpecialEvents()
	
	-- mobs
	for i,mob in pairs(mobs) do mob.Update(t) end
	-- player
	p1.Update(t)
	-- bullets
	for i,v in pairs(bullets) do
		if bullets[i].died then table.remove(bullets,i)
		else bullets[i].Update(t) end
	end
	-- traps
	for i,trap in pairs(traps) do trap.Update(t) end
	
	------------- DISPLAY -------------
	-- animated tiles
	for i,tile in pairs(animTiles) do tile.Display(t) end	
	-- mobs
	for i,mob in pairs(mobs) do mob.Display(t) end
	-- player
	p1.Display(t)
	-- bullets
	for i,bullet in pairs(bullets) do bullet.Display(t) end
	-- traps
	for i,trap in pairs(traps) do trap.Display(t) end

	-- HUD
	DisplayHUD(p1)
	DisplayMessages(p1,boss)

	-- increment global time
	t=t+1
end