local function FindBeefalo()
  local beefalo = nil
  local x, y, z = ThePlayer.Transform:GetWorldPosition()
  local ents = TheSim:FindEntities(x, y, z, 100, {"beefalo", "rideable", "saddled"})
  local min_distance_sq = math.huge
  if #ents > 0 then
    for i, ent in pairs(ents) do
      local ex, ey, ez = ent.Transform:GetWorldPosition()
      local distance_sq = (ex - x) * (ex - x) + (ey - y) * (ey - y) + (ez - z) * (ez - z)
      if distance_sq < min_distance_sq then
        beefalo = ent
        min_distance_sq = distance_sq
      end
    end
  end
  return beefalo
end

local function FindFood()
  local inventory = ThePlayer.replica.inventory
  if inventory and inventory:GetItems() then
    for _, i in pairs(inventory:GetItems()) do
      if i:HasTag("edible_"..FOODTYPE.ROUGHAGE) or i:HasTag("edible_"..FOODTYPE.VEGGIE) then
        return i
      end
    end
  end
end

BeefaloKeybindsFuncs = {

IsInGameplay = function()
  return ThePlayer ~= nil and TheFrontEnd:GetActiveScreen().name == "HUD"
  and not ThePlayer.HUD:IsCraftingOpen()
  and not ThePlayer.HUD:HasInputFocus()
end,

MountOrDis = function()
  local beefalo = FindBeefalo()
  if beefalo ~= nil then
    local controller = ThePlayer.components.playercontroller
    if not ThePlayer.replica.rider:IsRiding() then
      local act = BufferedAction(ThePlayer, beefalo, ACTIONS.MOUNT, nil)

      -- Debug print BufferedAction
      -- Investigation: compared to the one generated just by manual right clicking, this is exactly the same???
      --   how is there the action getting stuck bug then
      --[[
      local inspect = require "inspect"
      local act_doer = act.doer
      local act_t = act.target
      act.doer = nil
      act.target = nil
      print(inspect(act, 4))
      act.doer = act_doer
      act.target = act_t
      --]]

      local pos = act:GetActionPoint() or ThePlayer:GetPosition()
      SendRPCToServer(RPC.RightClick, act.action.code, pos.x, pos.z, act.target, act.rotation, true, nil, nil, act.action.mod_name);
      -- TODO(rtk0c) 2024-05-13 6:42PM
      --             commenting this out, i.e. only start action on server, but don't play pre-action animation, solves the Movement Predication bug
      --             how tf does this work???
      -- controller:DoAction(act)
    else
      local act2 = BufferedAction(ThePlayer, ThePlayer, ACTIONS.DISMOUNT)
      local pos = act2:GetActionPoint() or ThePlayer:GetPosition()
      SendRPCToServer(RPC.RightClick, act2.action.code, pos.x, pos.z, act2.target, act2.rotation, true, nil, nil, act2.action.mod_name)
      controller:DoAction(act2)
    end
  end
end,

Feed = function()
  local food = FindFood()
  local beefalo = FindBeefalo()
  if food ~= nil and beefalo ~= nil then
    local act = BufferedAction(ThePlayer, beefalo, ACTIONS.GIVE, food)
    local pos = act:GetActionPoint() or ThePlayer:GetPosition()
    SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, food, act.target, act.action.mod_name)
    ThePlayer.components.playercontroller:DoAction(act)
  end
end,

}
