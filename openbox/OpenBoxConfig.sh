#!/bin/bash

# Set the location of the Openbox rc.xml configuration file
rc_file="/etc/xdg/openbox/rc.xml"

# Use awk to identify sections of code with the ShowMenu tag and comment them out
awk '/<ShowMenu>/,/<\/ShowMenu>/ { print "<!--" $0 " -->"; next } 1' "$rc_file" > "$rc_file.temp" && mv "$rc_file.temp" "$rc_file"

# Set the keybinding and command
keybinding="A-S-F2"
command="mate-terminal"

# Define the new keybinding element
new_keybind="<keybind key=\"$keybinding\" name=\"Open_Mate_Term\">
  <action name=\"Execute\">
    <command>$command</command>
  </action>
</keybind>"

# Insert the new keybinding element into the rc.xml file
sed -i "/<\/keyboard>/i $new_keybind" /etc/xdg/openbox/rc.xml

# Add Tint2 to openbox autostart
sed -i '/tint2 &/!s/^/tint2 \&\n/' ~/.config/openbox/autostart
