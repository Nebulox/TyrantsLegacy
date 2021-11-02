require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  if status.resourceMax("health") < config.getParameter("minMaxHealth", 0) then
    effect.expire()
  end
  
  self.projectileCount = config.getParameter("projectileCount")
  self.sourceEntity = effect.sourceEntity()
  
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
  --Effects
  animator.setParticleEmitterActive("smoke", self.musicPlaying)
  if not self.musicPlaying then
    self.musicPlaying = (effect.duration() and world.liquidAt({mcontroller.xPosition(), mcontroller.yPosition() - 1}))
    animator.playSound("sizzle", -1)
  else
    self.musicPlaying = (effect.duration() and world.liquidAt({mcontroller.xPosition(), mcontroller.yPosition() - 1}))
    animator.stopAllSounds("sizzle")
  end

  --Damage
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
        damageSourceKind = config.getParameter("damageKind", "firebroadsword"),
        sourceEntityId = self.sourceEntity
      })
	spawnProjectiles()
  end
  
  --Spread effect
  local nearEntities = world.entityQuery(mcontroller.position(), config.getParameter("spreadRadius", 0), {includedTypes = {"creature"}})
  nearEntities = util.filter(nearEntities, function(entityId)
    if world.lineTileCollision(mcontroller.position(), world.entityPosition(entityId)) then
	  return false
    end
    if self.sourceEntity and not world.entityCanDamage(self.sourceEntity, entityId) then
	  return false
    end
    if world.entityDamageTeam(entityId).type == "passive" then
	  return false
    end
    return true
  end)
  for _, entity in ipairs(nearEntities) do
    world.sendEntityMessage(entity, "applyStatusEffect", config.getParameter("spreadEffect", "burning"))
  end
  
  --On death send projectiles
  if not status.resourcePositive("health") and status.resourceMax("health") >= config.getParameter("minMaxHealth", 0) then
    spawnProjectiles()
  end
end

function spawnProjectiles()
	if world.entityExists(self.sourceEntity) then
	  local projectileNumber = 0
	  for i = 1, self.projectileCount do
		projectileNumber = projectileNumber + 1
		
		local aimVec = vec2.rotate({0, 1}, (360 / (config.getParameter("projectileCount") + 1) * projectileNumber) + math.random(360))
		
		if config.getParameter("directPath", false) then
		  aimVec = {0, 0}
		end
		
		local projectileId = world.spawnProjectile(config.getParameter("projectileType"), mcontroller.position(), nil, aimVec, false)
		if projectileId then
		  world.sendEntityMessage(projectileId, "setTargetEntity", self.sourceEntity)
		  self.projectileSpawned = true
		end
	  end
	end
end

function uninit()

end
