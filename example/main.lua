local graphlove = require("graphlove")
local WIN_WIDTH, WIN_HEIGHT = 800, 600
local graph

-- Generates points to be graphed
function gen_points(from, to, int, fn)
   local pts = {}
   for x=from, to, int do
      table.insert(pts, x)
      table.insert(pts, fn(x))
   end
   return pts
end

function love.conf(t)
   t.console = true
end

function love.load()
   love.window.setMode(WIN_WIDTH, WIN_HEIGHT)

   -- Create a new graph
   graph = graphlove.new({
         print_info = false,
         width = WIN_WIDTH,
         height = WIN_HEIGHT,
         x_off = 350,
         y_off = 350,
         curves = {
            {
               color = {1, 1, 1, 0.9},
               points = gen_points(-20, 20, 0.0005, function(x)
                  return 1/x
               end)
            },
            {
               color = {0.3, 0.9, 0.8, 0.9},
               radius = 2,
               points = gen_points(-20, 20, 0.03, function(x)
                  return 1/x + -1 + 2 * math.random()
               end)
            }
         }
   })

   -- Update the graph. Doing this is necessary if we wish to use the graph,
   -- because update() maps the cartesian coordinates to screen space
   graphlove.update(graph)
end

function love.draw()
   graphlove.draw(graph)
end

function love.update(dt)
   graphlove.do_easy_controls(graph, dt)
end

