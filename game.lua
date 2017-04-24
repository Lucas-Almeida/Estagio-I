-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Your code here

local composer = require( "composer" )
 
local scene = composer.newScene()

local physics = require("physics")
physics.start()
--physics.setDrawMode( "hybrid" )

-- initialize variables

local arrows = 10
local arrowsText
local towerHp = 3
local died = false

local score = 0
local scoreText 
local gameLoopTimer
local livesText

local backGroup 
local mainGroup 
local uiGroup 

local arrow
local archer
local forceArea
local radiusMin, radiusMax

local arrowsFired = 0 -- total arrows fired
local arrowsHit = 0

local soundTable = {
    arrowSound = audio.loadSound("arrowHit01.wav"),
    youDiedSound = audio.loadSound("you-died-sound.mp3")
}

local gameBackgroundMusic = audio.loadStream("warped.mp3")
local gameBackgroundMusicChannel = audio.play(gameBackgroundMusic, { channel=20, loops=-1, fadein=5000 })
audio.setVolume(0.25)

local function updateText()
    livesText.text = "Lives: " .. towerHp
    scoreText.text = "Score: " .. score
    arrowsText.text = "Arrow: " .. arrows
end

local function endGame()
    composer.setVariable("totalArrowsFired", arrowsFired )
	composer.gotoScene( "highscores", { time=8000, effect="crossFade" } )
end

local function touch(event)
    if event.phase == 'began' then
        display.getCurrentStage():setFocus(archer, event.id)
        archer.isFocused = true
    elseif archer.isFocused then
        if event.phase == 'moved' then
            local touchArea = display.newCircle(archer.x, archer.y, radiusMax)
            touchArea.isVisible = false
            touchArea.isHitTestable = true
            touchArea:addEventListener('touch', archer)
            local x, y = archer.parent:contentToLocal(event.x, event.y)
            x, y = x - archer.x, y - archer.y
            local rotation = math.atan2(y, x) * 180 / math.pi + 180
            local radius = math.sqrt(x ^ 2 + y ^ 2)
            setForce(radius, rotation)   
            touchArea:removeSelf()   
        else
            display.getCurrentStage():setFocus(archer, nil)
            archer.isFocused = false
            engageForce() 
            forceArea:scale(0, 0)            
        end
    end

    return true
end

function setForce(radius, rotation)
    archer.rotation = rotation % 360 
    if radius > radiusMin then
        if radius > radiusMax then
            radius = radiusMax 
        end
        archer.force = radius 
    else
        archer.force = 0
    end
    
    forceArea.isVisible = true
    forceArea.xScale = 2 * radius / forceArea.width
    forceArea.yScale = forceArea.xScale
    
    return math.min(radius, radiusMax), archer.rotation
end

function engageForce()
    --forceArea.isVisible = false
    archer.forceRadius = 0
    if archer.force > 0 and arrows > 0 then
       fire()
    end
end

-- arrow functions

function launch(dir, force)
    if (arrows > 0) then
        local arrow = display.newImageRect("arrow.png", 20, 20)
        arrow.x, arrow.y = archer.x, archer.y + -14
        arrow.rotation = 90
        physics.addBody(arrow, "static", {isSensor = true, density = 2, friction = 0.5, bounce = 0.5, radius = arrow.width / 2})
        arrow.myName = "arrow"
        arrow.isBullet = true
        arrow.angularDamping = 3 -- Prevent the arrow from rolling for too long (necessary?)
        dir = math.rad(dir) -- direction angle in radians
        arrow.bodyType = "dynamic"
        arrow:applyLinearImpulse((force - 40) * math.cos(dir), (force - 40) * math.sin(dir), arrow.x, arrow.y) 
        arrow.isLaunched = true
        arrows = arrows - 1
        arrowsText.text = "Arrows: " .. arrows
    end

    if (arrows == 0) then
        timer.performWithDelay(1000, endGame)
    end
end

function fire()
    if arrow and not arrow.isLaunched then        
        launch(archer.rotation, archer.force)
        audio.play(soundTable["arrowSound"])
        arrowsFired = arrowsFired + 1
    end
end

local spawnTimer
local spawnedEnemy = {}

function createEnemy()
    local newEnemy = display.newImageRect(mainGroup, "idle001.png", 20, 55)
    table.insert(spawnedEnemy, newEnemy)
    physics.addBody(newEnemy, "dynamic", {filter=enemyCollisionFilter})
    newEnemy.myName = "orc"
    newEnemy.x = display.contentCenterX + 280
    newEnemy.y = display.contentCenterY + 120
    newEnemy:scale(-3, 1.25)
    newEnemy:setLinearVelocity(10, 0)
    transition.to(newEnemy, {x = -15, time = 17500})
end

function gameLoop()
    createEnemy() 
end

function onCollision(event)
    if(event.phase == "began") then
        local obj1 = event.object1
        local obj2 = event.object2 

        if((obj1.myName == "floor" and obj2.myName == "orc") or (obj1.myName == "orc" and obj2.myName == "floor")) then
        
        elseif(obj1.myName == "orc" and obj2.myName == "tower") then
            display.remove(obj1)
            towerHp = towerHp - 1
            livesText.text = towerHp - 1
        elseif(obj1.myName == "tower" and obj2.myName == "orc") then
            display.remove(obj2)
            towerHp = towerHp - 1
            livesText.text = "Lives: " .. towerHp
        elseif((obj1.myName == "orc" and obj2.myName == "arrow") or (obj1.myName == "arrow" and obj2.myName == "orc"))  then
            display.remove(obj1)
            display.remove(obj2)
            score = score + 100
            arrows = arrows + 3
            arrowsHit = arrowsHit + 1
            arrowsText.text = "Arrows: " .. arrows
            livesText.text = "Lives: " .. towerHp
            scoreText.text = "Score: " .. score
        end

        if (towerHp == 0) then
            timer.performWithDelay(2000, endGame)
        end

        for i = #spawnedEnemy, 1, -1 do
            if (spawnedEnemy[i] == obj1 or spawnedEnemy[i] == obj2 ) then
                table.remove(spawnedEnemy, i)
                break
            end
        end       
    end
end

-- Composer

-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
 
    physics.pause()

    -- Set up display groups
    backGroup = display.newGroup()  -- Display group for the background image
    sceneGroup:insert( backGroup )  -- Insert into the scene's view group
 
    mainGroup = display.newGroup()  -- Display group for the ship, asteroids, lasers, etc.
    sceneGroup:insert( mainGroup )  -- Insert into the scene's view group
 
    uiGroup = display.newGroup()    -- Display group for UI objects like the score
    sceneGroup:insert( uiGroup )    -- Insert into the scene's view group

    local background = display.newImageRect(backGroup, "forest.png", 570, 350)
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    local tower = display.newImageRect(mainGroup, "tower.png", 50, 100)
    tower.x = display.contentCenterX - 200
    tower.y = display.contentCenterY + 90
    tower.myName = "tower"
    tower:scale(3, 2)
    physics.addBody(tower, "static")

    local floor = display.newImageRect(backGroup, "grass.png", 1200, 20)
    floor.x = display.contentCenterX - 300
    floor.y = display.contentCenterY + 150
    physics.addBody(floor, "static")
    floor.myName = "floor"
    floor:toBack()

    archer = display.newImageRect(mainGroup, "archer_elf.png", 60, 60)
    archer.x = display.contentCenterX - 190
    archer.y = display.contentCenterY + 20
    -- Archer force is set by a player by moving the finger away from the archer
    archer.force = 0
    archer.forceRadius = 0

    arrow = display.newImageRect(mainGroup, "arrow.png", 20, 20)
    arrow.x, arrow.y = archer.x, archer.y + -14
    arrow.rotation = 90
    physics.addBody(arrow, "static", {isSensor = true, density = 2, friction = 0.5, bounce = 0.5, radius = arrow.width / 2, filter=arrowCollisionFilter})
    arrow.isBullet = true
    arrow:toBack()

    -- Minimum and maximum radius of the force circle indicator
    radiusMin, radiusMax = 32, 48
    -- Indicates force value
    forceArea = display.newCircle(archer.x, archer.y, radiusMax)
    forceArea.strokeWidth = 4
    forceArea:setFillColor(1, 0.5, 0.2, 0.2)
    forceArea:setStrokeColor(1, 0.5, 0.2)
    forceArea.isVisible = false

    -- Display lives and score
    livesText = display.newText( uiGroup, "Lives: " .. towerHp, 0, 10, native.systemFont, 24)
    scoreText = display.newText( uiGroup, "Score: " .. score, display.contentCenterX, 10, native.systemFont, 24)
    arrowsText = display.newText( uiGroup, "Arrows: " .. arrows, 450, 10, native.systemFont, 24)

    archer:addEventListener("touch", touch)
end 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)

    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        physics.start()
        Runtime:addEventListener("collision", onCollision)
        gameLoopTimer = timer.performWithDelay(1500, gameLoop, 0) 
    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        audio.stop()
        local death = display.newImageRect(sceneGroup, "you-died.png", 600, 80)
        death.x = display.contentCenterX 
        death.y = display.contentCenterY 
        audio.play(soundTable["youDiedSound"])
        timer.cancel(gameLoopTimer)
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        Runtime:removeEventListener("collision", onCollision)
        physics.pause()
        composer.removeScene("game")
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