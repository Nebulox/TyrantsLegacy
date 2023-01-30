function init()
  object.setInteractive(storage.interactive or config.getParameter("interactive", false))
end

function onInteraction(args)
  world.sendEntityMessage(args.sourceId, "neb-tyrantknelt")
end