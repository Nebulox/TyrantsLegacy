function init()
  monster.setUniqueId(config.getParameter("uniqueId"))
  local pos = mcontroller.position()
  mcontroller.setPosition({pos[1] + 0.25, pos[2]})
  monster.setDamageOnTouch(false)
end

function update(dt)
  local playerCount = #world.playerQuery(mcontroller.position(), 30, {order = "nearest"})
  local regenRate = config.getParameter("regen", 125) * (playerCount + (playerCount * 0.1) - 0.1) 
  status.modifyResource("health", regenRate)
  if playerCount > 0 then
	monster.setDamageBar("Special")
  else
	monster.setDamageBar("None")
  end
end

function die()
  local doors = world.entityQuery(entity.position(), 100)
  for _, door in ipairs(doors) do
    world.sendEntityMessage(door, "openDoor")
  end
end

function uninit()
end

