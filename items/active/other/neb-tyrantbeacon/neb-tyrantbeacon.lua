require "/scripts/vec2.lua"

function init()
  self.fireOffset = config.getParameter("fireOffset")
  self.warpAction = config.getParameter("warpAction")
  
  updateAim()
end

function update(dt, fireMode, shiftHeld)
  updateAim()
  
  if fireMode == "primary" then
	item.consume(1)
    if player then
      player.warp(self.warpAction, "beam")
	end
    return
  end
end

function updateAim()
  self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  activeItem.setArmAngle(self.aimAngle)
  activeItem.setFacingDirection(self.aimDirection)
end

function firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function aimVector()
  local aimVector = vec2.rotate({1, 0}, self.aimAngle + sb.nrand(config.getParameter("inaccuracy", 0), 0))
  aimVector[1] = aimVector[1] * self.aimDirection
  return aimVector
end

function holdingItem()
  return true
end

function recoil()
  return false
end

function outsideOfHand()
  return false
end
