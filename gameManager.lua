require("jlEvent")

local ston = nil

gameManager = {}

gameManager.__index = gameManager
--[[MAKE INTO A SINGLETON!!!]]--
setmetatable(gameManager,
		{__call = function(cls, ...)
			return cls.new(...)
		end})

function gameManager.new()
	local self = setmetatable({}, gameManager)
	self:init()
	return self
end

function gameManager:init()
	self.events = {}
	self.currentLevel = 0
	self.numLevels = 0
	self.playerLives = 0
	self.gameState = "running"
	self.deathTimer = 1.2
	self.fadeTimer = 1.2
 	self.fadeInTimer = 0
  	self.fadeInMax = 0.4

	self.hasPad = false
	self.pad = nil

	self.currX = 0
	self.currY = 0
	self.toX = 0
	self.toY = 0
	self.cameraTime = 0
	self.elapsed = 0
	self.moving = false

	self.storedPlayerPos = vector(0, 0)
	self.storedFloorsPos = {}
	self.storedEnemiesPos = {}
	self.storedEnemiesState = {}
	self.storedMoversPos = {}
	self.storedMoversState = {}
	self.storedMoversDir = {}
	self.storedMoversDist = {}
	self.storedTranslateX = 0 
	self.storedTranslateY = 0

	self.storedMoversCurrentExtent = {}
	self.storedMoversOtherExtent = {}
	self.storedWallsPos = {}
	self.storedWallsState = {}
	self.storedGunsPos = {}
	self.storedGunsState = {}
	self.storedGunsBulletsMade = {}
	self.storedGunsBulletsState = {}
	self.storedGunsBulletsPos = {}
	self.storedGunsAges = {}

  self.padMapping = {}
--	==self.stored
end

function gameManager:getButtons()
	local buttons = {}
	for i = 0, self.pad:getButtonCount() do
		buttons[i] = self.pad:isDown(i)
	end
	return buttons
end

function gameManager:getMapping(button)
  return self.padMapping[button]
end

function gameManager:checkForPad()
	if love.joystick.getJoystickCount() > 0 then
		if self.hasPad then return end
		local pads = love.joystick.getJoysticks()
		self.pad = pads[1]
		local padID = self.pad:getGUID()
		_, self.padMapping["leftx"] = self.pad:getGamepadMapping("leftx")
		_, self.padMapping["lefty"] = self.pad:getGamepadMapping("lefty")
		_, self.padMapping["rightx"] = self.pad:getGamepadMapping("rightx")
		_, self.padMapping["righty"] = self.pad:getGamepadMapping("righty")		
		
		_, self.padMapping["b"] = self.pad:getGamepadMapping("b");
		_, self.padMapping["back"] = self.pad:getGamepadMapping("back");
		self.hasPad = true
	else
		self.pad = nil
		self.hasPad = false
	end
end

function gameManager:getLeftStickAxes()
	if self.hasPad then	return self.pad:getAxis(self.padMapping["leftx"]), self.pad:getAxis(self.padMapping["lefty"]) else return 0, 0 end
end

function gameManager:getRightStickAxes()
	if self.hasPad then	return self.pad:getAxis(self.padMapping["rightx"]), self.pad:getAxis(self.padMapping["righty"]) else return 0, 0 end
end

function gameManager:getBandedAxes(upStages, downStages)
	x, y = self:getLeftStickAxes()
	x2, y2 = self:getRightStickAxes()
	local bx, by = x, y

	x = math.abs(x) > math.abs(x2) and x or x2
	y = math.abs(y) > math.abs(y2) and y or y2

	for _, s in ipairs(downStages) do
		if x <= s then bx = s end
		if y <= s then by = s end
	end
	
	for _, s in ipairs(upStages) do
		if x >= s then bx = s end
		if y >= s then by = s end
	end
	return bx, by
end

function gameManager:moveCameraGradual(dt)
	if not self.moving then return end
	self.elapsed = self.elapsed + dt
	local extent = self.elapsed/self.cameraTime
	if self.elapsed < self.cameraTime then
		self.currX = self.currX + extent * (self.toX - self.currX)
		self.currY = self.currY + extent * (self.toY - self.currY)
	else
		self.currX = self.toX
		self.currY = self.toY
		self.moving = false
		self.elapsed = 0
	end

end



function gameManager:moveCamera(toX, toY, time)
	self.toX = toX
	self.toY = toY
	self.cameraTime = time
	self.elapsed = 0
	self.moving = true
end

function gameManager:getCurrX()
	return self.currX
end

function gameManager:getCurrY()
	return self.currY
end

function gameManager:setCurrX(x)
	self.currX = x
end

function gameManager:setCurrY(y)
	self.currY = y
end

function gameManager:setToX(x)
	self.toX = x
end

function gameManager:setToY(y)
	self.toY = y
end

function gameManager:getFadeInMax()
  return self.fadeInMax
end

function gameManager:update(dt)
	self:checkForPad()
	if self.gameState == "running" then
    self.fadeInTimer = self.fadeInTimer + dt
    self.fadeInTimer = math.min(self.fadeInTimer, self.fadeInMax)
	end
  if self.gameState == "finishinglevel" then
		if self.fadeTimer > 0 then
			self.fadeTimer = self.fadeTimer - dt
		else
			self.gameState = "loading"
		end
	end
	if self.gameState == "finishinggame" then
		if self.fadeTimer > 0 then
			self.fadeTimer = self.fadeTimer - dt
		else
			self.gameState = "endsplash"
		end
	end
	if self.gameState == "dead" then
		if self.deathTimer > 0 then
			self.deathTimer = self.deathTimer - dt
		else
			self:loadState()
		end
	end
	if self.moving then
		self:moveCameraGradual(dt)
	end
end

function gameManager:getDeathTimer()
	return math.min(self.deathTimer, 1)
end

function gameManager:getFadeTimer()
  return math.min(self.fadeTimer, 1)
end

function gameManager:getFadeInTimer()
  return self.fadeInTimer
end

function gameManager:saveState()
	self.storedPlayerPos = thePlayer:getPos():clone()
	self.storedTranslateX = self.toX
	self.storedTranslateY = self.toY

	for i, v in ipairs(scenery) do
		self.storedFloorsPos[i] = v:getPos():clone()
	end
	for i, v in ipairs(enemies) do
		self.storedEnemiesPos[i] = v:getPos():clone()
		self.storedEnemiesState[i] = v:getState()
	end
	for i, v in ipairs(movers) do
		self.storedMoversPos[i] = v:getPos():clone()
		self.storedMoversState[i] = v:getState()
		self.storedMoversDir[i] = v:getDir():clone()
		self.storedMoversDist[i] = v:getDist()
		self.storedMoversCurrentExtent[i] = v:getCurrentExtent()
		self.storedMoversOtherExtent[i] = v:getOtherExtent()
	end
	for i, v in ipairs(blocks) do
		self.storedWallsPos[i] = v:getPos():clone()
		self.storedWallsState[i] = v:getState()
	end
	for i, v in ipairs(guns) do
		self.storedGunsPos[i] = v:getPos():clone()
		self.storedGunsState[i] = v:getState()
		self.storedGunsBulletsMade[i] = v:getBulletsMade()
	end
end


function gameManager:loadState()
	self:setState("running")
	self.deathTimer = 1.2
	self.fadeTimer = 1.2
	self.fadeInTimer = 0.0
	thePlayer:setState("resting")
	thePlayer:resetAnim("dead")
	thePlayer:resetSounds()	
	thePlayer:setPos(self.storedPlayerPos:clone())
	self.currX = self.storedTranslateX
	self.currY = self.storedTranslateY
	self.toX = self.storedTranslateX
	self.toY = self.storedTranslateY
	
	self.moving = false
	for i, v in ipairs(scenery) do
		v:setPos(self.storedFloorsPos[i]:clone())
	end
	for i, v in ipairs(enemies) do
		v:setPos(self.storedEnemiesPos[i]:clone())
		v:setState(self.storedEnemiesState[i])
		if v.resetBehaviour then v:resetBehaviour() end
		--if v:getState() ~= "dead" then v:resetAnim("dead") end
		v:setPath(nil)
		if v:getState() ~= "dead" then
			v:resetAnims()--("dead")
			v:resetSounds()	
		end
		v:setPathTimer(1.1)
		--v:setFlatMap(nil)
	end
	for i, v in ipairs(movers) do
		v:setPos(self.storedMoversPos[i]:clone())
		v:setState(self.storedMoversState[i])
		v:setDir(self.storedMoversDir[i]:clone())
		v:setDist(self.storedMoversDist[i])
		v:setCurrentExtent(self.storedMoversCurrentExtent[i])
		v:setOtherExtent(self.storedMoversOtherExtent[i])
	end
	for i, v in ipairs(blocks) do
		v:setPos(self.storedWallsPos[i]:clone())
		v:setState(self.storedWallsState[i])
		if v:getState() ~= "off" then
			v:resetSounds()
		end
		if v:getState() ~= "dead" then youShallNotPass(pathMap, v:getPos(), v:getSize()) end
	end

	for i, v in ipairs(guns) do
		v:setPos(self.storedGunsPos[i]:clone())
		v:setState(self.storedGunsState[i])
		v:setBulletsMade(self.storedGunsBulletsMade[i])
		v:resetFiringBehaviour()
		v:killBullets()
		v:resetTimeLastBullet()
		v:resetSounds()
		if v:getState() ~= "dead" and v:getInvisible() == false then youShallNotPass(pathMap, v:getPos(), v:getSize()) end
	end
end
	--	end

function gameManager:unload()
	self.events = {}
	self.deathTimer = 1.2
	self.fadeTimer = 1.2
	self.fadeInTimer = 0
	self.currX = 0
	self.currY = 0
	self.toX = 0
	self.toY = 0

	self.moving = false

	self.storedPlayerPos = nil 
	
	self.storedTranslateX = {} 
	self.storedTranslateY = {}

	self.storedFloorsPos = {}

	self.storedEnemiesPos = {}
	self.storedEnemiesState = {}
	
	self.storedMoversPos = {} 
	self.storedMoversState = {}
	self.storedMoversDir = {}
	self.storedMoversDist = {}
	self.storedMoversCurrentExtent = {}
	self.storedMoversOtherExtent = {}

	self.storedWallsPos = {}
	self.storedWallsState = {}

	self.storedGunsPos = {} 
	self.storedGunsState = {}
	self.storedGunsBulletsMade = {}
end

function gameManager:targets(a)
	local i = 0
	if self.events[a] then
		i = #self.events[a] + 1
	end
	return function()
		i = i - 1
		if self.events[a] and self.events[a][i] then
			return i, self.events[a][i]
		end

	end
end

function gameManager:setCurrentLevel(l)
	if l < self.numLevels or l > 0 then self.currentLevel = l end
end

function gameManager:getCurrentLevel()
	return self.currentLevel
end

function gameManager:setNextLevel(l)
	if self.currentLevel < self.numLevels then self.currentLevel = self.currentLevel + 1 end
end

function gameManager:setPrevLevel(l)
	if self.currentLevel > 0 then self.currentLevel = self.currentLevel - 1 end
end

function gameManager:setNumLevels(n)
	self.numLevels = n
end

function gameManager:getNumLevels()
	return self.numLevels
end

function gameManager:setState(s)
	self.gameState = s
end

function gameManager:getState()
	return self.gameState
end

function gameManager:sendEvent(e)
	if self.events[e:getTarget()] == nil then
		self.events[e:getTarget()] = {e}
	else
		self.events[e:getTarget()][#self.events[e:getTarget()] + 1] = e
	end
end

function gameManager:removeEvent(k, i) 
	table.remove(self.events[k], i)
end

function gameManager:showEvents()
	for i, v in pairs(self.events) do
			print(i, v)
			for g, j in ipairs(v) do
				print(g, j:getID())
			end
	end
end
		
function gameManager:pause()
	if self.gameState == "paused" then self.gameState = "running"
	elseif self.gameState == "running" then self.gameState = "paused"
	end
end


if ston == nil then
	ston = gameManager:new()
end

return ston
