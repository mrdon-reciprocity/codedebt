INFINITY = 5e+20  -- good enough for our needs
TOP = 0
BOTTOM = 50  -- TODO: adjust!
LEFT = 0
RIGHT = 250  -- TODO: ajdust! MAX_X


function reverse_array(arr)
	local i, j = 1, #arr
	while i < j do
		arr[i], arr[j] = arr[j], arr[i]
		i = i + 1
		j = j - 1
	end
end


function reconstruct_path(came_from, node)
    --[[
    Reconstruct the path that lead to `node` and return it
    as an table in REVERSED order

    Args:
        node: a point {x=5, y=7}
        came_from:
         {
             [{x=5, y=7}] = {x=2, y=4},
             [{x=1, y=5}] = {x=2, y=2},
             ...
         }
    --]]

    local total_path = {node}
    local current = node  -- TOOD: needed? or can we safely use "node" directly?

    while true do
        current = cameFrom[current]
        if current == nil then
            break  -- no predecessor, stop looping
        else
            table.insert(total_path, current)  -- append
        end
    end

    reverse_array(total_path)
    return total_path
end


function euclid_distance(p1, p2)
    -- return the Euclidian distance between two points
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    return math.sqrt(dx * dx + dx * dy)
end


function node_min_f_score(f_scores, nodes)
    -- Return the node with the lowest f_score
    --
    -- Args:
    --    f_scores: a map (node --> f_score), e.g. { [{x=7, y=5}] = 8}
    --    nodes: a set of nodes to consider, e.g. { [{x=7, y=5}] = true }

    local result_node = nil
    local min_f_score = INFINITY  -- pretend this is "infinity"
    local current = nil

    for current_node in pairs(nodes) do
        local f_score = f_scores[current_node]

        -- Nodes not present in f_scores are assumed to have an f score of Infinity
        if f_score == nil then
            f_score = INFINITY
        end

        if f_score < min_f_score then
            min_f_score = f_score
            result_node = current_node
        end
    end

    return result_node
end


function walkable_neighbors(tile)
    -- Find and return all walkable (non-wall) neighbors of a given tile
    --
    -- Args:
    --    tile: a table, e.g. {x=5, y=7}
    --
    local neighbor = nil
    negihbors = {}

    -- upper neighbor
    if tile.y > TOP then
        neighbor {x = tile.x , y = tile.y -1}
        neighbors[neighbor] = true  -- TODO: if not WALL
    end

    -- lower neighbor
    if tile.y < BOTTOM then
        neighbor = {x = tile.x , y = tile.y + 1}
        neighbors[neighbor] = true  -- TODO: if not WALL
    end

    -- left neightbor
    if tile.x > LEFT then
        neighbor = {x = tile.x - 1 , y = tile.y}
        neighbors[neighbor] = true  -- TODO: if not WALL
    end

    -- right neighbor
    if tile.x < RIGHT then
        neighbor = {x = tile.x + 1 , y = tile.y}
        neighbors[neighbor] = true  -- TODO: if not WALL
    end

    return neighbors
end


function suggested_path(start, goal)
    -- Return the shortest path from start to goal as a list of tiles
    -- to follow.
    -- Assumption: both the start and the goal are non-wall tiles, i.e.
    --- "walkable"
    --
    -- Both args are table with x,y coordinates, example: {x=5, y=7}
    
    -- SET: use elements as _keys_ and check for existence
    -- reserved = {
        --     ["while"] = true,     ["end"] = true,
        --     ["function"] = true,  ["local"] = true,
        --   }
            
        
    -- // The set of nodes already evaluated
    local closed_set = {}

    -- // The set of currently discovered nodes that are not evaluated yet.
    -- // Initially, only the start node is known.
    local open_set = {[start] = true}

    -- // For each node, which node it can most efficiently be reached from.
    -- // If a node can be reached from many nodes, cameFrom will eventually contain the
    -- // most efficient previous step.
    local came_from = {}

    -- // For each node, the cost of getting from the start node to that node.
    local g_scores = {} -- non-existing nodes are treated as being infinitely away

    -- // The cost of going from start to start is zero.
    g_scores[start] = 0

    -- // For each node, the total cost of getting from the start node to the goal
    -- // by passing by that node. That value is partly known, partly heuristic.
    local f_scores = {}  -- NOTE: non-existing nodes are treated as being infinitely away

    -- // For the first node, that value is completely heuristic.
    f_scores[start] = euclid_distance(start, goal)

    while (#open_set > 0) do  --while not empty
        --  find the node in openSet having the lowest fScore[] value
        current = node_min_f_score(f_scores, open_set)  -- TODO: use priority queue!
        if current == goal then
            return reconstruct_path(came_from, current)
        end

        open_set[current] = nil  -- remove from open set
        closed_set[current] = true  -- add to closed set

        local neighbors = walkable_neighbors(current) -- TODO: implemnt
        for neighbor in pairs(neighbors) do
            if closed_set[neighbor] == nil then
                -- Only consider the neighbor if it is not already evaluated.
                
                if g_scores[neighbor] == nil then
                    g_scores[neighbor] = INFINITY
                end

                --  // The distance from start to a neighbor
                tentative_g_score = g_scores[current] + euclid_distance(current, neighbor)
                
                local neighbor_not_in_open = (open_set[neighbor] == nil)

                if neighbor_not_in_open then
                    open_set[neighbor] = true  -- // Discover a new node
                end

                -- if a new node was discovered or its path is shorter than the
                -- currently shortest known path, record the new best path
                if neighbor_not_in_open or tentative_g_score < g_scores[neighbor] then
                    -- // This path is the best until now. Record it!
                    came_from[neighbor] = current
                    g_scores[neighbor] = tentative_g_score
                    f_scores[neighbor] = g_scores[neighbor] + euclid_distance(neighbor, goal)
                end
            end
        end
    end
end
