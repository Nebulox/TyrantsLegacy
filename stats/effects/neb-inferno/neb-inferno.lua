require "/scripts/vec2.lua"

function init()
  if status.resourceMax("health") < config.getParameter("minMaxHealth", 0) then
    effect.expire()
  end
  
  self.projectileCount = config.getParameter("projectileCount")
  
  animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
  animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  animator.setParticleEmitterActive("flames", true)
  effect.setParentDirectives("fade=BF3300=0.25")
  animator.playSound("burn", -1)
  
  script.setUpdateDelta(5)

  self.tickDamagePercentage = config.getParameter("tickDamagePercentage", 0.025)
  self.tickTime =  config.getParameter("tickTime", 1)
  self.tickTimer = self.tickTime
end

function update(dt)
  animator.setParticleEmitterActive("smoke", (effect.duration() and world.liquidAt({mcontroller.xPosition(), mcontroller.yPosition() - 1})))
  if (effect.duration() and world.liquidAt({mcontroller.xPosition(), mcontroller.yPosition() - 1})) then
    animator.playSound("sizzle", -1)
  else
    animator.stopAllSounds("sizzle")
  end

  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
        damageSourceKind = "firebroadsword",
        sourceEntityId = entity.id()
      })
	spawnProjectiles()
  end
  
  if not status.resourcePositive("health") and status.resourceMax("health") >= config.getParameter("minMaxHealth", 0) then
    spawnProjectiles()
  end
end

function spawnProjectiles()
	local sourceEntity = effect.sourceEntity()
	if world.entityExists(sourceEntity) then
	  local projectileNumber = 0
	  for i = 1, self.projectileCount do
		projectileNumber = projectileNumber + 1
		
		local aimVec = vec2.rotate({0, 1}, (360 / (config.getParameter("projectileCount") + 1) * projectileNumber) + math.random(360))
		
		if config.getParameter("directPath", false) then
		  aimVec = {0, 0}
		end
		
		local projectileId = world.spawnProjectile(config.getParameter("projectileType"), mcontroller.position(), nil, aimVec, false)
		if projectileId then
		  world.sendEntityMessage(projectileId, "setTargetEntity", sourceEntity)
		  self.projectileSpawned = true
		end
	  end
	end
end

function uninit()

end
