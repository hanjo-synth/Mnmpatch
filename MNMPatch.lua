-- Monomachine Randomizer v1.1
-- 
-- HANJO, Tokyo, Japan.
-- K3: Randomize CC values on the current page.
-- E1: Change page.
-- E2: Select CC slot.
-- K2 + E3: Change Mode.
-- E3: Adjust CC, value, MIDI channel.
-- Scroll to CC -1 : OFF Feature
-- 

local midi_out
local channel = 1

local num_slots_per_page = 8
local num_pages = 7
local current_page = 1

local page_data = {
  { title = "SYNTH", cc_targets = {48, 49, 50, 51, 52, 53, 54, 55}, cc_values = {0, 0, 0, 0, 0, 0, 0, 0} },
  { title = "AMP",   cc_targets = {56, 57, 58, 59, 60, 61, 62, 63}, cc_values = {0, 0, 0, 0, 0, 0, 0, 0} },
  { title = "FILTER", cc_targets = {72, 73, 74, 75, 76, 77, 78, 79}, cc_values = {0, 0, 0, 0, 0, 0, 0, 0} },
  { title = "EFFECTS",cc_targets = {80, 81, 82, 83, 84, 85, 86, 87}, cc_values = {0, 0, 0, 0, 0, 0, 0, 0} },
  { title = "LFO 1",  cc_targets = {88, 89, 90, 91, 92, 93, 94, 95}, cc_values = {0, 0, 0, 0, 0, 0, 0, 0} },
  { title = "LFO 2",  cc_targets = {104, 105, 106, 107, 108, 109, 110, 111}, cc_values = {0, 0, 0, 0, 0, 0, 0, 0} },
  { title = "LFO 3",  cc_targets = {112, 113, 114, 115, 116, 117, 118, 119}, cc_values = {0, 0, 0, 0, 0, 0, 0, 0} }
}

local selected_slot = 1
local edit_mode = "cc"

function init()
  midi_out = midi.connect(1)

  params:add_separator("CC Randomizer Settings")
  params:add_number("midi_channel", "MIDI Channel", 1, 16, 1)
  params:set_action("midi_channel", function(val) channel = val end)
  params:add_number("cc_val_min", "Value Min", 0, 127, 0)
  params:add_number("cc_val_max", "Value Max", 0, 127, 127)

  clock.run(redraw_loop)
end

function get_current_page_data()
  return page_data[current_page]
end

function send_dice_roll()
  local current_data = get_current_page_data()
  local val_min = params:get("cc_val_min")
  local val_max = params:get("cc_val_max")
  local ch = params:get("midi_channel")

  for i = 1, num_slots_per_page do
    local cc = current_data.cc_targets[i]
    if cc >= 0 then
      local val = math.random(val_min, val_max)
      current_data.cc_values[i] = val
      midi_out:cc(cc, val, ch)
      print("🎲 Page " .. current_page .. " Slot " .. i .. " → CC " .. cc .. " = " .. val)
    end
  end
end

function key(n, z)
  if n == 3 and z == 1 then
    send_dice_roll()
  elseif n == 2 and z == 1 then
    if edit_mode == "cc" then
      edit_mode = "value"
    elseif edit_mode == "value" then
      edit_mode = "midi"
    else
      edit_mode = "cc"
    end
  end
end

function enc(n, d)
  local current_data = get_current_page_data()
  if n == 1 then
    current_page = util.clamp(current_page + d, 1, num_pages)
    selected_slot = 1
  elseif n == 2 then
    selected_slot = util.clamp(selected_slot + d, 1, num_slots_per_page)
  elseif n == 3 then
    if edit_mode == "cc" then
      local new_cc = util.clamp(current_data.cc_targets[selected_slot] + d, -1, 127)
      current_data.cc_targets[selected_slot] = new_cc
    elseif edit_mode == "value" then
      local new_val = util.clamp(current_data.cc_values[selected_slot] + d, 0, 127)
      current_data.cc_values[selected_slot] = new_val
      local cc = current_data.cc_targets[selected_slot]
      if cc >= 0 then
        midi_out:cc(cc, new_val, params:get("midi_channel"))
      end
    elseif edit_mode == "midi" then
      local new_channel = util.clamp(params:get("midi_channel") + d, 1, 16)
      params:set("midi_channel", new_channel)
    end
  end
end

function redraw()
  screen.clear()
  screen.font_size(8)

  local current_data = get_current_page_data()
  local title = current_data.title
  local title_x = (128 - (#title * 8)) / 2 + 6
  screen.move(title_x, 5)
  screen.text(title)

  for i = 1, 4 do
    draw_slot(i, current_data, 2, 15 + (i - 1) * 10)
  end
  for i = 5, 8 do
    draw_slot(i, current_data, 68, 15 + (i - 5) * 10)
  end

  screen.move(96, 60)
  screen.text("K3: Roll")
  screen.move(54, 60)
  screen.text(string.format("E1:%02d", current_page))
  screen.move(4, 60)
  if edit_mode == "cc" then
    screen.text("CC")
  elseif edit_mode == "value" then
    screen.text("VAL")
  elseif edit_mode == "midi" then
    screen.text(string.format("MIDI %02d", params:get("midi_channel")))
  end

  screen.update()
end

function draw_slot(i, data, x, y)
  local marker = (selected_slot == i) and ">" or " "
  local cc = data.cc_targets[i]
  local cc_str = (cc == -1) and "OFF " or string.format("CC%3d", cc)
  screen.move(x, y)
  screen.text(string.format("%s%d: %s→%3d", marker, i, cc_str, data.cc_values[i]))
end

function redraw_loop()
  while true do
    redraw()
    clock.sleep(1 / 15)
  end
end
