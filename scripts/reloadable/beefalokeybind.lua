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

function EXPORTS.IsInGameplay()
  return ThePlayer ~= nil and TheFrontEnd:GetActiveScreen().name == "HUD"
  and not ThePlayer.HUD:IsCraftingOpen()
  and not ThePlayer.HUD:HasInputFocus()
end

function EXPORTS.MountOrDis()
  local beefalo = FindBeefalo()
  if beefalo ~= nil then
    local controller = ThePlayer.components.playercontroller
    if not ThePlayer.replica.rider:IsRiding() then
      local act = BufferedAction(ThePlayer, beefalo, ACTIONS.MOUNT, nil)
      local pos = act:GetActionPoint() or ThePlayer:GetPosition()

      -- It appears that PlayerController.locomotor exists when movement prediction is one, and nil when it is off.
      -- According to vanilla's code, when movement prediction is on, the action RPC needs to be one frame later than the movement prediction RPC.
      --
      --[[ scripts/components/playercontroller.lua
function PlayerController:RemoteBufferedAction(buffaction)
  if not self.ismastersim and buffaction.preview_cb ~= nil then
    --Delay one frame if we just sent movement prediction so that
    --this RPC arrives a frame after the movement prediction RPC
    if self.predictionsent then
        self.inst:DoTaskInTime(0, DoRemoteBufferedAction, self, buffaction)
    else
        DoRemoteBufferedAction(self.inst, self, buffaction)
    end
  end
end
      --]]
      --
      -- Vanilla does this delay by putting the SendRPCToServer() call into a callback stored in BufferedAction.preview_cb. This callback is processed somewhere down the chain, and it will finally reach PlayerControll:RemoteBufferedAction() above.
      -- See relevant code at the bottom of PlayerController:OnRightClick()
      if controller.locomotor == nil then
        SendRPCToServer(RPC.RightClick, act.action.code, pos.x, pos.z, act.target, act.rotation, true, nil, nil, act.action.mod_name)
      else
        act.preview_cb = function()
          SendRPCToServer(RPC.RightClick, act.action.code, pos.x, pos.z, act.target, act.rotation, true, nil, nil, act.action.mod_name)
        end
      end
      controller:DoAction(act)
    else
      local act2 = BufferedAction(ThePlayer, ThePlayer, ACTIONS.DISMOUNT)
      local pos = act2:GetActionPoint() or ThePlayer:GetPosition()
      SendRPCToServer(RPC.RightClick, act2.action.code, pos.x, pos.z, act2.target, act2.rotation, true, nil, nil, act2.action.mod_name)
      controller:DoAction(act2)
    end
  end
end

function EXPORTS.Feed()
  local food = FindFood()
  local beefalo = FindBeefalo()
  if food ~= nil and beefalo ~= nil then
    local act = BufferedAction(ThePlayer, beefalo, ACTIONS.GIVE, food)
    local pos = act:GetActionPoint() or ThePlayer:GetPosition()
    SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, act.action.code, food, act.target, act.action.mod_name)
    ThePlayer.components.playercontroller:DoAction(act)
  end
end
