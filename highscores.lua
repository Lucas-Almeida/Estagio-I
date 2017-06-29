local composer = require( "composer" )
 
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
 local function gotoMenu()
    --audio.stop()
	composer.gotoScene( "menu", { time=800, effect="crossFade" } )
end

 local json = require("json")

 local scoresTable = {}

 local filePath = system.pathForFile("scores.json", system.DocumentsDirectory)
 
 local function loadScores()
    local file = io.open(filePath, "r")

    if file then
        local contents = file:read("*a")
        io.close(file)
        scoresTable = json.decode(contents)
    end

    if (scoresTable == nil or #scoresTable == 0) then
        scoresTable = { 10000, 7500, 5200, 4700, 3500, 3200, 1200, 1100, 800, 500 }
    end
 end

 local function saveScores()
    for i = #scoresTable, 11, -1 do 
        table.remove(scoresTable, i)
    end

    local file = io.open(filePath, "w")

    if file then
        file:write(json.encode(scoresTable))
        io.close(file)
    end

 end
 
 
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

    --[[
    local title = display.newImageRect(sceneGroup, "highscores-menu.png", 500, 80)
    title.x = display.contentCenterX
    title.y = display.contentCenterY - 100
    ]]

    local menuButton = display.newImageRect(sceneGroup, "menu-button.png", 100, 75)
    menuButton.x = display.contentCenterX + 200
    menuButton.y = display.contentCenterY

    menuButton:addEventListener("tap", gotoMenu)    
end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        snowballsFiredText = display.newText("Snowballs fired: " ..  composer.getVariable("totalSnowballsFired"), 50, 260, "Snowinter.ttf", 18)
        snowballsHitText = display.newText("Snowballs Hit: " ..  composer.getVariable("totalSnowballsHit"), 50, 220, "Snowinter.ttf", 18)
        pigeonsKilledText = display.newText("Pigeons Killed: " ..  composer.getVariable("totalPigeonsKilled"), 50, 180, "Snowinter.ttf", 18)
        snowmenKilledText = display.newText("Snowmen Killed: " ..  composer.getVariable("totalSnowmenKilled"), 50, 140, "Snowinter.ttf", 18)
        collateralKillsText = display.newText("Collateral Kills: " ..  composer.getVariable("totalCollateralDamage"), 50, 100, "Snowinter.ttf", 18) 
        scoresText = display.newText("Total Score: " ..  composer.getVariable("totalScore"), 50, 60, "Snowinter.ttf", 18) 

        snowballsFiredText:setFillColor(0, 0.5, 1)
        snowballsHitText:setFillColor(0, 0.5, 1)
        pigeonsKilledText:setFillColor(0, 0.5, 1)
        snowmenKilledText:setFillColor(0, 0.5, 1)
        collateralKillsText:setFillColor(0, 0.5, 1)
        scoresText:setFillColor(0, 0.5, 1)

        sceneGroup:insert(snowballsFiredText)
        sceneGroup:insert(snowballsHitText)
        sceneGroup:insert(pigeonsKilledText)
        sceneGroup:insert(snowmenKilledText)
        sceneGroup:insert(collateralKillsText) 
        sceneGroup:insert(scoresText) 
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
        sceneGroup:remove(snowballsFiredText)
        sceneGroup:remove(snowballsHitText)
        sceneGroup:remove(pigeonsKilledText)
        sceneGroup:remove(snowmenKilledText)
        sceneGroup:remove(collateralKillsText) 
        sceneGroup:remove(scoresText) 
        composer.removeScene("game")
        
    end
end
 
 
-- destroy()
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
    --composer.remove(arrowsFiredText)
    
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