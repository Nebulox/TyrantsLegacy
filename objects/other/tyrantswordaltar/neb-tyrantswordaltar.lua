function init()
  if not storage.itemHasSpawned then
    object.setInteractive(true)
    animator.setAnimationState("objectState", "filled")
	storage.itemHasSpawned = false
  else
    animator.setAnimationState("objectState", "empty")
	object.setInteractive(false)
  end
  message.setHandler("neb-tyrantsReturn-returnPlayerFunction", function(_, _, var, id)
      if not var then
	    storage.looted = true
		world.sendEntityMessage(id, "neb-tyrantsReturn-callPlayerFunction", "setProperty", {"neb-tyrantsReturn-hasSword", true})
	    animator.setAnimationState("objectState", "empty")
	    object.setInteractive(false)
	    object.setConfigParameter("breakDropPool", "empty")
      end
	end)
end

function open()
end

function onInteraction(args)
  world.sendEntityMessage(args.sourceId, "neb-tyrantsReturn-callPlayerFunction", "getProperty", {"neb-tyrantsReturn-hasSword", false}, entity.id())
end