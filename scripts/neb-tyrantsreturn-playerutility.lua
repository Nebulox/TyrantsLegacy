local tyrantOriginalInit = init

function init()
  tyrantOriginalInit()
  
  message.setHandler("neb-tyrantsReturn-callPlayerFunction", callPlayerFunction)
end

function callPlayerFunction(_, _, functionType, args, returnId)
  local var = player[functionType](table.unpack(args))
  if returnId then
    world.sendEntityMessage(returnId, "neb-tyrantsReturn-returnPlayerFunction", var, entity.id())
  end
end