

function init()
	t=0
end


function draw_point(x, y, color_index)
	width=8
	height=8
--	color_index=9 -- color codes, 9 is orange 
	rect(x,y,width,height,color_index)
	music(0, 0, -1, false)
end

cls()

--draw_point(0, 0, 9)
--draw_point(230, 130, 9)
--music(0, 0, 0)


--row = 0
function TIC()
--	music(0, 0, row, false)
--	row= row + 1
	if btn(3) then
		x = math.random(0, 230)
		y = math.random(0, 130)
		draw_point(x, y, 9)
	end
end
