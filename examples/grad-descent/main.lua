-- Graph a function and find its local minimum using a simple
-- naive dy/dx calculation.
local graphlove = require("graphlove")
local WIN_WIDTH, WIN_HEIGHT = 800, 600
local graph

-- The function we want to do gradient descent on
local f = math.sin
local px = 1.7 -- X coordinate of the point on the graph
local p = {px, f(px)} -- The X,Y of the point

-- Gradient descent step size
local step = 3

-- Function that is tangent to the graph at point {px, f(px)}
local tangent_line_curve
local tangent_line_slope = 1
local tf = function(x) return tangent_line_slope*x end

-- Generates points to be graphed
function gen_points(from, to, int, fn)
   local pts = {}
   for x=from, to, int do
      table.insert(pts, x)
      table.insert(pts, fn(x))
   end
   return pts
end

function calc_tangent_points()
   -- Calc f'(px)
   local x1 = px
   local x2 = px + 0.001
   local y1 = f(x1)
   local y2 = f(x2)
   local slope = (y2-y1)/(x2-x1)
   tangent_line_slope = slope

   -- Solve for k in "slope*x + k = f(px)" where "x == px"
   local k = f(px) - slope*px

   -- Update tangent line function and the points
   tf = function (x) return slope*x + k end
   tangent_line_curve.points = gen_points(-20, 20, 0.001, tf)
   tangent_point_curve.points = {px, f(px)}
end

function love.conf(t)
   t.console = true
end

function love.load()
   math.randomseed(os.time())
   love.window.setMode(WIN_WIDTH, WIN_HEIGHT)

   -- A single point on the graph. 
   tangent_point_curve = {
      color = {0, 1, 0, 1},
      radius = 4,
      points = nil
   }

   -- Tangent line of the graph (f) at the point 
   tangent_line_curve = {
      color = {0.9, 0.9, 0.1, 0.9},
      points = nil
   }

   -- This will set the points for the two curves defined above
   calc_tangent_points()

   -- Create a new graph
   graph = graphlove.new({
         print_info = true,
         width = WIN_WIDTH,
         height = WIN_HEIGHT,
         x_scale = 34,
         x_off = 350,
         y_off = 350,
         curves = {
            {
               color = {1, 1, 1, 0.9},
               points = gen_points(-20, 20, 0.001, f)
            },
            tangent_line_curve,
            -- This is placed after the tangent
            -- line so that graphlove will paint over it - the point won't be
            -- behind the line.
            tangent_point_curve
         }
   })

   graphlove.update(graph)
end

function love.draw()
   graphlove.draw(graph)
end

local r_down = false
function love.update(dt)
   -- When the "r" key is released
   if love.keyboard.isDown("r") then
      r_down = true
   else
      if r_down  then
         r_down = false

         -- Pick another random point
         px = -10 + 20*math.random()
   
         -- Update tangent line
         calc_tangent_points()
   
         -- Update graph
         graphlove.update(graph)
      end
   end

   if love.keyboard.isDown("space") then
      -- Decent by one step
      if tangent_line_slope ~= 0 then
         px = px - tangent_line_slope*step*dt
      end

      -- Update tangent line
      calc_tangent_points()

      -- Update graph
      graphlove.update(graph)
   end

   graphlove.do_easy_controls(graph, dt)
end
