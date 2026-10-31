require("GamePlay/FightFramework/RoleTarget/RoleTargetId")
RoleTargetManager = {}
local targetMonsterSelected = {}
local targetPlayerSelected = {}
local this = RoleTargetManager
local lookUpRoleTarget = {}

local function SortRole(a, b)
  return a.tempPathFindingDistance < b.tempPathFindingDistance
end

local BESTRARE = 1000
local MIDDLERARE = 500
local LOWRARE = 100

local function GetRareByMonsterType(monsterType)
  if monsterType == MonsterType.goldBoss then
    return BESTRARE
  elseif monsterType == MonsterType.littleMonster then
    return LOWRARE
  else
    return MIDDLERARE
  end
end

local function AutoFightSortRole(a, b)
  local rareA = GetRareByMonsterType(a.monsterType)
  local rareB = GetRareByMonsterType(b.monsterType)
  if rareA ~= rareB then
    return rareA > rareB
  else
    return a.tempPathFindingDistance < b.tempPathFindingDistance
  end
end

local function IsSummonOrFriendly(role)
  if not role then return true end
  local isSummon = role.isSummon or (role.data and role.data.isSummon) or false
  local ownerId = role.ownerId or (role.data and role.data.ownerId) or role.masterId or (role.data and role.data.master) or 0
  if isSummon or (ownerId ~= 0 and ownerId ~= nil) then
    return true
  end
  if role.IsSameCamp and role:IsSameCamp() then
    return true
  end
  if role.data and role.data.campId and role.data.campId ~= 0 and ViewData and ViewData.meData then
    if role.data.campId == ViewData.meData.unionId or (ViewData.meData.campId ~= nil and role.data.campId == ViewData.meData.campId) then
      return true
    end
  end
  return false
end

function RoleTargetManager.IsCanAttackMonster(role)
  if not role or role.isDead then
    return false
  end
  local isSummon = role.isSummon or (role.data and role.data.isSummon) or false
  local ownerId = role.ownerId or (role.data and role.data.ownerId) or role.masterId or (role.data and role.data.master) or 0
  if isSummon or (ownerId ~= 0 and ownerId ~= nil) then
    return false
  end
  if RoleManager.me.level <= QiJiHelperData.limitSelectMonsterLevel and not role:IsBoss() and role.owner ~= 0 and role.owner ~= RoleManager.me.id then
    return false
  end
  if role.IsSameCamp and role:IsSameCamp() then
    return false
  end
  if role.data then
    if role.data.status ~= 100 then
      if role.data.campId ~= 0 and (role.data.campId == ViewData.meData.unionId or (ViewData.meData.campId ~= nil and role.data.campId == ViewData.meData.campId)) then
        return false
      end
    else
      return false
    end
  end
  return true
end

function RoleTargetManager.IsCanAttackPlayer(role)
  if not role or role.isDead then
    return false
  end
  if role.RoleType ~= ERoleType.Player then
    return true
  end
  local limitDay = ClientTable.cfg_Global_globalManager:GetGlobalItemEffect(2110012)
  local limitLevel = tonumber(ClientTable.cfg_Global_globalManager:GetGlobalItemEffect(2110013))
  if ConditionManager.Check4D(limitDay) and limitLevel <= RoleManager.me.level and limitLevel > role.level and role.PKMode == ERolePkMode.Peace then
    return false
  end
  return true
end

function RoleTargetManager.GetCanAttackRole(role)
  if not role or role.isDead then
    return false
  end
  if role:IsCurSafeZone() then
    return false
  end
  if role.RoleType == ERoleType.Monster then
    return this.IsCanAttackMonster(role)
  elseif role.RoleType == ERoleType.Player then
    return this.IsCanAttackPlayer(role) and RoleUtility.TargetIsFitMyPkMode(role)
  end
  return true
end

function RoleTargetManager.GetCanAttackRoleOnHookTime(role)
  if not role or role.isDead then
    return false
  end
  if role:IsCurSafeZone() then
    return false
  end
  if role.RoleType == ERoleType.Monster then
    return this.IsCanAttackMonster(role) and not role:IsBoss()
  elseif role.RoleType == ERoleType.Player then
    return false
  end
  return true
end

function RoleTargetManager.GetNearestMonsterTarget(isChangeTarget, range)
  range = range or GameInitData.selectTargetDistance
  local monsters = RoleManager.GetRolesByTypeAndRangeAlive(ERoleType.Monster, range, this.GetCanAttackRole)
  table.sort(monsters, SortRole)
  if 0 < #monsters then
    if isChangeTarget then
      for i = 1, #monsters do
        if not table.contains(targetMonsterSelected, monsters[i].id) and not IsSummonOrFriendly(monsters[i]) then
          table.insert(targetMonsterSelected, monsters[i].id)
          return monsters[i]
        end
      end
      targetMonsterSelected = {}
      table.insert(targetMonsterSelected, monsters[1].id)
    end
    local index = 1
    while monsters[index] and IsSummonOrFriendly(monsters[index]) do
      index = index + 1
    end
    return monsters[index]
  else
    return nil
  end
end

function RoleTargetManager.GetNearestPlayerTarget(isChangeTarget, range)
  range = range or GameInitData.selectTargetDistance
  local players = RoleManager.GetRolesByTypeAndRangeAlive(ERoleType.Player, range, this.GetCanAttackRole)
  table.sort(players, SortRole)
  if 0 < #players then
    if isChangeTarget then
      for i = 1, #players do
        if not table.contains(targetPlayerSelected, players[i].id) and players[i]:IsCanSelect() == true then
          table.insert(targetPlayerSelected, players[i].id)
          return players[i]
        end
      end
      targetPlayerSelected = {}
      table.insert(targetPlayerSelected, players[1].id)
    end
    if players[1] ~= nil and players[1]:IsCanSelect() == false then
      return nil
    end
    return players[1]
  else
    return nil
  end
end

function RoleTargetManager.SelectPlayerTarget(playerID, range)
  range = range or GameInitData.selectTargetDistance
  local players = RoleManager.GetRolesByTypeAndRangeAlive(ERoleType.Player, range, this.GetCanAttackRole)
  if players ~= nil then
    for i = 1, #players do
      if players[i] ~= nil and players[i].id == playerID then
        RoleTargetManager.ClearSelectMonsterTarget()
        RoleManager.me:SetTarget(players[i])
        return true
      end
    end
  end
  return false
end

function RoleTargetManager.SetLookUpMonsterFunc(id, lookMonsterFunc, priority)
  for k, v in ipairs(lookUpRoleTarget) do
    if v[1] and id == v[1] then
      return
    end
  end
  priority = priority or 0
  local index
  for k, v in ipairs(lookUpRoleTarget) do
    if v[3] and priority < v[3] then
      index = k
      break
    end
  end
  table.insert(lookUpRoleTarget, index or #lookUpRoleTarget + 1, {
    id,
    lookMonsterFunc,
    priority
  })
end

function RoleTargetManager.RemoveLookUpMonsterFunc(id)
  local index
  for k, v in ipairs(lookUpRoleTarget) do
    if id == v[1] then
      index = k
      break
    end
  end
  if not index then
  else
    table.remove(lookUpRoleTarget, index)
  end
end

function RoleTargetManager.IsHasLookUpTargetFunc()
  return 0 < #lookUpRoleTarget
end

function RoleTargetManager.IsMoreThanHightestPriority(priority)
  local hightestPriority = 0
  for k, v in ipairs(lookUpRoleTarget) do
    if hightestPriority < v[3] then
      hightestPriority = v[3]
    end
  end
  return priority > hightestPriority
end

function RoleTargetManager.LookUpMonsterFunc()
  local selectMonster
  for k, v in ipairs(lookUpRoleTarget) do
    selectMonster = v[2]()
    if selectMonster then
      return selectMonster, v[3]
    end
  end
end

function RoleTargetManager.GetMonsterUnderRules()
  local selectMonster, priority
  selectMonster, priority = this.LookUpMonsterFunc()
  if not selectMonster then
    selectMonster = this.GetMostRareMonsterTarget(false, QiJiHelperData.SettingData.KillMonsterScope, this.GetCanAttackRole)
    priority = 1
  end
  return selectMonster, priority
end

function RoleTargetManager.GetMostRareMonsterTarget(isChangeTarget, distance, confirmCallback, tblSkill)
  local SkillAdditionValue = 0
  if not table.isNullOrEmpty(tblSkill) then
    SkillAdditionValue = gameMgr:GetAvatarManager():GetMainPlayer():GetSkillManager():GetSKillGroupAdditionManager():GetSkillAdditionValueFormId(tblSkill.id, ESkillGroupAdditionType.RANGE)
  end
  distance = distance or GameInitData.selectTargetDistance + SkillAdditionValue
  confirmCallback = confirmCallback or this.GetCanAttackRole
  local monsters = RoleManager.GetRolesByTypeAndRangeAlive(ERoleType.Monster, distance, confirmCallback)
  table.sort(monsters, AutoFightSortRole)
  if 0 < #monsters then
    if isChangeTarget then
      for i = 1, #monsters do
        if not table.contains(targetMonsterSelected, monsters[i].id) and not IsSummonOrFriendly(monsters[i]) then
          table.insert(targetMonsterSelected, monsters[i].id)
          return monsters[i]
        end
      end
      targetMonsterSelected = {}
      table.insert(targetMonsterSelected, monsters[1].id)
    end
    local index = 1
    while monsters[index] and IsSummonOrFriendly(monsters[index]) do
      index = index + 1
    end
    return monsters[index]
  else
    return nil
  end
end

function RoleTargetManager.GetMostRareMonsterTargetOnHook()
  local distance = 6
  local monsters = RoleManager.GetRolesByTypeAndRangeAlive(ERoleType.Monster, distance, this.GetCanAttackRoleOnHookTime)
  table.sort(monsters, AutoFightSortRole)
  if 0 < #monsters then
    local index = 1
    while monsters[index] and IsSummonOrFriendly(monsters[index]) do
      index = index + 1
    end
    return monsters[index]
  else
    return nil
  end
end

function RoleTargetManager.GetPlayerTarget(isChangeTarget, distance, confirmCallback)
  distance = distance or GameInitData.selectTargetDistance
  confirmCallback = confirmCallback or this.GetCanAttackRole
  local players = RoleManager.GetRolesByTypeAndRangeAlive(ERoleType.Player, distance, confirmCallback)
  if 0 < #players then
    if isChangeTarget then
      for i = 1, #players do
        if not table.contains(targetPlayerSelected, players[i].id) then
          table.insert(targetPlayerSelected, players[i].id)
          return players[i]
        end
      end
      targetPlayerSelected = {}
      table.insert(targetPlayerSelected, players[1].id)
    end
    local index = 1
    return players[index]
  else
    return nil
  end
end

function RoleTargetManager.GetNearestMonsterTargetInLimitDistance(isChangeTarget, distance)
  local monsters = RoleManager.GetRolesByTypeAndRangeAlive(ERoleType.Monster, distance, this.GetCanAttackRole)
  table.sort(monsters, SortRole)
  if 0 < #monsters then
    if isChangeTarget then
      for i = 1, #monsters do
        if not table.contains(targetMonsterSelected, monsters[i].id) and not IsSummonOrFriendly(monsters[i]) then
          table.insert(targetMonsterSelected, monsters[i].id)
          return monsters[i]
        end
      end
      targetMonsterSelected = {}
      table.insert(targetMonsterSelected, monsters[1].id)
    end
    local index = 1
    while monsters[index] and IsSummonOrFriendly(monsters[index]) do
      index = index + 1
    end
    return monsters[index]
  else
    return nil
  end
end

function RoleTargetManager.GetTargetToAttack(role)
  if CS.Game.NavMesh.NavMeshPathFinding.Instance ~= nil then
    local paths, distance = CS.Game.NavMesh.NavMeshPathFinding.Instance:SeekPath(RoleManager.me.pos, role.pos)
    if paths.Length > 2 then
      local pos = paths[paths.Length - 2]
      return true, pos
    end
  end
  return false, role.pos
end

function RoleTargetManager.GetRoleTarget(distance, tblSkill)
  local player = this.GetPlayerTarget(false, distance)
  if not player then
    local monster = this.GetMostRareMonsterTarget(false, distance, nil, tblSkill)
    return monster
  else
    return player
  end
end

function RoleTargetManager.IsTargetHasBuff(role, buffStr, buffSkillAuto)
  if buffSkillAuto == 1 then
    return true
  end
  if not role then
    return true
  end
  if buffStr == "" then
    return true
  end
  local buffIds = string.split(buffStr, "#")
  local res = false
  for i = 1, #buffIds do
    if not BuffData.IsHasBuff(role.id, tonumber(buffIds[i])) then
      res = true
    end
  end
  return res
end

function RoleTargetManager.IsTargetNotHasBuff(role, buffStr)
  if not role then
    return true
  end
  if buffStr == "" then
    return true
  end
  local buffIds = string.split(buffStr, "#")
  local res = true
  for i = 1, #buffIds do
    if not BuffData.IsHasBuff(role.id, tonumber(buffIds[i])) then
      res = false
    end
  end
  return res
end

function RoleTargetManager.ClearSelectMonsterTarget()
  targetMonsterSelected = {}
end

function RoleTargetManager.ClearSelectPlayerTarget()
  targetPlayerSelected = {}
end
