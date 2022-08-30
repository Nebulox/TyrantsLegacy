require "/scripts/util.lua"

function init()
  storage.gender = storage.gender or "male"
  
  storage.looted = storage.looted
  object.setInteractive(not storage.looted)
  if storage.looted then
    animator.setAnimationState("state", "looted")
  else
    animator.setAnimationState("state", "full")
  end 
  
  message.setHandler("neb-tyrantsReturn-returnPlayerFunction", function(_, _, var, id)
      if not var then
	    storage.looted = true
		animator.setAnimationState("state", "looted")
		world.sendEntityMessage(id, "neb-tyrantsReturn-callPlayerFunction", "setProperty", {"neb-tyrantsReturn-hasArmour", true})
      end
	end)
end

function onInteraction(args)
  world.sendEntityMessage(args.sourceId, "neb-tyrantsReturn-callPlayerFunction", "getProperty", {"neb-tyrantsReturn-hasArmour", false}, entity.id())
end