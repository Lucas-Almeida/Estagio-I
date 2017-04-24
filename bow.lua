bow = {}

function bow:new(x, y, bowHeight, startSpeed, accuracy)
	self = {}
	
	-- properties to set up the bow's features
	self.x = x
	self.y = y
	self.startSpeed = startSpeed	
	self.angle = 0
	
	-- init the first state of the bow
	self.bowui = display.newImage("Images/bow.png", 0, 0)
	self.bowui:setReferencePoint(display.CenterReferencePoint)
	self.bowui.x, self.bowui.y = self.x, self.y	
	self.bowui.xScale = bowHeight / self.bowui.height
	self.bowui.yScale = bowHeight / self.bowui.height
	
	-- init the first state of the arrow
	self.arrowui = display.newImage("Images/arrow.png", 0, 0)
	self.arrowui:setReferencePoint(display.CenterReferencePoint)
	self.arrowui.x, self.arrowui.y = self.x, self.y
	self.arrowui.xScale = bowHeight / self.arrowui.height / 2
	self.arrowui.yScale = bowHeight / self.arrowui.height / 2
	
	-- timer handles the shooting event
	self.arrowui.timer = nil
	
	-- targets for collision checking
	self.targets = {}
	self.targets.count = 0
	
	-- bow's accuracy
	self.accuracy = accuracy
	
	-- the timer counter used for calculating the arrow's position by the time
	local tCounter = 0
	
	-- reload the arrow
	self.reload = function()
		-- reset timer
		if self.arrowui.timer ~= nil then
			timer.cancel(self.arrowui.timer)
			self.arrowui.timer = nil
		end
		
		-- reset arrow's position		
		self.arrowui:setReferencePoint(display.CenterReferencePoint)
		self.arrowui.x, self.arrowui.y = self.x, self.y
		self.arrowui.rotation = self.bowui.rotation
	end
	
	-- the collision event
	self.onCollision = nil
	
	-- add target for collision checking
	self.addTarget = function(target)
		self.targets.count = self.targets.count + 1
		self.targets[self.targets.count] = target
	end
	
	-- check if the collision occurs using accuracy or object's collision check function
	self.isCollided = function()
		-- storing collision data
		local ev = {}
		
		-- count the hit targets
		local cnt = 0
		
		if self.targets ~= nil then
			for i = 1, #self.targets do				
				-- if collision check is implemented 
				if self.targets[i].isCollided ~= nil then
					local isHit = self.targets[i].isCollided(self.arrowui.x, self.arrowui.y)
					if isHit then
						cnt = cnt + 1
						ev[cnt] = {}				
						ev[cnt].target = self.targets[i]
						
						ev[cnt].x, ev[cnt].y = self.arrowui.x, self.arrowui.y
						ev[cnt].angle = self.arrowui.rotation
						
					end
				-- if the collision checking is not implemented on the target, then use accuracy
				else
					-- compute the distance between the arrow and a target
					local d = (self.arrowui.x - self.targets[i].x) ^ 2 + (self.arrowui.y - self.targets[i].y) ^ 2
					-- compare the distance
					if (d < accuracy ^ 2) then			
						cnt = cnt + 1
						ev[cnt] = {}				
						ev[cnt].target = self.targets[i]
						
						ev[cnt].x, ev[cnt].y = self.arrowui.x, self.arrowui.y
						ev[cnt].angle = self.arrowui.rotation
					end
				end
			end
		end
		
		return ev
	end
	
	-- update position of the arrow while shooting
	self.arrowui.update = function(event)		
		
		local angle = self.bowui.rotation * math.pi / 180
		local g = -0.98 -- gravity
				
		-- horizontal velocity
		local vx = self.startSpeed * math.cos(angle)		
		-- update new position		
		self.arrowui.x = self.arrowui.x + vx	
		
		local h = self.arrowui.y - self.bowui.y
		-- check if h is max height then switch the gravity direction
		if (h == self.startSpeed ^ 2 * math.sin(angle) ^ 2 / (2 * g)) then
			g = g * (-1)
		end
		
		-- vertical velocity
		local vy = self.startSpeed * math.sin(angle) - g * tCounter
		-- update new position
		self.arrowui.y = self.arrowui.y + vy
		
		-- compute the angle of the arrow		
		local arAngle = math.atan2(vy, vx)
		self.arrowui.rotation = arAngle * 180 / math.pi
		
		-- timer counter
		tCounter = tCounter + 1	
		
		-- invoke the collision detection function
		local collided = self.isCollided()
		-- raise collision event
		if collided ~= nill then		
			self.onCollision(collided)
		end 
		
		-- if the arrow is moving out of boundaries, reload the bow
		if self.arrowui.y > 1100 or self.arrowui.y < - 100 then			
			print ("reload")
			self.reload()
		end
		
	end
	
	-- handle shoot event, when the arrow is released
	self.arrowui.shoot = function()
		tCounter = 0
		self.arrowui.timer = timer.performWithDelay(20, self.arrowui.update, 0)		
	end
	
	-- handle touch event
	self.onShoot = function(event)
		local eX, eY = event.x, event.y
		local target = self.bowui
		display.getCurrentStage():setFocus(self.arrowui) 
		
		-- update the bow's rotation
		if event.phase == "moved" then
			
			local dx = target.x - eX
			local dy = target.y - eY
			local angle = math.atan2(dy, dx)
			local angle180 = angle * 180 / math.pi
			
			print(angle180)
			
			self.bowui.rotation = angle180
			self.arrowui.rotation = angle180					
			
		elseif event.phase == "ended" or event.phase == "cancelled" then
			-- when the touch is released, shoot the arrow
			self.arrowui.shoot()
			display.getCurrentStage():setFocus(nil) 
		end
		
	end
	
	self.arrowui:addEventListener("touch", self.onShoot)
	
	return self
end