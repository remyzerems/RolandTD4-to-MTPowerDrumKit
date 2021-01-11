ardour {
	["type"]    = "dsp",
	name        = "Roland TD4 to MTPowerDrumKit",
	category    = "Utility",
	license     = "MIT",
	author      = "Ardour Lua Task Force",
	description = [[A plugin that allows using a Roland TD4 drum kit with the MT Power Drum Kit plugin.
It uses MIDI CC messages to determine the required MIDI note to play instead.
	
Default plugin settings are based on Roland TD4 and MT Power Drum Kit default values.
Pedal thresholds define the following ranges :
	- [0, open threshold] => Open Hihat range
	- ]open threshold, closed threshold] => Half Closed Hihat range
	- ]closed threshold, 127] => Closed Hihat range]]
}

-- Here are all default values for the plugin

ROLAND_TD4_DEFAULT_HIHAT_NOTE = 26
ROLAND_TD4_HIHAT_PEDAL_CC_ID = 4

DEFAULT_HIHAT_OPEN_THRESHOLD = 0
DEFAULT_HIHAT_CLOSED_THRESHOLD = 120

MT_DEFAULT_HIHAT_CLOSED_NOTE = 42
MT_DEFAULT_HIHAT_HALF_CLOSED_NOTE = 83
MT_DEFAULT_HIHAT_OPEN_NOTE = 46

-- This is to store the current hihat note. The value is based on the last CC message we had.
local cur_hihat_note = HIHAT_OPEN_NOTE;

-- Parameter index enumeration
P_ROLAND_H_NOTE = 1
P_H_OPEN = 4
P_H_H_CLOSED = 5
P_H_CLOSED = 6
P_H_OPEN_THRESH = 2
P_H_CLOSED_THRESH = 3



function dsp_ioconfig ()
	return { { midi_in = 1, midi_out = 1, audio_in = 0, audio_out = 0}, }
end


function dsp_params ()

    local map_scalepoints = {}
    for note=0,127 do
        local name = ARDOUR.ParameterDescriptor.midi_note_name(note)
        map_scalepoints[string.format("%03d (%s)", note, name)] = note
    end

    local map_params = {}

    map_params[P_ROLAND_H_NOTE] = {
        ["type"] = "input",
        name = "Roland TD4 Hihat note",
        min = 0,
        max = 127,
        default = ROLAND_TD4_DEFAULT_HIHAT_NOTE,
        integer = true,
        enum = true,
        scalepoints = map_scalepoints
    }
    
    map_params[P_H_OPEN] = {
        ["type"] = "input",
        name = "MT Power Drum kit open Hihat note",
        min = 0,
        max = 127,
        default = MT_DEFAULT_HIHAT_OPEN_NOTE,
        integer = true,
        enum = true,
        scalepoints = map_scalepoints
    }
    
    map_params[P_H_H_CLOSED] = {
        ["type"] = "input",
        name = "MT Power Drum kit half closed Hihat note",
        min = 0,
        max = 127,
        default = MT_DEFAULT_HIHAT_HALF_CLOSED_NOTE,
        integer = true,
        enum = true,
        scalepoints = map_scalepoints
    }
    
    map_params[P_H_CLOSED] = {
        ["type"] = "input",
        name = "MT Power Drum kit closed Hihat note",
        min = 0,
        max = 127,
        default = MT_DEFAULT_HIHAT_CLOSED_NOTE,
        integer = true,
        enum = true,
        scalepoints = map_scalepoints
    }

    map_params[P_H_OPEN_THRESH] = {
        ["type"] = "input",
        name = "Roland TD4 Hihat pedal open threshold",
        min = 0,
        max = 127,
        default = DEFAULT_HIHAT_OPEN_THRESHOLD,
        integer = true,
    }
    
    map_params[P_H_CLOSED_THRESH] = {
        ["type"] = "input",
        name = "Roland TD4 Hihat pedal closed threshold",
        min = 0,
        max = 127,
        default = DEFAULT_HIHAT_CLOSED_THRESHOLD,
        integer = true,
    }
    
    return map_params
end

function dsp_run (_, _, n_samples)
	assert (type(midiin) == "table")
	assert (type(midiout) == "table")
	local cnt = 1;

	function tx_midi (time, data)
		midiout[cnt] = {}
		midiout[cnt]["time"] = time;
		midiout[cnt]["data"] = data;
		cnt = cnt + 1;
	end

    local ctrl = CtrlPorts:array()

	-- for each incoming midi event
	for _,b in pairs (midiin) do
		local t = b["time"] -- t = [ 1 .. n_samples ]
		local d = b["data"] -- get midi-event
		local event_type
		if #d == 0 then event_type = -1 else event_type = d[1] >> 4 end


        local roland_hihat = ctrl[P_ROLAND_H_NOTE]
		if (#d == 3 and event_type == 9) then -- note on
		    if (d[2] == ctrl[P_ROLAND_H_NOTE]) then
		        d[2] = cur_hihat_note
		    end
			tx_midi (t, d)
		elseif (#d == 3 and event_type == 8) then -- note off
		    if (d[2] == ctrl[P_ROLAND_H_NOTE]) then
		        d[2] = cur_hihat_note
		    end
			tx_midi (t, d)
		end
		
		if (#d == 3 and (d[1] & 240) == 176) then -- CC
			-- if (d[2] == 120 or d[2] == 123) then -- panic
			--	
			-- end
			
			-- If the CC message is about the Roland TD4 hihat pedal
			if (d[2] == ROLAND_TD4_HIHAT_PEDAL_CC_ID) then
			    -- Look at the value representing the pedal "angle" and check them against the defined thresholds
			    if (d[3] <= ctrl[P_H_OPEN_THRESH]) then
			        cur_hihat_note = ctrl[P_H_OPEN] -- Hihat note is now Hihat Open
			    elseif (d[3] > ctrl[P_H_OPEN_THRESH] and d[3] <= ctrl[P_H_CLOSED_THRESH]) then
			        cur_hihat_note = ctrl[P_H_H_CLOSED] -- Hihat note is now Hihat Half Closed
			    else
			        cur_hihat_note = ctrl[P_H_CLOSED] -- Otherwise Hihat note is Hihat Closed
			    end
			end
		end
	end
end
