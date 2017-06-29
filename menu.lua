
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local function gotoGame()
    audio.stop()
	composer.gotoScene( "game", { time=800, effect="crossFade" } )
end

--[[
local function gotoHighScores()
	audio.stop()
	composer.gotoScene( "highscores", { time=800, effect="crossFade" } )
end
]]
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view

	-- Code here runs when the scene is first created but has not yet appeared on screen

    local background = display.newImageRect(sceneGroup, "background-snow.jpg", 580, 400)
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    local title = display.newImageRect(sceneGroup, "LOGO.png", 500, 200)
    title.x = display.contentCenterX
    title.y = display.contentCenterY - 100

    local playButton = display.newImageRect(sceneGroup, "play-button.png", 80, 60)
    playButton.x = display.contentCenterX
    playButton.y = display.contentCenterY + 50

	--[[

    local highScoresButton = display.newImageRect(sceneGroup, "highscores.png", 75, 75)
    highScoresButton.x = display.contentCenterX 
    highScoresButton.y = display.contentCenterY + 100
	
	]]

    local backgroundMusic = audio.loadStream("waking-the-devil.mp3")
    audio.play(backgroundMusic, { channel=1, loops=-1, fadein=5000 })

    playButton:addEventListener("tap", gotoGame)
    --highScoresButton:addEventListener("tap", gotoHighScores)

end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)
	elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
		composer.removeScene("menu")		
	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
