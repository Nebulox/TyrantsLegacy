function init()
  monster.setUniqueId(config.getParameter("uniqueId"))
end

function update(dt)
  if #world.playerQuery(mcontroller.position(), 30, {order = "nearest"}) > 0 then
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

