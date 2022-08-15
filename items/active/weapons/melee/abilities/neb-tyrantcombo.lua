require "/scripts/interp.lua"

-- Melee primary ability
NebTyrantCombo = WeaponAbility:new()

function NebTyrantCombo:init()  
  self.comboStep = 1

  self.energyUsage = self.energyUsage or 0

  self:computeDamageAndCooldowns()

  self.weapon:setStance(self.stances.idle)

  self.edgeTriggerTimer = 0
  self.flashTimer = 0
  self.cooldownTimer = self.cooldowns[1]

  self.animKeyPrefix = self.animKeyPrefix or ""

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function NebTyrantCombo:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
    if self.cooldownTimer == 0 then
      self:readyFlash()
    end
  end

  if self.flashTimer > 0 then
    self.flashTimer = math.max(0, self.flashTimer - self.dt)
    if self.flashTimer == 0 then
      animator.setGlobalTag("bladeDirectives", "")
    end
  end
  
  self.edgeTriggerTimer = math.max(0, self.edgeTriggerTimer - dt)
  if self.lastFireMode ~= (self.activatingFireMode or self.abilitySlot) and fireMode == (self.activatingFireMode or self.abilitySlot) then
    self.edgeTriggerTimer = self.edgeTriggerGrace
  end
  self.lastFireMode = fireMode

  if not self.weapon.currentAbility and self:shouldActivate() then
    self:setState(self.windup)
  end
end

-- State: windup
function NebTyrantCombo:windup()
  local stance = self.stances["windup"..self.comboStep]

  self.weapon:setStance(stance)

  self.edgeTriggerTimer = 0

  if stance.hold then
    while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
      coroutine.yield()
    end
  elseif stance.endWeaponRotation then
    --Smoothly windup
    local progress = 0
    util.wait(stance.duration, function()
      progress = math.min(stance.duration, progress + self.dt)
      local progressRatio = math.sin(progress / stance.duration * 1.57)
	
	  local from = stance.weaponOffset or {0,0}
      local to = stance.endWeaponOffset or {0,0}
      self.weapon.weaponOffset = {interp.linear(progressRatio, from[1], to[1]), interp.linear(progressRatio, from[2], to[2])}

      self.weapon.relativeWeaponRotation = util.toRadians(util.lerp(progressRatio, {stance.weaponRotation, stance.endWeaponRotation}))
      self.weapon.relativeArmRotation = util.toRadians(util.lerp(progressRatio, {stance.armRotation, stance.endArmRotation}))
    end)
  else
    util.wait(stance.duration)
  end

  if self.energyUsage then
    status.overConsumeResource("energy", self.energyUsage)
  end

  if self.stances["preslash"..self.comboStep] then
    self:setState(self.preslash)
  else
    self:setState(self.fire)
  end
end

-- State: wait
-- waiting for next combo input
function NebTyrantCombo:wait()
  local stance = self.stances["wait"..(self.comboStep - 1)]

  self.weapon:setStance(stance)

  util.wait(stance.duration, function()
    if self:shouldActivate() then
      self:setState(self.windup)
      return
    end
  end)

  self.cooldownTimer = math.max(0, self.cooldowns[self.comboStep - 1] - stance.duration)
  self.comboStep = 1
end

-- State: preslash
-- brief frame in between windup and fire
function NebTyrantCombo:preslash()
  local stance = self.stances["preslash"..self.comboStep]

  self.weapon:setStance(stance)
  self.weapon:updateAim()

  util.wait(stance.duration)

  self:setState(self.fire)
end

-- State: fire
function NebTyrantCombo:fire()
  local stance = self.stances["fire"..self.comboStep]

  self.weapon:setStance(stance)
  self.weapon:updateAim()

  local animStateKey = self.animKeyPrefix .. (self.comboStep > 1 and "fire"..self.comboStep or "fire")
  animator.setAnimationState("swoosh", animStateKey)
  animator.playSound(animStateKey)

  local swooshKey = self.animKeyPrefix .. (self.elementalType or self.weapon.elementalType) .. "swoosh"
  animator.setParticleEmitterOffsetRegion(swooshKey, self.swooshOffsetRegions[self.comboStep])
  animator.burstParticleEmitter(swooshKey)

  local canFire = true
  local loopTimer = 0
  --Set the damage area for the duration of the step
  util.wait(stance.duration, function()
	local damageArea = partDamageArea("swoosh")
	self.weapon:setDamage(self.stepDamageConfig[self.comboStep], damageArea)
	
    --Optionally fire a projectile
    if stance.projectile and status.statusProperty("neb-tyrantssword", 0) == 1 then
	  local firePosition = vec2.add(mcontroller.position(), activeItem.handPosition(self.firePoint or {0,0}))
	  local params = stance.projectileParameters or {}
	  params.power = stance.projectileDamage * config.getParameter("damageLevelMultiplier")
	  params.powerMultiplier = activeItem.ownerPowerMultiplier()
	  params.speed = util.randomInRange(params.speed)
		
	  world.debugPoint(firePosition, "red")
		
	  if not world.lineTileCollision(mcontroller.position(), firePosition) and canFire and status.overConsumeResource("energy", stance.energyUsage or 0) then
		for i = 1, (stance.projectileCount or 1) do
		  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(stance.projectileInaccuracy or 0, 0) + (stance.projectileAimAngleOffset or 0))
		  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
			
		  world.spawnProjectile(
			stance.projectile,
			firePosition,
			activeItem.ownerEntityId(),
			aimVector,
			false,
			params
	  	  )
	    end
	    canFire = false
	  end
		
	  --Optionally loop projectile firing during the stance
	  if stance.fireTime and not canFire then
	    loopTimer = math.min(stance.fireTime, loopTimer + self.dt)
		if loopTimer >= stance.fireTime then
		  loopTimer = 0
		  canFire = true
		end
	  end
	end
	  
	--Optionally freeze the player in place if so configured
	if stance.freezePlayer then
	  mcontroller.setVelocity({0,0})
	end
  end)

  --If this wasn't the last combo step, go to next step
  --Else, go to cooldown
  if self.comboStep < self.comboSteps then
    self.comboStep = self.comboStep + 1
    self:setState(self.wait)
  else
    if self.fullComboCooldown then
	  self.cooldownTimer = self.fullComboCooldown
	else
	  self.cooldownTimer = self.cooldowns[self.comboStep]
	end
    self.comboStep = 1
  end
end

function NebTyrantCombo:shouldActivate()
  if self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
    if self.comboStep > 1 then
      return self.edgeTriggerTimer > 0
    else
      return self.fireMode == (self.activatingFireMode or self.abilitySlot)
    end
  end
end

function NebTyrantCombo:readyFlash()
  animator.setGlobalTag("bladeDirectives", self.flashDirectives)
  self.flashTimer = self.flashTime
end

function NebTyrantCombo:computeDamageAndCooldowns()
  local attackTimes = {}
  for i = 1, self.comboSteps do
    local attackTime = self.stances["windup"..i].duration + self.stances["fire"..i].duration
    if self.stances["preslash"..i] then
      attackTime = attackTime + self.stances["preslash"..i].duration
    end
    table.insert(attackTimes, attackTime)
  end

  self.cooldowns = {}
  local totalAttackTime = 0
  local totalDamageFactor = 0
  
  local currentDamageConfig = (self.active and self.activeDamageConfig or self.damageConfig)
  for i, attackTime in ipairs(attackTimes) do
    util.mergeTable(self.stepDamageConfig[i], currentDamageConfig)
    self.stepDamageConfig[i].timeoutGroup = "primary"..i

    local damageFactor = self.stepDamageConfig[i].baseDamageFactor
    self.stepDamageConfig[i].baseDamage = damageFactor * self.baseDps * self.fireTime

    totalAttackTime = totalAttackTime + attackTime
    totalDamageFactor = totalDamageFactor + damageFactor

    local targetTime = totalDamageFactor * self.fireTime
    local speedFactor = 1.0 * (self.comboSpeedFactor ^ i)
    table.insert(self.cooldowns, (targetTime - totalAttackTime) * speedFactor)
  end
end

function NebTyrantCombo:uninit()
  self.weapon:setDamage()
end
