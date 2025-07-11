#!/usr/bin/env osascript

tell application "System Events" to set wasRunning to exists process "iTerm2"

-- restore “qp” layout
tell application "iTerm2" to activate
delay 0.2
tell application "System Events"
	tell process "iTerm2"
		click menu bar item "Window" of menu bar 1
		click menu item "Restore Window Arrangement" of menu 1 of menu bar item "Window" of menu bar 1
		click menu item "qp" of menu 1 of menu item "Restore Window Arrangement" of menu 1 of menu bar item "Window" of menu bar 1
	end tell
end tell

-- give it time to rebuild panes
delay 2.0

if not wasRunning then
	tell application "iTerm2" to close window 2
	delay 0.2
end if


-- send your commands into each pane
tell application "iTerm2"
	tell current window
		tell current tab
			tell session 5 to write text "./q.sh"
			delay 2.0
			tell session 1 to write text "cd ~/Documents/Github/quizpro/frontend && npm run dev"
			tell session 2 to write text "cd ~/Documents/Github/quizpro && ./work.sh"
			tell session 4 to write text "btop"
			delay 5.0
			tell session 3 to write text "cd qp/frontend && ~/bin/b.sh"
		end tell
	end tell
end tell
