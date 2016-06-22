
function hook_UnitWakeUp(u, f)
	game.initHero(u)
end

function hook_CopySaveGame(str, void, f)
	cmd.start(str)
end

timer.loop(30, true, function()
	hook.UnitWakeUp = hook_UnitWakeUp
	hook.CopySaveGame = hook_CopySaveGame
end)
