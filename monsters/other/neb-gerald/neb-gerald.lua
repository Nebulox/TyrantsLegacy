require "/scripts/status.lua"

function init()
  monster.setUniqueId(config.getParameter("uniqueId"))
  local pos = mcontroller.position()
  mcontroller.setPosition({pos[1] + 0.25, pos[2]})
  monster.setDamageOnTouch(false)
  
  self.damageTaken = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
		if self.banterTimer == 0 and math.random() > config.getParameter("banterChance", 0.5) then
		  engageBanter()
		end
      end
    end
  end)
  
  self.banterTimer = config.getParameter("banterTimeout", 1)
end

function update(dt)
  --Regen
  local playerCount = #world.playerQuery(mcontroller.position(), 30, {order = "nearest"})
  local regenRate = (config.getParameter("regenRate", 125) * (playerCount + (playerCount * 0.1) - 0.1))
  local finalRegenRate = regenRate + ((1 - status.resourcePercentage("health")) * regenRate * 3)
  status.modifyResource("health", finalRegenRate * dt)
  if playerCount > 0 then
	monster.setDamageBar("Special")
  else
	monster.setDamageBar("None")
  end
  
  --Banter
  self.banterTimer = math.max(0, self.banterTimer - dt)
end

function engageBanter()
  local banter = config.getParameter("battleBanter")
  local phrase = banter[math.random(1, #banter)]
  monster.say(phrase)
  
  self.banterTimer = config.getParameter("banterTimeout", 1)
end

function die()
  local doors = world.entityQuery(entity.position(), 100)
  for _, door in ipairs(doors) do
    world.sendEntityMessage(door, "openDoor")
  end
end

function uninit()
end

