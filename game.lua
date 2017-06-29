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

local snowballs 
local snowballsText
local towerHp = 4
local died = false

local score = 0
local scoreText 
local gameLoopTimer

local backGroup 
local mainGroup 
local uiGroup 

local snowball
local pigeonsKilled = 0 
local snowmenKilled = 0
local collaterals = 0
local forceArea
local radiusMin, radiusMax

local snowballsFired = 0 -- total snowballs fired
local snowballsHit = 0

local soundTable = {
    snowballSound = audio.loadSound("snowball_hit.mp3"),
    --youDiedSound = audio.loadSound("you-died-sound.mp3"),
    explosionSound = audio.loadSound("explosion.mp3")
}

local gameBackgroundMusic = audio.loadStream("warped.mp3")
local gameBackgroundMusicChannel = audio.play(gameBackgroundMusic, { channel=3, loops=-1, fadein=5000 })
audio.setVolume(0.1, {channel = 3})

local function updateText()
    scoreText.text = "Score: " .. score
end

local function endGame()
    spawnControllerTop( "pause", spawnParamsTop )    
    spawnControllerBottom( "pause", spawnParamsBottom )   
    spawnControllerSnowflake("pause", spawnParamsSnowflake) 

    composer.setVariable("totalScore", score )
    composer.setVariable("totalSnowballsFired", snowballsFired )
    composer.setVariable("totalSnowballsHit", snowballsHit )
    composer.setVariable("totalPigeonsKilled", pigeonsKilled)
    composer.setVariable("totalSnowmenKilled", snowmenKilled )
    composer.setVariable("totalCollateralDamage", collaterals )    
	composer.gotoScene( "highscores", { time=10000, effect="crossFade" } )
end

local function touch(event)
    if event.phase == 'began' then  
        
        player.currentPlayer = 2
        player:setFrame(player.currentPlayer)   
        display.getCurrentStage():setFocus(player, event.id)       
        player.isFocused = true

        elseif player.isFocused then
            if event.phase == 'moved' then
                local touchArea = display.newCircle(player.x, player.y, radiusMax)
                touchArea.isVisible = true
                touchArea.isHitTestable = true
                touchArea:addEventListener('touch', player)
                local x, y = player.parent:contentToLocal(event.x, event.y)
                x, y = x - player.x, y - player.y
                local rotation = math.atan2(y, x) * 180 / math.pi + 180
                local radius = math.sqrt(x ^ 2 + y ^ 2)
                setForce(radius, rotation)   
                touchArea:removeSelf()   
            else
                display.getCurrentStage():setFocus(player, nil)
                player.isFocused = false
                player.currentPlayer = 1
                player:setFrame(player.currentPlayer) 
                engageForce() 
                forceArea:scale(0, 0)      
                player.force = 0
                radius = 0      
            end
        elseif (event.phase == "ended") then

            system.getTimer()
        end

    return true
end

function setForce(radius, rotation)
    player.rotation = rotation % 360 
    if radius > radiusMin then
        if radius > radiusMax then
            radius = radiusMax 
        end
        player.force = radius 
    else
        player.force = 0
        radius = 0
    end
    
    forceArea.isVisible = true
    if (radius > 0) then 
        forceArea.xScale = 2 * radius / forceArea.width        
    else 
        forceArea.xScale = 0.1
    end

    forceArea.yScale = forceArea.xScale
    
    return math.min(radius, radiusMax), player.rotation
end

function engageForce()
    forceArea.isVisible = true
    player.forceRadius = 0
    if player.force > 0 then 
       fire()
    end
end

-- snowball functions

function launch(dir, force)
    local snowball = display.newImageRect("snowball.png", 20, 20)
    snowball.x, snowball.y = player.x, player.y + -14
    snowball.rotation = 90
    physics.addBody(snowball, "static", {isSensor = true, density = 3, friction = 0.5, bounce = 0.5, radius = snowball.width / 2})
    snowball.myName = "snowball"
    snowball.isBullet = true
    snowball.angularDamping = 3 -- Prevent the snowball from rolling for too long
    dir = math.rad(dir) -- direction angle in radians
    snowball.bodyType = "dynamic"
    snowball:applyLinearImpulse((force - 35) * math.cos(dir), (force - 35) * math.sin(dir), snowball.x, snowball.y) 
    snowball.isLaunched = true
end

function fire()
    if snowball and not snowball.isLaunched then        
        launch(player.rotation, player.force)        
        snowballsFired = snowballsFired + 1
    end
end

local spawnTimerTop
spawnedObjectsTop = {}
local spawnParamsTop = {
    xMin = display.contentCenterX + 350,
    xMax = display.contentCenterX + 500,
    yMin = display.contentCenterY - 100,
    yMax = display.contentCenterY + 20,
    spawnTime = 1200,
    spawnOnTimer = 1,
    spawnInitial = 0
}

local spawnTimerBottom
spawnedObjectsBottom = {}
local spawnParamsBottom = {
    xMin = display.contentCenterX + 200,
    xMax = display.contentCenterX + 550,
    yMin = display.contentCenterY + 110,
    yMax = display.contentCenterY + 110,
    spawnTime = 800,
    spawnOnTimer = 3,
    spawnInitial = 0
}

local spawnTimerSnowflake
local spawnedSnowflakes = {}
local spawnParamsSnowflake = {
    xMin = display.contentCenterX - 250,
    xMax = display.contentCenterX + 250,
    yMin = display.contentCenterY - 200,
    yMax = display.contentCenterY - 200,
    spawnTime = 100,
    spawnOnTimer = 10,
    spawnInitial = 0
}

function createBottomEnemy(bounds)
    local newEnemy = display.newSprite(bottomSheet, bottomSequenceData)
    physics.addBody(newEnemy, "dynamic", {filter=bottomEnemyCollisionFilter})
    newEnemy:setSequence("run")
    newEnemy.currentEnemy = 1
    newEnemy:setFrame(newEnemy.currentEnemy)
    newEnemy.myName = "bottom"
    newEnemy.x = math.random(bounds.xMin, bounds.xMax)
    newEnemy.y = math.random(bounds.yMin, bounds.yMax)
    newEnemy:setLinearVelocity(-85, 0)
    newEnemy:play()    
    spawnedObjectsBottom[#spawnedObjectsBottom+1] = newEnemy    
end

local collided = false

function createTopEnemy(bounds)
    local newEnemy = display.newSprite(topSheet, topSequenceData)
    physics.addBody(newEnemy, "dynamic", {filter=topEnemyCollisionFilter})
    newEnemy:setSequence("fly")
    newEnemy.currentEnemy = 1
    newEnemy:setFrame(newEnemy.currentEnemy)
    newEnemy.myName = "top"
    newEnemy.gravityScale = 0
    newEnemy.x = math.random(bounds.xMin, bounds.xMax)
    newEnemy.y = math.random(bounds.yMin, bounds.yMax)
    newEnemy:play()
    newEnemy:setLinearVelocity(-60, 0)
    spawnedObjectsTop[#spawnedObjectsTop+1] = newEnemy
end

local function createSnowflake(bounds)
    local newSnowflake = display.newImageRect(backGroup, "snowflake.png", 15, 15)
    physics.addBody(newSnowflake, "dynamic")
    newSnowflake.isSensor = true
    newSnowflake.alpha = 0.5
    newSnowflake.gravityScale = 0.01
    newSnowflake.x = math.random(bounds.xMin, bounds.xMax)
    newSnowflake.y = math.random(bounds.yMin, bounds.yMax)
    spawnedSnowflakes[#spawnedSnowflakes+1] = newSnowflake    
end

-- Spawn controller Snowflake
function spawnControllerSnowflake( action, params )

	-- cancel timer on "start" or "stop", if it exists
	if ( spawnTimerSnowflake and ( action == "start" or action == "stop" ) ) then
		timer.cancel( spawnTimerSnowflake )
	end

	-- Start spawning
	if ( action == "start" ) then

		-- gather/set spawning bounds
		local spawnBounds = {}
		spawnBounds.xMin = params.xMin or 0
		spawnBounds.xMax = params.xMax or display.contentWidth
		spawnBounds.yMin = params.yMin or 0
		spawnBounds.yMax = params.yMax or display.contentHeight
		-- gather/set other spawning params
		local spawnTime = params.spawnTime or 1000
		local spawnOnTimer = params.spawnOnTimer or 50
		local spawnInitial = params.spawnInitial or 0

		-- if spawnInitial > 0, spawn n item(s) instantly
		if ( spawnInitial > 0 ) then
			for n = 1,spawnInitial do
				createSnowflake( spawnBounds )
			end
		end

		-- start repeating timer to spawn items
		if ( spawnOnTimer > 0 ) then
			spawnTimerSnowflake= timer.performWithDelay( spawnTime,
				function() createSnowflake( spawnBounds ); end,
			spawnOnTimer )
		end
	
	-- Pause spawning
	elseif ( action == "pause" ) then
		timer.pause( spawnTimerSnowflake )

	-- Resume spawning
	elseif ( action == "resume" ) then
		timer.resume( spawnTimerSnowflake )

	end
end

-- Spawn controller Top
function spawnControllerTop( action, params )

	-- cancel timer on "start" or "stop", if it exists
	if ( spawnTimerTop and ( action == "start" or action == "stop" ) ) then
		timer.cancel( spawnTimerTop )
	end

	-- Start spawning
	if ( action == "start" ) then

		-- gather/set spawning bounds
		local spawnBounds = {}
		spawnBounds.xMin = params.xMin or 0
		spawnBounds.xMax = params.xMax or display.contentWidth
		spawnBounds.yMin = params.yMin or 0
		spawnBounds.yMax = params.yMax or display.contentHeight
		-- gather/set other spawning params
		local spawnTime = params.spawnTime or 1000
		local spawnOnTimer = params.spawnOnTimer or 50
		local spawnInitial = params.spawnInitial or 0

		-- if spawnInitial > 0, spawn n item(s) instantly
		if ( spawnInitial > 0 ) then
			for n = 1,spawnInitial do
				createTopEnemy( spawnBounds )
			end
		end

		-- start repeating timer to spawn items
		if ( spawnOnTimer > 0 ) then
			spawnTimerTop= timer.performWithDelay( spawnTime,
				function() createTopEnemy( spawnBounds ); end,
			spawnOnTimer )
		end
	
	-- Pause spawning
	elseif ( action == "pause" ) then
		timer.pause( spawnTimerTop )

	-- Resume spawning
	elseif ( action == "resume" ) then
		timer.resume( spawnTimerTop )

	end
end

-- Spawn controller Bottom
function spawnControllerBottom( action, params )

	-- cancel timer on "start" or "stop", if it exists
	if ( spawnTimerBottom and ( action == "start" or action == "stop" ) ) then
		timer.cancel( spawnTimerBottom )
	end

	-- Start spawning
	if ( action == "start" ) then

		-- gather/set spawning bounds
		local spawnBounds = {}
		spawnBounds.xMin = params.xMin or 0
		spawnBounds.xMax = params.xMax or display.contentWidth
		spawnBounds.yMin = params.yMin or 0
		spawnBounds.yMax = params.yMax or display.contentHeight
		-- gather/set other spawning params
		local spawnTime = params.spawnTime or 1000
		local spawnOnTimer = params.spawnOnTimer or 50
		local spawnInitial = params.spawnInitial or 0

		-- if spawnInitial > 0, spawn n item(s) instantly
		if ( spawnInitial > 0 ) then
			for n = 1,spawnInitial do
				createBottomEnemy( spawnBounds )
			end
		end

		-- start repeating timer to spawn items
		if ( spawnOnTimer > 0 ) then
			spawnTimerBottom= timer.performWithDelay( spawnTime,
				function() createBottomEnemy( spawnBounds ); end,
			spawnOnTimer )
		end
	
	-- Pause spawning
	elseif ( action == "pause" ) then
		timer.pause( spawnTimerBottom )

	-- Resume spawning
	elseif ( action == "resume" ) then
		timer.resume( spawnTimerBottom )

	end
end

function gameLoop()
    print(tower.currentHealth) 
    spawnControllerTop( "start", spawnParamsTop )    
    spawnControllerBottom( "start", spawnParamsBottom )   
    spawnControllerSnowflake("start", spawnParamsSnowflake) 
    if (tower.currentHealth > 4) then
        timer.performWithDelay(1000, endGame)
        player:removeEventListener("touch", touch)
        --player.y = display.contentCenterY + 130
        --died = true
        transition.to( player, { time=1500, alpha=0, y=(display.contentCenterY + 130) } )
        physics.addBody(player, "dynamic")
        player.isSensor = true
        player.currentPlayer = 3
        player:setFrame(player.currentPlayer)
        spawnControllerBottom("stop")
        spawnControllerTop("stop")        
    end   
end

function removeBottom(params)
    return function()
        params:removeSelf()
    end
end

function removeTop(params)
    return function()        
        params:removeSelf()
    end
end

function onCollision(event)
    if(event.phase == "began") then
        local obj1 = event.object1
        local obj2 = event.object2         

        -- floor collision
        if((obj1.myName == "floor" and obj2.myName == "bottom") or (obj1.myName == "bottom" and obj2.myName == "floor")) then
        
        -- tower + enemies
        elseif (obj2.myName == "tower" and (obj1.myName == "bottom" or obj1.myName == "top")) then
            display.remove(obj1)
            towerHp = towerHp - 1
            if (towerHp < 0) then
                towerHp = 0
            end 

            tower.currentHealth = tower.currentHealth + 1
            if (tower.currentHealth <= 5) then
                tower:setFrame(tower.currentHealth)
            end 

        -- tower + top
        elseif (obj1.myName == "tower" and obj2.myName == "top") or (obj1.myName == "top" and obj2.myName == "tower") then
            if (obj1.myName == "top") then
                display.remove(obj1)                
            else
                display.remove(obj2)                
            end

            towerHp = towerHp - 1
            if (towerHp < 0) then
                towerHp = 0
            end 
            tower.currentHealth = tower.currentHealth + 1
            if (tower.currentHealth <= 5) then
                tower:setFrame(tower.currentHealth)
            end 

            for i = #spawnedObjectsTop, 1, -1 do
                if (spawnedObjectsTop[i] == obj1 or spawnedObjectsTop[i] == obj2 ) then
                    table.remove(spawnedObjectsTop, i)
                    break                    
                end
            end    

        elseif (obj1.myName == "tower" and (obj2.myName == "bottom" or obj2.myName == "top")) then            
            towerHp = towerHp - 1
            if (towerHp < 0) then
                towerHp = 0
            end 
            tower.currentHealth = tower.currentHealth + 1
            if (tower.currentHealth <= 5) then
                tower:setFrame(tower.currentHealth)
            end 

            -- tower + bottom
            if ((obj1.myName == "bottom" or obj2.myName == "bottom")) then
                for i = #spawnedObjectsBottom, 1, -1 do
                    if (spawnedObjectsBottom[i] == obj1 or spawnedObjectsBottom[i] == obj2 ) then
                        audio.play(soundTable["explosionSound"])    
                        spawnedObjectsBottom[i]:setSequence("boom")
                        spawnedObjectsBottom[i].currentEnemy = 2
                        spawnedObjectsBottom[i]:setFrame(spawnedObjectsBottom[i].currentyEnemy)                          
                        spawnedObjectsBottom[i]:play()
                        spawnedObjectsBottom[i]:setLinearVelocity(0, 0)                 
                        timer.performWithDelay(1000, removeBottom(spawnedObjectsBottom[i]))

                        --display.remove(spawnedObjectsBottom[i])
                        break
                    end
                end
            end
            
            for i = #spawnedObjectsBottom, 1, -1 do
                if (spawnedObjectsBottom[i] == obj1 or spawnedObjectsBottom[i] == obj2 ) then
                    table.remove(spawnedObjectsBottom, i)
                    break
                end
            end

        -- bottom + snowball
        elseif((obj1.myName == "bottom" and obj2.myName == "snowball")
                or (obj1.myName == "snowball" and obj2.myName == "bottom"))  then
            if (obj1.myName == "snowball") then
                display.remove(obj1)
            else
                display.remove(obj2)
            end

            audio.play(soundTable["explosionSound"])

            for i = #spawnedObjectsBottom, 1, -1 do
                if (spawnedObjectsBottom[i] == obj1 or spawnedObjectsBottom[i] == obj2 ) then  
                    --audio.play(soundTable["explosionSound"])   
                    spawnedObjectsBottom[i]:setSequence("boom")
                    spawnedObjectsBottom[i].currentEnemy = 2
                    spawnedObjectsBottom[i]:play()
                    spawnedObjectsBottom[i]:setLinearVelocity(0, 0)
                    timer.performWithDelay(1000, removeBottom(spawnedObjectsBottom[i]))
                    break
                end
            end

            score = score + 100
            snowballsHit = snowballsHit + 1
            snowmenKilled = snowmenKilled + 1
            scoreText.text = "Score: " .. score

            for i = #spawnedObjectsBottom, 1, -1 do
                if (spawnedObjectsBottom[i] == obj1 or spawnedObjectsBottom[i] == obj2 ) then
                    table.remove(spawnedObjectsBottom, i)
                break
            end
        end  

        -- bottom + top
        elseif((obj1.myName == "bottom" and obj2.myName == "top")
                or (obj1.myName == "top" and obj2.myName == "bottom"))  then            

            audio.play(soundTable["explosionSound"])

            for i = #spawnedObjectsBottom, 1, -1 do
                if (spawnedObjectsBottom[i] == obj1 or spawnedObjectsBottom[i] == obj2 ) then  
                    --audio.play(soundTable["explosionSound"])   
                    spawnedObjectsBottom[i]:setSequence("boom")
                    spawnedObjectsBottom[i].currentEnemy = 2
                    spawnedObjectsBottom[i]:play()
                    spawnedObjectsBottom[i]:setLinearVelocity(0, 0)
                    timer.performWithDelay(1000, removeBottom(spawnedObjectsBottom[i]))
                    break
                end
            end

            score = score + 300
            collaterals = collaterals + 1
            scoreText.text = "Score: " .. score

            for i = #spawnedObjectsBottom, 1, -1 do
                if (spawnedObjectsBottom[i] == obj1 or spawnedObjectsBottom[i] == obj2 ) then
                    table.remove(spawnedObjectsBottom, i)
                break
            end
        end  

        -- top + snowball
        else if ((obj1.myName == "top" and obj2.myName == "snowball")
                or (obj1.myName == "snowball" and obj2.myName == "top"))  then
                        
            for i = #spawnedObjectsTop, 1, -1 do
                if (spawnedObjectsTop[i] == obj1 or spawnedObjectsTop[i] == obj2 ) then
                    spawnedObjectsTop[i]:setSequence("death")
                    spawnedObjectsTop[i].currentEnemy = 2
                    spawnedObjectsTop[i]:setFrame(spawnedObjectsTop[i].currentEnemy)
                    spawnedObjectsTop[i]:play()
                    audio.play(soundTable["snowballSound"])
                    spawnedObjectsTop[i].gravityScale = 0.5
                    --spawnedObjectsTop[i].isSensor = true
                    spawnedObjectsTop[i]:setLinearVelocity(0, 0) 
                    
                    --timer.performWithDelay(2000, display.removeTop(spawnedObjectsTop[i]))   
                    timer.performWithDelay(2000, table.remove(spawnedObjectsTop[i]) )    
                    timer.performWithDelay(2000, removeTop(spawnedObjectsTop[i]) ) 
                                 
                    break
                end
            end
            
            if (obj1.myName == "snowball") then
                display.remove(obj1)
            else
                display.remove(obj2)
            end
           
            score = score + 75            
            snowballsHit = snowballsHit + 1
            pigeonsKilled = pigeonsKilled + 1
            scoreText.text = "Score: " .. score
            for i = #spawnedObjectsTop, 1, -1 do
                if (spawnedObjectsTop[i] == obj1 or spawnedObjectsTop[i] == obj2 ) then
                   table.remove(spawnedObjectsTop, i)
                   break
                end
            end
        end
        end

    end

    
end

local function fitImage( displayObject, fitWidth, fitHeight, enlarge )
    --
    -- first determine which edge is out of bounds
    --
    local scaleFactor = fitHeight / displayObject.height
    local newWidth = displayObject.width * scaleFactor
    if newWidth > fitWidth then
        scaleFactor = fitWidth / displayObject.width
    end
    if not enlarge and scaleFactor > 1 then
        return
    end
    displayObject:scale( scaleFactor, scaleFactor )
end

-- Composer

-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
 
    physics.pause()    

    
    floorCollisionFilter = {categoryBits = 1, maskBits = 30}
    topEnemyCollisionFilter = {categoryBits = 2, maskBits = 29}
    bottomEnemyCollisionFilter = {categoryBits = 4, maskBits = 27}
    snowballCollisionFilter = {categoryBits = 8, maskBits = 6}    
    towerCollisionFilter = {categoryBits = 16, maskBits = 7}    
    

    -- Set up display groups
    backGroup = display.newGroup()  -- Display group for the background image
    sceneGroup:insert( backGroup )  -- Insert into the scene's view group
 
    mainGroup = display.newGroup()  -- Display group for the ship, asteroids, lasers, etc.
    sceneGroup:insert( mainGroup )  -- Insert into the scene's view group
 
    uiGroup = display.newGroup()    -- Display group for UI objects like the score
    sceneGroup:insert( uiGroup )    -- Insert into the scene's view group

    local background = display.newImageRect(backGroup, "background-final.png", 570, 360)
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    local floor = display.newImageRect(backGroup, "grass.png", 1200, 20)
    floor.x = display.contentCenterX - 300
    floor.y = display.contentCenterY + 150
    physics.addBody(floor, "static", {filter=floorCollisionFilter})
    floor.myName = "floor"
    floor:toBack()

    playerSheetOptions = 
    {       
        width = 64,
        height = 64,
        numFrames = 3
    }

    playerSheet = graphics.newImageSheet("player.png", playerSheetOptions)

    playerSequenceData = 
    {
        name = "player",
        start = 1,
        count = 3,
    }

    player = display.newSprite(playerSheet, playerSequenceData)
    player:setSequence("player")
    player.currentPlayer = 1
    player:setFrame(player.currentPlayer)
    player.x = display.contentCenterX - 200
    player.y = display.contentCenterY - 40
    player.force = 0
    player.forceRadius = 0
    physics.addBody(player, "static")

    topSheetOptions = 
    {
        width = 22,
        height = 20,
        numFrames = 6
    }

    topSheet = graphics.newImageSheet("pombinho.png", topSheetOptions)

    topSequenceData = 
    {
        {
            name = "fly",
            frames = {1, 2, 3, 4},
            time = 1000,
            loopCount = 0,
            loopDirection = foward
        },

        {
            name = "death",
            --start = 5,
            --count = 6,
            frames = {5, 6},
            time = 250,
            loopCount = 1
        }
    }

    bottomSheetOptions = 
    {
        width = 64,
        height = 64,
        numFrames = 9
    }

    bottomSheet = graphics.newImageSheet("snowman-boom.png", bottomSheetOptions)

    bottomSequenceData =
    {
        {
            name = "run",
            start = 1,
            count = 2, 
            time = 400,
            loopCount = 0,
            loopDirection = "foward",
        },

        {
            name = "boom",
            frames = {3, 4, 5, 6, 7, 8, 9},
            time = 1000,
            loopCount = 1
        }
    }

    towerSheetOptions = 
    {
        width = 96,
        height = 288,
        numFrames = 5,
        --sheetContentWidth = 2500,
        --sheetContentHeight = 5000
    }

    towerSequenceData = 
    {
        name = "health",
        start = 1,
        count = 5,
        time = 100,
        loopCount = 1,
        loopDirection = "foward"    
    }

    towerSheet = graphics.newImageSheet("torre.png", towerSheetOptions)

    --tower = display.newImageRect(mainGroup, towerSheet, 1, 64, 256)
    tower = display.newSprite(mainGroup, towerSheet, towerSequenceData)
    tower:setSequence("health")
    tower.currentHealth = 1
    tower:setFrame(tower.currentHealth)
    fitImage(tower, 1200, 1200, true)
    --tower:scale(4, 8)
    tower.x = display.contentCenterX - 200
    tower.y = display.contentCenterY + 20
    tower.myName = "tower"    
    physics.addBody(tower, "static", {filter=towerCollisionFilter})

    snowball = display.newImageRect(mainGroup, "snowball.png", 36, 36)
    snowball.x, snowball.y = player.x, player.y
    snowball.rotation = 90
    physics.addBody(snowball, "static", {isSensor = true, density = 2, friction = 1, bounce = 0.5, radius = snowball.width / 2, filter=snowballCollisionFilter})
    snowball.isBullet = true
    snowball:toBack()

    -- Minimum and maximum radius of the force circle indicator
    radiusMin, radiusMax = 32, 54 -- 32, 48
    -- Indicates force value
    forceArea = display.newCircle(player.x, player.y, radiusMax)
    forceArea.strokeWidth = 4
    forceArea:setFillColor(0, 0.5, 0.5, 0.2)
    forceArea:setStrokeColor(0, 1, 1, 0.2)
    forceArea.isVisible = false

    -- Display score
    scoreText = display.newText( uiGroup, "Score: " .. score, display.contentCenterX, 10, "Snowinter.ttf", 24)
    scoreText:setFillColor(0, 0.5, 1)
    player:addEventListener("touch", touch)
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
    sceneGroup:insert(player)
    sceneGroup:insert(snowball)


         
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        audio.stop()
        timer.cancel(gameLoopTimer)

        
        local death = display.newImageRect(sceneGroup, "you-died.png", 580, 80)
        death.x = display.contentCenterX 
        death.y = display.contentCenterY 
        --audio.play(soundTable["warped"])
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