# RolandTD4 to MTPowerDrumKit plugin
This is an Ardour LUA plugin that allows playing the MTPowerDrumKit plugin with a Roland TD4 drum kit

# Usage
- Copy paste the plugin (.lua file) to the Ardour LUA script. Check [Ardour Manual](https://manual.ardour.org/lua-scripting) for details.
- Restart Ardour (or manually refresh plugins)
- Add a new MIDI track with MTPowerDrumKit as the instrument
- Add the LUA plugin to the MIDI drum track as the first plugin (Utility category)
- Plug in your Roland TD4, set it as the MIDI input of the track
- Enjoy !

**Note 1** : there is no specific configuration to do if you left the default settings on your Roland and in MTPowerDrumkit. Otherwise, you'll have to match the settings in the plugin parameters.
**Note 2** : if you are used to the Roland TD4 settings, you may also like to check the [Midi Curve plugin](https://github.com/remyzerems/MIDI-Velocity-Curve) for a better feeling of your strokes... 

