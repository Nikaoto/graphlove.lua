local graphlove = {
   _VERSION = "graphlove.lua 0.0.1",
   _URL     = "http://github.com/Nikaoto/graphlove.lua",
   _DESCRIPTION = "small and simple curve graphing library for Love2D",
   _LICENSE = [[
      Copyright 2022 Nikoloz Otiashvili

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions are
      met:

      1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

      2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

      3. Neither the name of the copyright holder nor the names of its
      contributors may be used to endorse or promote products derived from this
      software without specific prior written permission.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
      IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
      THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
      CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
      EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
      LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
      NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
      SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
   ]]
}

local gl = graphlove
local lg = love.graphics
local abs = math.abs
local pow = math.pow
local sqrt = math.sqrt
local floor = math.floor

-- Draw the crossings (unit markers) on the axes
local function draw_vert_crossing(x, y, length, girth)
   local h = length
   local w = girth

   lg.rectangle("fill", x-w/2, y-h/2, w, h)
end
local function draw_horiz_crossing(x, y, length, girth)
   local w = length
   local h = girth

   lg.rectangle("fill", x-w/2, y-h/2, w, h)
end

-- Returns new graph table.
function gl.new(opts)
   local graph = {
      print_info = opts.print_info or false,
      plane_ox = opts.plane_ox or 0,
      plane_oy = opts.plane_oy or 0,
      x_off = opts.x_off or 205,
      y_off = opts.y_off or 350,
      y_scale = opts.y_scale or 40,
      x_scale = opts.x_scale or 40,
      crossing_girth = opts.crossing_girth or 1,
      crossing_length = opts.crossing_length or 10,
      x_axis_color = opts.x_axis_color or {1, 0, 0, 1},
      y_axis_color = opts.y_axis_color or {0, 0, 1, 1},
      crossing_color = opts.crossing_color or {1, 0, 1, 0.9},
      alt_crossing_color = opts.alt_crossing_color or {1, 0.27, 0, 0.9},
      scale_color_change_threshold = opts.scale_color_change_threshold or 1,
      magnified_scale_mult = opts.magnified_scale_mult or 100,
      curves = opts.curves,
      x = opts.x or 0,
      y = opts.y or 0,
      width = opts.width or 800,
      height = opts.height or 600,
   }

   return graph
end

-- Remap all points according to the scale and offset. Should be called after
-- any changes have been made to the curves passed to the graph.
function gl.update(graph)
   local g = graph
   for _, curve in ipairs(g.curves) do
      curve.raw_points = {}
      for i=1, #curve.points, 2 do
         local x = g.x + g.x_off +
                   curve.points[i] * g.x_scale
         local y = g.y + g.y_off -
                   curve.points[i+1] * g.y_scale

         -- Do AABB on point and graph window
         if x >= g.x and x <= (g.x + g.width) and
            y >= g.y and y <= (g.y + g.height) then
            table.insert(curve.raw_points, x)
            table.insert(curve.raw_points, y)
         end
      end
   end
end

function gl.draw(graph)
   local g = graph
 
   -- Draw y axis if visible
   if (g.x_off >= 0 and g.x_off <= g.width) then
      lg.setColor(g.y_axis_color)
      lg.line(
         g.x + g.x_off, g.y,
         g.x + g.x_off, g.y + g.height)

      -- Draw horiz crossing lines (unit markers) on y axis
      local step
      if g.y_scale < g.scale_color_change_threshold then
         lg.setColor(g.alt_crossing_color)
         step = g.y_scale * g.magnified_scale_mult
      else
         lg.setColor(g.crossing_color)
         step = g.y_scale
      end
      if step >= 1 then
         local bot = g.y + g.height
         local origin_y = g.y + g.y_off
         local outside = origin_y - bot
         local first_line_y_from_bot = step - (outside % step)
         local y_start = g.y + g.height - first_line_y_from_bot
         for y=y_start, g.y, -step do
            draw_horiz_crossing(
               g.x + g.x_off,
               floor(y),
               g.crossing_length,
               g.crossing_girth)
         end
      end
   end

   -- Draw x axis line if visible
   if (g.y_off >= 0 and g.y_off <= g.height) then
      lg.setColor(g.x_axis_color)
      lg.line(
         g.x,           g.y + g.y_off,
         g.x + g.width, g.y + g.y_off)

      -- Draw vertical crossing lines (unit markers) on x axis
      local step
      if g.x_scale < g.scale_color_change_threshold then
         lg.setColor(g.alt_crossing_color)
         step = g.x_scale * g.magnified_scale_mult
      else
         lg.setColor(g.crossing_color)
         step = g.x_scale
      end
      if step >= 1 then
         local first_line_x_from_left = step - (-g.x_off % step)
         local x_start = g.x + first_line_x_from_left
         for x=x_start, g.x + g.width, step do
            draw_vert_crossing(
               floor(x),
               g.y + g.y_off,
               g.crossing_length,
               g.crossing_girth)
         end
      end
   end

   -- Draw all curves
   for _, curve in ipairs(g.curves) do
      lg.setColor(curve.color or {1, 1, 1, 1})

      -- Draw circles if point radius given
      if curve.radius and curve.radius > 1 then
         for i=1, #curve.raw_points, 2 do
            lg.circle(
               "fill",
               curve.raw_points[i],
               curve.raw_points[i+1],
               curve.radius)
         end
      else  -- Draw points otherwise
         lg.points(curve.raw_points)
      end
   end

   -- Print stats
   if g.print_info then
      lg.setColor(1, 1, 1, 1)
      local str = string.format(
         "x_scale = %.4f\ny_scale = %.4f\nx_off = %i\ny_off = %i",
         g.x_scale, g.y_scale, g.x_off, g.y_off)
      lg.print(str, g.x, g.y)
   end
end

-- Handles scaling slowdown/speedup after threshold.
-- Both functions are only called from do_easy_controls()
local function get_scale_delta(scale, dt, sign)
   local dscale = 40
   local small_dscale = 0.3
   if math.abs(scale) < 1 then
      return sign * dt * small_dscale
   else
      return sign * dt * dscale
   end
end
local function get_offset_delta(off, dt, sign)
   local doff = 300
   return sign * dt * doff
end

-- Keys used for moving/scaling the graph interactively
local default_keys = {
   scale_y_down = "k",
   scale_y_up   = "j",
   scale_x_down = "h",
   scale_x_up   = "l",
   move_left    = "left",
   move_right   = "right",
   move_up      = "up",
   move_down    = "down",
}

-- Make the graph interactive.
-- Drop this in love.update() for easy integration.
function gl.do_easy_controls(graph, dt, keys)
   if not keys then keys = {} end
   setmetatable(keys, {__index = default_keys})

   local recalc_points = false

   local scale_dx, scale_dy = 0, 0
   local off_dx, off_dy = 0, 0

   -- Scale y
   if love.keyboard.isDown(keys.scale_y_up) then
      scale_dy = get_scale_delta(graph.y_scale, dt, 1)
   elseif love.keyboard.isDown(keys.scale_y_down) then
      scale_dy = get_scale_delta(graph.y_scale, dt, -1)
   end
   graph.y_scale = graph.y_scale + scale_dy

   -- Scale x
   if love.keyboard.isDown(keys.scale_x_up) then
      scale_dx = get_scale_delta(graph.x_scale, dt, 1)
   elseif love.keyboard.isDown(keys.scale_x_down) then
      scale_dx = get_scale_delta(graph.x_scale, dt, -1)
   end
   graph.x_scale = graph.x_scale + scale_dx

   -- Move x_off
   if love.keyboard.isDown(keys.move_left) then
      off_dx = get_offset_delta(graph.x_off, dt, 1)
   elseif love.keyboard.isDown(keys.move_right) then
      off_dx = get_offset_delta(graph.x_off, dt, -1)
   end
   graph.x_off = graph.x_off + off_dx

   -- Move y_off
   if love.keyboard.isDown(keys.move_up) then
      off_dy = get_offset_delta(graph.y_off, dt, 1)
   elseif love.keyboard.isDown(keys.move_down) then
      off_dy = get_offset_delta(graph.y_off, dt, -1)
   end
   graph.y_off = graph.y_off + off_dy

   recalc_points = recalc_points or
                   off_dx ~= 0 or off_dy ~= 0 or
                   scale_dx ~= 0 or scale_dy ~= 0

   if recalc_points then
      graphlove.update(graph)
   end
end

return graphlove
