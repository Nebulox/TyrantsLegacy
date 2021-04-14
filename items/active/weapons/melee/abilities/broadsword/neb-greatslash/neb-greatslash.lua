require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/weapon.lua"

NebGreatSlash = WeaponAbility:new()

function NebGreatSlash:init()
  self.cooldownTimer = self.cooldownTime
end

function NebGreatSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.fireTimer = 0

  if not self.weapon.currentAbility
     and self.cooldownTimer == 0
     and self.fireMode == "alt"
     and not status.statPositive("activeMovementAbilities")
     and status.overConsumeResource("energy", self.energyUsage) then

    self:setState(self.windup)
  end
end

function NebGreatSlash:windup()
  self.weapon:setStance(self.stances.windup)

  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

  if mcontroller.onGround() then
    util.wait(self.stances.windup.duration, function(dt)
        mcontroller.controlCrouch()
      end)
  end

  self:setState(self.flip, mcontroller.onGround())
end

function NebGreatSlash:flip(grounded)
  self.weapon:setStance(self.stances.flip)
  self.weapon:updateAim()

  animator.setAnimationState("swoosh", "greatSlashWindup")
  animator.playSound(self.fireSound or "greatSlashFire")
  animator.setParticleEmitterActive("greatSlash", true)

  self.flipTime = self.rotations * self.rotationTime
  self.flipTimer = 0

  self.jumpTimer = 0
  if grounded then
    self.jumpTimer = self.jumpDuration
  end
  
  --Init projectile variables
  local params = sb.jsonMerge(self.projectileParameters, {})
  params.power = (self.baseDps * self.fireTime) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier")
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  
  local firePosition = vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset or {0, 0}))
  local aimVec = vec2.rotate({1, 0}, self.weapon.aimAngle)
  aimVec[1] = aimVec[1] * mcontroller.facingDirection()

  while self.flipTimer < self.flipTime do
    --Prevent movement
    mcontroller.setVelocity({0, 0})
	
	--Decay timers
    spinSpeedFactor = math.sin(self.flipTimer * self.flipTime) + 0.5
    self.flipTimer = self.flipTimer + (self.dt * spinSpeedFactor)
	self.fireTimer = math.max(0, self.fireTimer - self.dt)

    mcontroller.controlParameters(self.flipMovementParameters)

	--Launch player
    if self.jumpTimer > 0 then
      self.jumpTimer = self.jumpTimer - self.dt
      mcontroller.setVelocity({self.jumpVelocity[1] * self.weapon.aimDirection, self.jumpVelocity[2]})
    end
	
	--Spawn trail and damaging projectiles
	if self.fireTimer == 0 and self.jumpTimer <= 0 then
	  self.fireTimer = self.fireTime
	  world.spawnProjectile(
        self.projectileType,
        firePosition,
        activeItem.ownerEntityId(),
        aimVec,
        false,
		params
	  )
	end

    mcontroller.setRotation(-math.pi * 2 * self.weapon.aimDirection * (self.flipTimer / self.rotationTime))

    coroutine.yield()
  end

  status.clearPersistentEffects("weaponMovementAbility")

  animator.setAnimationState("swoosh", "greatSlashWinddown")
  mcontroller.setRotation(0)
  animator.setParticleEmitterActive("greatSlash", false)
  self.cooldownTimer = self.cooldownTime
end


function NebGreatSlash:uninit()
  status.clearPersistentEffects("weaponMovementAbility")
  animator.setAnimationState("swoosh", "idle")
  mcontroller.setRotation(0)
  animator.setParticleEmitterActive("greatSlash", false)
end
