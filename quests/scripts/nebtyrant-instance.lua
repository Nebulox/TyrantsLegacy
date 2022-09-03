require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/quests/scripts/portraits.lua"

function init()
  self.descriptions = config.getParameter("descriptions")

  self.warpEntity = config.getParameter("warpEntityUid")
  self.warpAction = config.getParameter("warpAction")
  self.warpDialog = config.getParameter("warpDialog")

  self.goalTrigger = config.getParameter("goalTrigger", "proximity")

  self.trackGoalEntity = config.getParameter("trackGoalEntity", false)
  self.indicateGoals = config.getParameter("indicateGoals", false)
  
  self.conditionConfig = config.getParameter("conditionConfig", {})

  self.turnInEntity = config.getParameter("turnInEntityUid")
 
  buildConditions()
 
  setPortraits()

  self.stages = {
    enterInstance,
    findGoal,
    turnIn
  }

  storage.stage = storage.stage or 1
  self.state = FSM:new()
  self.state:set(self.stages[storage.stage])
end

function questStart()
  local associatedMission = config.getParameter("associatedMission")
  if associatedMission then
    player.enableMission(associatedMission)
  end
end

function update(dt)
  self.state:update()
end

function questInteract(entityId)
  if self.onInteract then
    return self.onInteract(entityId)
  end
end

function questComplete()
  setPortraits()

  questutil.questCompleteActions()
end

function enterInstance(dt)
  quest.setCompassDirection(nil)
  quest.setObjectiveList({
    {self.descriptions.enterInstance, false}
  })
  quest.setParameter("warpentity", {type = "entity", uniqueId = self.warpEntity})
  quest.setIndicators({"warpentity"})

  self.onInteract = function(entityId)
    if world.entityUniqueId(entityId) == self.warpEntity then
      if not self.warpConfirmation then
        local dialogConfig = root.assetJson(self.warpDialog)
        dialogConfig.sourceEntityId = entityId
        self.warpConfirmation = player.confirm(dialogConfig)
      end
      return true
    end
  end

  local findWarpEntity = util.uniqueEntityTracker(self.warpEntity, 0.5)
  local questValid, target = questValidAndNextTarget()
  local currentGoalEntity = util.uniqueEntityTracker(target, 0.5)
  while storage.stage == 1 do
    questutil.pointCompassAt(findWarpEntity())
	
    if currentGoalEntity() then
      storage.stage = 2
    end

    if self.warpConfirmation and self.warpConfirmation:finished() then
      if self.warpConfirmation:result() then
        if type(self.warpAction) == "string" then
          player.warp(self.warpAction, "beam")
        elseif type(self.warpAction) == "table" then
          player.warp(self.warpAction[1], self.warpAction[2], self.warpAction[3])
        end
      end
      self.warpConfirmation = nil
    end

    coroutine.yield()
  end
  
  self.state:set(self.stages[storage.stage])
end

function findGoal(dt)
  quest.setCompassDirection(nil)
  
  quest.setIndicators({})
  if self.indicateGoals then
    quest.setIndicators(setupIndicators())
  end
  
  quest.setObjectiveList(updateConditions())

  local warpAction = "outpost"
  if type(self.warpAction) == "string" then
	warpAction = self.warpAction
  elseif type(self.warpAction) == "table" then
	warpAction = self.warpAction[1]
  end
  local delim = ":"

  local targetDungeon = warpAction:sub(warpAction:find(delim, 1, true) + 1, -1)
  
  while storage.stage == 2 do
	local questValid, target = questValidAndNextTarget()
	
	if target then
      local currentGoalEntity = util.uniqueEntityTracker(target, 0.5)
      local goalPosition = currentGoalEntity()
      if self.trackGoalEntity then
        questutil.pointCompassAt(goalPosition)
	  else
		quest.setCompassDirection(nil)
      end
	end
	
    quest.setObjectiveList(updateConditions())
	
	if questValid then
	  storage.stage = 3
	elseif world.type() ~= targetDungeon then
	  storage.stage = 1
	end

    coroutine.yield()
  end

  self.state:set(self.stages[storage.stage])
end

function setupIndicators()
  local indicatorList = {}
  for _, conditionInfo in ipairs(self.conditionConfig) do
    local param = "goalEntity" .. conditionInfo.goalUid
    table.insert(indicatorList, param)
  
    local indicator = {type = "entity", uniqueId = conditionInfo.goalUid}
    quest.setParameter(param, indicator)
  end
  return indicatorList
end

function buildConditions()
  for _, conditionInfo in ipairs(self.conditionConfig) do
    if conditionInfo.type == "message" then
      message.setHandler(conditionInfo.message, function()
        self[conditionInfo.goalUid .. "MessageReceived" .. conditionInfo.message] = true
      end)
	end
  end
end

function updateConditions()
  local conditions = {}

  for _, conditionInfo in ipairs(self.conditionConfig) do
	local valueCompletion = false
	if conditionInfo.type == "playerProperty" then
	  if player.getProperty(table.unpack(conditionInfo.args)) then
	    valueCompletion = true
	  end
	elseif conditionInfo.type == "message" then
	  if self[conditionInfo.goalUid .. "MessageReceived" .. conditionInfo.message] then
	    valueCompletion = true
	  end
	end
	
	local condition = {conditionInfo.description, valueCompletion}
    table.insert(conditions, condition)
  end

  return conditions
end

function questValidAndNextTarget()
  local valid = true
  local target = nil
  for _, conditionInfo in pairs(self.conditionConfig) do
    if conditionInfo.type == "playerProperty" then
  	  valid = player.getProperty(table.unpack(conditionInfo.args))
	elseif conditionInfo.type == "message" then
	  valid = self[conditionInfo.goalUid .. "MessageReceived" .. conditionInfo.message] or false
	end
	
	if not valid and not target then
  	  target = conditionInfo.goalUid
    end
  end
  return valid, target
end

function turnIn()
  quest.setCompassDirection(nil)
  quest.setObjectiveList({
    {self.descriptions.turnIn, false}
  })
  quest.setIndicators({})
  self.onInteract = nil

  if self.turnInEntity then
    quest.setCanTurnIn(true)

    local findTurnInEntity = util.uniqueEntityTracker(self.turnInEntity, 0.5)
    while true do
      questutil.pointCompassAt(findTurnInEntity())
      coroutine.yield()
    end
  else
    quest.complete()
  end
end
