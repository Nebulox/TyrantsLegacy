function init()
  self.gearSetType = config.getParameter("gearSetType")
  
  script.setUpdateDelta(1)
end

function update(dt)
  if not self.setPieceRegistered then
	self.statModifierGroup = effect.addStatModifierGroup({
	  {stat = self.gearSetType, amount = 1}
	})
	self.setPieceRegistered = true
  end
  if status.stat(self.gearSetType) >= 3 then
    status.setStatusProperty("neb-tyrantssword", 1)
  end
end

function uninit()
  status.setStatusProperty("neb-tyrantssword", 0)
end
