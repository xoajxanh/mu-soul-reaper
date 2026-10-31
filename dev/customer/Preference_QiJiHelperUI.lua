Preference_QiJiHelperUI = class(BaseUI)
Preference_QiJiHelperUI.layer = UILayer.Panel
Preference_QiJiHelperUI.orderInLayer = 6
Preference_QiJiHelperUI.hideType = UIHideType.Destroy
Preference_QiJiHelperUI.hideFunc = UIHideFunc.MoveOutOfScreen
Preference_QiJiHelperUI.escClose = UIEscClose.DontClose

function Preference_QiJiHelperUI:InitControls()
  self.btn_closeBg = self:GetControl("btn_closeBg")
  self.btn_Close = self:GetControl("bg/btn_Close")
  self.tog_KillMonster = self:GetControl("bg/go_Tabs/tog_KillMonster")
  self.tog_Collect = self:GetControl("bg/go_Tabs/tog_Collect")
  self.go_KillMonster = self:GetControl("bg/go_KillMonster")
  self.ScrollView = self:GetControl("bg/go_KillMonster/ScrollView")
  self.tog_StrikeBack = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/BaseSet/tog_StrikeBack")
  self.tog_Return = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/BaseSet/tog_Return")
  self.InputField = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/BaseSet/tog_Return/InputField")
  self.tog_AutoTreat = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/BaseSet/tog_AutoTreat")
  self.ExpUp = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/ExpUp")
  self.go_ExpUpItem = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/ExpUp/ScrollView/Viewport/Content/go_ExpUpItem")
  self.go_DamageSkillSet = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/go_DamageSkillSet")
  self.Img_SingleSkillBg = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/go_DamageSkillSet/Img_SingleSkillBg")
  self.Img_SingleSkillIcon = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/go_DamageSkillSet/Img_SingleSkillBg/Img_SingleSkillIcon")
  self.Img_DoubleSkillBg = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/go_DamageSkillSet/Img_DoubleSkillBg")
  self.Img_DoubleSkillIcon = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/go_DamageSkillSet/Img_DoubleSkillBg/Img_DoubleSkillIcon")
  self.Img_SelfSelectSkillBg = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/go_DamageSkillSet/Img_SelfSelectSkillBg")
  self.go_SkillSet = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/go_SkillSet")
  self.Img_autoFightSkillBg = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/go_SkillSet/go_SkillSet/Img_autoFightSkillBg")
  self.go_SummonSkillSet = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/go_SummonSkillSet")
  self.Img_SummonSkillBg = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/go_SummonSkillSet/Img_SummonSkillBg")
  self.Img_SummonSkillIcon = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/go_SummonSkillSet/Img_SummonSkillBg/Img_SummonSkillIcon")
  self.go_BUFFSkillSet = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/go_BUFFSkillSet")
  self.Img_BUFFSkillBg = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/go_BUFFSkillSet/go_BUFFSkillGroup/Img_BUFFSkillBg")
  self.Img_BUFFSkillBg = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/go_BUFFSkillSet/go_BUFFSkillGroup/Img_BUFFSkillBg")
  self.sv_SelectSkill = self:GetControl("bg/go_KillMonster/sv_SelectSkill")
  self.img_SkillFrame = self:GetControl("bg/go_KillMonster/sv_SelectSkill/Viewport/Content/img_SkillFrame")
  self.lab_hpThreshold = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/AutoUseItem/lab_hpFloor/lab_hpThreshold")
  self.sl_hpThreshold = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/AutoUseItem/lab_hpFloor/sl_hpThreshold")
  self.lab_mpFloor = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/AutoUseItem/lab_mpFloor")
  self.lab_mpThreshold = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/AutoUseItem/lab_mpFloor/lab_mpThreshold")
  self.sl_mpThreshold = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/AutoUseItem/lab_mpFloor/sl_mpThreshold")
  self.btn_resetAutoFight = self:GetControl("bg/go_KillMonster/btn_resetAutoFight")
  self.go_Collect = self:GetControl("bg/go_Collect")
  self.tog_all = self:GetControl("bg/go_Collect/go_autoPickup/tog_all")
  self.tog_select = self:GetControl("bg/go_Collect/go_autoPickup/tog_select")
  self.tog_gem = self:GetControl("bg/go_Collect/go_autoPickup/tog_gem")
  self.tog_greyishWhiteEquip = self:GetControl("bg/go_Collect/go_autoPickup/tog_greyishWhiteEquip")
  self.tog_skillBook = self:GetControl("bg/go_Collect/go_autoPickup/tog_skillBook")
  self.tog_orangeEquip = self:GetControl("bg/go_Collect/go_autoPickup/tog_orangeEquip")
  self.tog_gold = self:GetControl("bg/go_Collect/go_autoPickup/tog_gold")
  self.tog_blueEquip = self:GetControl("bg/go_Collect/go_autoPickup/tog_blueEquip")
  self.tog_diamond = self:GetControl("bg/go_Collect/go_autoPickup/tog_diamond")
  self.tog_goldenEquip = self:GetControl("bg/go_Collect/go_autoPickup/tog_goldenEquip")
  self.tog_material = self:GetControl("bg/go_Collect/go_autoPickup/tog_material")
  self.tog_greenEquip = self:GetControl("bg/go_Collect/go_autoPickup/tog_greenEquip")
  self.tog_purpleEquip = self:GetControl("bg/go_Collect/go_autoPickup/tog_purpleEquip")
  self.tog_redEquip = self:GetControl("bg/go_Collect/go_autoPickup/tog_redEquip")
  self.btn_resetPickup = self:GetControl("bg/go_Collect/btn_resetPickup")
  self.descBtn = self:GetControl("bg/descBtn")
  self.lab_KillMonsterScope = self:GetControl("bg/go_KillMonster/ScrollView/Viewport/Content/KillMonsterScope/lab_KillMonsterScope")
  self.btn_autoFight = self:GetControl("bg/go_KillMonster/btn_autoFight")
end

function Preference_QiJiHelperUI:Init()
end

function Preference_QiJiHelperUI:OnCreate()
  self:InitControls()
  self:InitKillMonsterToggle()
  self:InitPickupToggle()
  self:InitUI()
  self:RegistUIEvents()
end

function Preference_QiJiHelperUI:InitKillMonsterToggle()
  self.killMonsters = {}
  for i = 1, 8 do
    self.killMonsters[#self.killMonsters + 1] = self.lab_KillMonsterScope:GetChild("Img_black_" .. i)
    self.killMonsters[#self.killMonsters].distance = i
  end
end

function Preference_QiJiHelperUI:InitPickupToggle()
  self.AutoPickUpItemControls = {
    self.tog_gem,
    self.tog_skillBook,
    self.tog_gold,
    self.tog_diamond,
    self.tog_material,
    self.tog_greyishWhiteEquip,
    self.tog_orangeEquip,
    self.tog_blueEquip,
    self.tog_goldenEquip,
    self.tog_greenEquip,
    self.tog_purpleEquip,
    self.tog_redEquip
  }
  self.tog_gem.type = EItemType.GemStone
  self.tog_skillBook.type = EItemType.SkillBook
  self.tog_gold.type = EResourcesType.gold
  self.tog_diamond.type = EResourcesType.diamond
  self.tog_material.type = EItemType.Material
  self.tog_greyishWhiteEquip.type = EItemType.Equipe
  self.tog_orangeEquip.type = EItemType.Equipe
  self.tog_blueEquip.type = EItemType.Equipe
  self.tog_goldenEquip.type = EItemType.Equipe
  self.tog_greenEquip.type = EItemType.Equipe
  self.tog_purpleEquip.type = EItemType.Equipe
  self.tog_redEquip.type = EItemType.Equipe
  self.tog_greyishWhiteEquip.rarity = "101#102"
  self.tog_orangeEquip.rarity = "103"
  self.tog_blueEquip.rarity = "104"
  self.tog_goldenEquip.rarity = "105"
  self.tog_greenEquip.rarity = "106#107"
  self.tog_purpleEquip.rarity = "109"
  self.tog_redEquip.rarity = "110"
end

function Preference_QiJiHelperUI:InitUI()
  self:BuffSkillContainerInit()
end

local function OnCreateBuffSkill(control, ui)
  control.imgIcon = UIControl(control.transform, "Img_BUFFSkillIcon")
  control.tog = UIControl(control.transform, "Tog_UseBuff")
  control.tog:SetOnToggleChanged(ui, ui.SetBuffSkillSwitch)
end

local function OnCreateSkillFrame(control, ui)
  control.imgIcon = UIControl(control.transform, "img_SkillIcon")
  control.txt = UIControl(control.transform, "txt_SkillDescribe")
  control.tog_select = UIControl(control.transform, "tog_select")
  control.tog_select:SetOnToggleChanged(ui, ui.SwitchSelfSelectSkill)
end

local function OnCreateExpFrame(control)
  control.btn_3DItem = UIControl(control.transform, "btn_3DItem")
  control.txt_ExpUpTime = UIControl(control.transform, "btn_3DItem/txt_ExpUpTime")
  control.txt_ExpUpValue = UIControl(control.transform, "btn_3DItem/txt_ExpUpValue")
  control.btn_buy = UIControl(control.transform, "btn_buy")
  control.btn_go = UIControl(control.transform, "btn_go")
  control.txt_active = UIControl(control.transform, "txt_active")
  control.img_item = UIControl(control.transform, "img_item")
  control.lab_showNum = UIControl(control.transform, "img_item/lab_showNum")
end

local function OnRefreshBuffSkill(ctr, _, buffSkillData, ui)
  local buffSkill = ClientTable.cfg_Skill_skillManager:TryGetValue(buffSkillData.id)
  ui:SetSprite("Atlas_Skill", buffSkill.icon, ctr.imgIcon)
  local isOpen = QiJiHelperData.GetBuffSkill(buffSkill.groupId).isOpen
  ctr.tog.skillId = buffSkillData.id
  ctr.tog:SetIsOn(isOpen)
end

local function OnRefreshSkillFrame(ctr, _, skillData, ui)
  local skill = ClientTable.cfg_Skill_skillManager:TryGetValue(skillData.id)
  if not skill then
    ctr.txt:SetText(ClientTable.cfg_Text_ClientManager:GetDes(333))
    ctr.skillId = 0
    ctr.tog_select.skillId = 0
    ctr.icon = nil
    ui:SetSprite("Atlas_Skill", nil, ctr.imgIcon)
    ctr.tog_select:SetActive(false)
    ctr:SetOnClick(ui, ui.SetSelfSelSkill)
    return
  else
    local itemTip = ClientTable.cfg_Item_tipsManager:TryGetValue(skill.description).content
    ui:SetSprite("Atlas_Skill", skill.icon, ctr.imgIcon)
    itemTip = SkillUtility.UpdateTips(skill, "#e6e600")
    ctr.txt:SetText(itemTip)
    ctr.skillId = skill.id
    ctr.tog_select.skillId = skill.id
    ctr.icon = skill.icon
  end
  ctr.skillType = ui.selfSelectSkillType
  if QiJiHelperData.IsGroupSkill(skillData.id) or QiJiHelperData.IsIndSkill(skillData.id) then
    ctr.tog_select:SetActive(true)
    local isOpen = QiJiHelperData.GetSelfSelSkill(skill.groupId).isOpen
    ctr.tog_select:SetIsOn(isOpen)
    ctr:SetOnClick(ui, ui.DontDoNothing)
  else
    ctr.tog_select:SetActive(false)
    ctr:SetOnClick(ui, ui.SetSelfSelSkill)
  end
end

function Preference_QiJiHelperUI:SwitchSelfSelectSkill(control)
  QiJiHelperController.SetSelfSelSkill(control.skillId, control.toggle.isOn)
end

function Preference_QiJiHelperUI:DontDoNothing(control)
end

local function OnRefreshExp(ctr, _, expData, ui)
  local itemId
  if expData.vip then
    if expData.itemId then
      if expData.itemId == 2290001 then
        itemId = 2290010
      else
        itemId = expData.itemId + 1
      end
      local itemConfig = ClientTable.cfg_Recharge_vvipManager:TryGetValue(itemId)
      if itemConfig then
        ctr.txt_active:SetText(ClientTable.cfg_Text_ClientManager:GetDes(240))
        ctr.btn_3DItem.isHideCompare = false
      else
        ctr.txt_active:SetText(ClientTable.cfg_Text_ClientManager:GetDes(523))
        ctr.btn_3DItem.isHideCompare = true
      end
      if not itemConfig then
        itemId = expData.itemId
      end
    else
      ctr.txt_active:SetText(ClientTable.cfg_Text_ClientManager:GetDes(522))
      ctr.btn_3DItem.isHideCompare = false
      itemId = 2290010
    end
    local itemConfig = ClientTable.cfg_Item_equipManager:TryGetValue(itemId)
    ctr.txt_ExpUpValue:SetText("+" .. itemConfig.experienceRate / 100 .. "%")
    ctr.btn_go:SetActive(true)
    ctr.btn_buy:SetActive(false)
    ctr.img_item:SetActive(false)
    ctr.txt_ExpUpTime:SetActive(false)
    ctr.txt_active:SetActive(true)
    ctr.img_item:GetChild("lab_showNum"):SetText("")
  else
    ctr.btn_3DItem.isHideCompare = false
    ctr.txt_active:SetActive(false)
    ctr.btn_buy:SetActive(true)
    ctr.btn_go:SetActive(false)
    ctr.img_item:SetActive(true)
    ctr.txt_ExpUpTime:SetActive(true)
    local price = string.split(expData.cost, "#")
    local reward = string.split(expData.reward, "#")
    local itemData = ItemUtility.GenerateItemData(tonumber(price[1]))
    itemData.count = nil
    if not ctr.img_item.itemCellData then
      local itemCellData = ItemCellData()
      ctr.img_item.itemCellData = itemCellData
    end
    ctr.img_item.itemCellData:RefreshData(itemData)
    ItemUtility.ShowItemCell(ctr.img_item, ctr.img_item.itemCellData, ui, true)
    ctr.lab_showNum:SetText(tonumber(price[2]))
    ctr.txt_ExpUpValue:SetText(expData.title)
    ctr.txt_ExpUpTime:SetText(TimeUtility.ShowNewTime(Mathf.Floor(ExpAddData.MultipleTime)))
    ctr.btn_buy.goodId = expData.id
    ctr.btn_buy.shop = expData
    ctr.btn_buy:SetOnClick(ui, ui.BuyExpMedicine)
    itemId = tonumber(reward[1])
  end
  local itemCellData
  local itemData = ItemUtility.GenerateItemData(itemId)
  itemData.count = nil
  if not ctr.itemCellData then
    itemCellData = ItemCellData()
    ctr.itemCellData = itemCellData
  end
  ctr.itemCellData:RefreshData(itemData)
  if expData.vip then
    ItemUtility.ShowItemCell(ctr.btn_3DItem, ctr.itemCellData, ui)
    ctr.btn_3DItem.itemData = ctr.itemCellData.itemData
    ctr.btn_3DItem:SetOnClick(ui, ui.ClickItemBtn)
    ctr.btn_go.itemData = ctr.itemCellData.itemData
    ctr.btn_go:SetOnClick(ui, ui.ClickItemBtn)
  else
    ItemUtility.ShowItemCell(ctr.btn_3DItem, ctr.itemCellData, ui, true)
  end
end

function Preference_QiJiHelperUI:BuyExpMedicine(control)
  UIManager.Show(UIID.Shop_ExpUpUI)
  UIManager.Hide(UIID.Preference_QiJiHelperUI)
end

function Preference_QiJiHelperUI:ClickItemBtn(control)
  UIManager.Show(UIID.ItemTipUI, {
    item = control.itemData,
    uiId = UIID.Recharge_VvipUI,
    hideUiId = UIID.Preference_QiJiHelperUI,
    ctrl = control,
    rightOperate = control.isHideCompare and EItemOperateType.Show or nil
  })
end

local function OnCreateAllSkillFrame(control)
  control.imgIcon = UIControl(control.transform, "Img_BUFFSkillIcon")
  control.toggle = UIControl(control.transform, "Tog_UseBuff")
  control.img_skill = UIControl(control.transform, "img_skill")
  control.skillName = UIControl(control.transform, "img_skillName_bg/skillName")
end

local function OnRefreshAllSkillFrame(ctr, _, data, ui)
  local skillConfig = ClientTable.cfg_Skill_skillManager:TryGetValue(data.skillId)
  ui:SetSprite("Atlas_Skill", skillConfig.icon, ctr.img_skill)
  ctr.skillName:SetText(skillConfig.name)
  ctr.toggle.skillId = data.skillId
  if skillConfig.autoSkillType == AutoSkillEnum.BuffSkill then
    local isOpen = QiJiHelperData.GetBuffSkill(skillConfig.groupId).isOpen
    ctr.toggle:SetIsOn(isOpen)
  else
    local isOpen = QiJiHelperData.GetSelfSelSkill(skillConfig.groupId).isOpen
    ctr.toggle:SetIsOn(isOpen)
  end
  ctr.toggle:SetOnToggleChanged(ui, ui.SetAutoFightSkill)
end

function Preference_QiJiHelperUI:BuffSkillContainerInit()
  self.buffSkillTemp = UIContainer(self.Img_BUFFSkillBg, self, OnCreateBuffSkill, OnRefreshBuffSkill)
  self.skillFrameTemp = UIContainer(self.img_SkillFrame, self, OnCreateSkillFrame, OnRefreshSkillFrame)
  self.allSkillSetTemp = UIContainer(self.Img_autoFightSkillBg, self, OnCreateAllSkillFrame, OnRefreshAllSkillFrame)
end

function Preference_QiJiHelperUI:SetAutoFightSkill(control)
  local skillConfig = ClientTable.cfg_Skill_skillManager:TryGetValue(control.skillId)
  if skillConfig.autoSkillType == AutoSkillEnum.BuffSkill then
    QiJiHelperController.SetMeBuffSkill(control.skillId, control:GetIsOn())
  else
    QiJiHelperController.SetSelfSelSkill(control.skillId, control:GetIsOn())
  end
end

function Preference_QiJiHelperUI:OnShow()
  self:RegistEvents()
  self:Refresh()
end

function Preference_QiJiHelperUI:OnHide()
  self.ScrollView:SetNormalizedPosition(1, 1)
  QiJiHelperController.Save()
end

function Preference_QiJiHelperUI:OnDestroy()
end

function Preference_QiJiHelperUI:RegistUIEvents()
  self.btn_closeBg:SetOnClick(self, self.btn_CloseOnClick)
  self.btn_Close:SetOnClick(self, self.btn_CloseOnClick)
  self.Img_SingleSkillBg:SetOnClick(self, self.UpdateSingleSkill)
  self.Img_DoubleSkillBg:SetOnClick(self, self.UpdateDoubleSkill)
  self.Img_SelfSelectSkillBg:SetOnClick(self, self.ShowSelectSkill)
  self.Img_SummonSkillBg:SetOnClick(self, self.UpdateSummonSkill)
  self.btn_resetAutoFight:SetOnClick(self, self.ResetAutoFight)
  self.btn_resetPickup:SetOnClick(self, self.ResetPickup)
  self.tog_KillMonster:SetOnToggleChanged(self, self.ShowPreferenceUI)
  self.tog_Collect:SetOnToggleChanged(self, self.ShowPreferenceUI)
  self.tog_StrikeBack:SetOnToggleChanged(self, self.SetStrikeBack)
  self.tog_Return:SetOnToggleChanged(self, self.SetReturnHome)
  self.tog_AutoTreat:SetOnToggleChanged(self, self.SetAutoTreat)
  self.InputField:SetOnEndEdit(self, self.SetReturnHomeTime)
  self.sl_hpThreshold:SetOnSliderValueChanged(self, self.UpdateHpValueChange)
  self.sl_mpThreshold:SetOnSliderValueChanged(self, self.UpdateMpValueChange)
  self.tog_all:SetOnToggleChanged(self, self.SelectAllPickup)
  self.tog_select:SetOnToggleChanged(self, self.SelectPartPickup)
  self.descBtn:SetOnClick(self, self.ShowDescPanel)
  self.btn_autoFight:SetOnClick(self, self.OpenAutoFight)
  for i = 1, #self.AutoPickUpItemControls do
    self.AutoPickUpItemControls[i]:SetOnToggleChanged(self, self.PickUpTogOnValueChanged)
  end
  for i = 1, #self.killMonsters do
    self.killMonsters[i]:SetOnToggleChanged(self, self.SetKillMonsterDistance)
  end
end

function Preference_QiJiHelperUI:OpenAutoFight(control)
  if QiJiHelperData.isAutoFight then
    FloatingWordUtility.QuickMsg(ClientTable.cfg_Text_ClientManager:GetDes(722))
  else
    QiJiHelperData.openReturnHome = true
    RoleManager.me:SetAutoFight(AutoFightStrKey.AutoFight)
    UIManager.Hide(UIID.Preference_QiJiHelperUI)
  end
end

function Preference_QiJiHelperUI:ShowDescPanel(control)
  local lvCfg = ConfigManager.FindConfigs("cfg_Ui_description", "uiName", "Preference_QiJiHelperUI")
  UIManager.Show(UIID.System_DescUI, {
    id = lvCfg[1].id
  })
end

local blackColor = "0x8A8A8AFF"
local whiteColor = "0xFFFFFFFF"

function Preference_QiJiHelperUI:SetKillMonsterDistance(control)
  control:SetColor(control:GetIsOn() and whiteColor or blackColor)
  QiJiHelperController.SetSkillMonsterRange(control.distance)
end

function Preference_QiJiHelperUI:btn_CloseOnClick(control)
  UIManager.Hide(UIID.Preference_QiJiHelperUI)
end

function Preference_QiJiHelperUI:ShowPreferenceUI(control)
  if not control.toggle.isOn then
    return
  end
  self.go_KillMonster:SetActive(self.tog_KillMonster.toggle.isOn)
  self.go_Collect:SetActive(self.tog_Collect.toggle.isOn)
end

function Preference_QiJiHelperUI:SetBuffSkillSwitch(control)
  QiJiHelperController.SetMeBuffSkill(control.skillId, control.toggle.isOn)
end

function Preference_QiJiHelperUI:SetStrikeBack(control)
  QiJiHelperController.SetSTrikeBack(control.toggle.isOn)
end

function Preference_QiJiHelperUI:SetReturnHome(control)
  QiJiHelperController.SetReturnHome(control.toggle.isOn)
  self:SetInputTextInteract(control.toggle.isOn)
end

function Preference_QiJiHelperUI:SetInputTextInteract(isOn)
  self.InputField:SetInteractable(isOn)
end

function Preference_QiJiHelperUI:SetReturnHomeTime(control)
  if control:GetInputText() == "" then
    QiJiHelperController.SetReturnHomeTime(10)
  else
    QiJiHelperController.SetReturnHomeTime(tonumber(control:GetInputText()))
  end
end

function Preference_QiJiHelperUI:SetAutoTreat(control)
  QiJiHelperController.SetAutoTreat(control.toggle.isOn)
end

function Preference_QiJiHelperUI:UpdateSingleSkill(control)
end

function Preference_QiJiHelperUI:UpdateDoubleSkill(control)
end

function Preference_QiJiHelperUI:ShowSelectSkill(control)
  self.showSkillType = "allDamage"
  BlockerUtility.Show(self.sv_SelectSkill)
  self:RefreshAllSelfSelSkill()
end

function Preference_QiJiHelperUI:UpdateSummonSkill(control)
  self.showSkillType = "summon"
  BlockerUtility.Show(self.sv_SelectSkill)
  self.selfSelectSkillType = AutoSkillEnum.SummonSkill
  self:RefreshSelfSelSkill(AutoSkillEnum.SummonSkill)
end

function Preference_QiJiHelperUI:SetSelfSelSkill(control)
  if control.skillType == AutoSkillEnum.SelfSelIndSkill then
    QiJiHelperController.SetSelfSelIndSkill(control.skillId)
    self:SetSprite("Atlas_Skill", control.icon, self.Img_SingleSkillIcon)
  elseif control.skillType == AutoSkillEnum.SelfSelGroupSkill then
    QiJiHelperController.SetSelfSelfGroupSkill(control.skillId)
    self:SetSprite("Atlas_Skill", control.icon, self.Img_DoubleSkillIcon)
  else
    QiJiHelperController.SetSummonSkill(control.skillId)
    self:SetSprite("Atlas_Skill", control.icon, self.Img_SummonSkillIcon)
  end
  BlockerUtility.Hide()
end

function Preference_QiJiHelperUI:UpdateHpValueChange(control)
  local value = control:GetValue()
  value = Mathf.Floor(value * 100 + 0.5) / 100
  local num, b = math.modf(value * 100)
  local valueStr = string.format("%s%s", num, "%")
  self.lab_hpThreshold:SetText(valueStr)
  QiJiHelperController.SetAutoRecoverHp(value)
end

function Preference_QiJiHelperUI:UpdateMpValueChange(control)
  local value = control:GetValue()
  value = Mathf.Floor(value * 100 + 0.5) / 100
  local num, b = math.modf(value * 100)
  local valueStr = string.format("%s%s", num, "%")
  self.lab_mpThreshold:SetText(valueStr)
  QiJiHelperController.SetAutoRecoverMp(value)
end

function Preference_QiJiHelperUI:SelectAllPickup(control)
  if not control.toggle.isOn then
    return
  end
  QiJiHelperController.SetAutoPickupType(AutoPickupEnum.SelectAll)
  for i = 1, #self.AutoPickUpItemControls do
    self.AutoPickUpItemControls[i]:SetInteractable(false)
  end
end

function Preference_QiJiHelperUI:SelectPartPickup(control)
  if not control.toggle.isOn then
    return
  end
  QiJiHelperController.SetAutoPickupType(AutoPickupEnum.SelectPart)
  for i = 1, #self.AutoPickUpItemControls do
    self.AutoPickUpItemControls[i]:SetInteractable(true)
  end
end

function Preference_QiJiHelperUI:PickUpTogOnValueChanged(control)
  QiJiHelperController.SetCantPickupType(control.toggle.isOn, control.type, control.rarity)
  EventManager.Dispatch(Event.QiJiHelper_SetAutoPickup)
end

function Preference_QiJiHelperUI:ResetAutoFight(control)
end

function Preference_QiJiHelperUI:ResetPickup(control)
  QiJiHelperController.SetDefaultAutoPickup()
  self:RefreshPickupType()
end

function Preference_QiJiHelperUI:RegistEvents()
  self:RegistEvent(Event.Role_RefreshMultipleUI, self.SetMultiple, self)
  self:RegistEvent(Event.Skill_SkillRedPoint, self.RefreshLearnSkill, self)
end

function Preference_QiJiHelperUI:SetMultiple()
end

function Preference_QiJiHelperUI:RefreshLearnSkill()
  if self.showSkillType == "summon" then
    self:RefreshSelfSelSkill(AutoSkillEnum.SummonSkill)
  elseif self.showSkillType == "allDamage" then
    self:RefreshAutoFightSkill()
  end
end

function Preference_QiJiHelperUI:Refresh()
  self.showSkillType = ""
  self:RefreshUIByCareer()
  self:RefreshBasic()
  if RoleUtility.GetBasicCareer(RoleManager.me.career) == ERoleCareer.Magic then
    self:RefreshDamageSkill()
  elseif RoleUtility.GetBasicCareer(RoleManager.me.career) == ERoleCareer.Archer then
    self:RefreshSummonSkill()
  elseif RoleUtility.GetBasicCareer(RoleManager.me.career) == ERoleCareer.SwordMan then
    self:RefreshSingleSkill()
  end
  self:RefreshAutoFightSkill()
  self:RefreshHpAndMp()
  self:RefreshPickupType()
  NetManager.Send(UnitMessage.ReqUnitState, {
    type = UnitType.ThreeExp
  })
end

function Preference_QiJiHelperUI:RefreshAutoFightSkill()
  local skills = {}
  for i, v in pairs(RoleManager.me.skills) do
    local skillData = ClientTable.cfg_Skill_skillManager:TryGetValue(v.sid)
    if skillData.autoSkillType == AutoSkillEnum.SelfSelIndSkill or skillData.autoSkillType == AutoSkillEnum.SelfSelGroupSkill or skillData.autoSkillType == AutoSkillEnum.CommonSkill or skillData.autoSkillType == AutoSkillEnum.BuffSkill then
      skills[#skills + 1] = {
        skillId = v.sid
      }
    end
  end
  self.allSkillSetTemp:SetData(skills)
  if #skills == 0 then
  else
    local height = 130
    local multiple = Mathf.Ceil(#skills / 3)
    self.go_SkillSet:SetSizeDelta(366, 200 + (multiple - 1) * height + 30)
  end
end

function Preference_QiJiHelperUI:RefreshExpUp()
  local expList = ConfigManager.FindConfigs("cfg_Item_buy", "type", 14)
  local itemId = tonumber(ClientTable.cfg_Global_globalManager:GetGlobalItemEffect(2210105))
  for k, v in pairs(expList) do
    local reward = string.split(v.reward, "#")
    if tonumber(reward[1]) ~= itemId then
      expList[k] = nil
    end
  end
  local resExpList = {}
  for i, v in pairs(expList) do
    table.insert(resExpList, v)
  end
  local vipData = {
    vip = true,
    itemId = CommercializeData.GetVvipRechargeItemId()
  }
  table.insert(resExpList, vipData)
end

function Preference_QiJiHelperUI:RefreshUIByCareer()
  if RoleUtility.GetBasicCareer(RoleManager.me.career) == ERoleCareer.Magic then
    self.go_SummonSkillSet:SetActive(false)
  elseif RoleUtility.GetBasicCareer(RoleManager.me.career) == ERoleCareer.Archer then
    self.go_SummonSkillSet:SetActive(true)
  elseif RoleUtility.GetBasicCareer(RoleManager.me.career) == ERoleCareer.SwordMan then
    self.go_SummonSkillSet:SetActive(false)
  else
    self.go_SummonSkillSet:SetActive(false)
  end
end

function Preference_QiJiHelperUI:RefreshBasic()
  local scope = QiJiHelperData.SettingData.KillMonsterScope
  if scope > 8 then scope = 8 end
  if scope < 1 then scope = 1 end
  self.killMonsters[scope].toggle.isOn = true
  self.tog_StrikeBack.toggle.isOn = QiJiHelperData.SettingData.StrikeBack
  self.tog_Return.toggle.isOn = QiJiHelperData.SettingData.ReturnHome.IsReturn
  self.InputField:SetInputText(QiJiHelperData.SettingData.ReturnHome.ReturnTime)
  self.tog_AutoTreat.toggle.isOn = QiJiHelperData.SettingData.AutoTreat
end

function Preference_QiJiHelperUI:RefreshDamageSkill()
end

function Preference_QiJiHelperUI:RefreshSingleSkill()
end

function Preference_QiJiHelperUI:RefreshSummonSkill()
  local summonSkillData = ClientTable.cfg_Skill_skillManager:TryGetValue(QiJiHelperData.SettingData.selfSelSummonSkill)
  if summonSkillData then
    self.Img_SummonSkillIcon:SetActive(true)
    self:SetSprite("Atlas_Skill", summonSkillData.icon, self.Img_SummonSkillIcon)
  else
    self.Img_SummonSkillIcon:SetActive(false)
  end
end

function Preference_QiJiHelperUI:RefreshBuffSkill()
  local buffSkillData = {}
  for i, v in pairs(RoleManager.me.skills) do
    local skillData = ClientTable.cfg_Skill_skillManager:TryGetValue(v.sid)
    if skillData.autoSkillType == AutoSkillEnum.BuffSkill then
      buffSkillData[#buffSkillData + 1] = {
        id = v.sid
      }
    end
  end
  if #buffSkillData == 0 then
    self.go_BUFFSkillSet:SetActive(false)
  else
    self.go_BUFFSkillSet:SetActive(true)
    local height = 150
    local multiple = Mathf.Ceil(#buffSkillData / 3)
    self.go_BUFFSkillSet:SetSizeDelta(366, multiple * height + 10)
  end
  self.buffSkillTemp:SetData(buffSkillData)
end

function Preference_QiJiHelperUI:RefreshSelfSelSkill(skillType)
  local skills = {}
  for i, v in pairs(RoleManager.me.skills) do
    local skillData = ClientTable.cfg_Skill_skillManager:TryGetValue(v.sid)
    if skillData.autoSkillType == skillType then
      skills[#skills + 1] = {
        id = v.sid
      }
    end
  end
  skills[#skills + 1] = {id = 0}
  self.skillFrameTemp:SetData(skills)
end

function Preference_QiJiHelperUI:RefreshAllSelfSelSkill()
  local skills = {}
  for i, v in pairs(RoleManager.me.skills) do
    local skillData = ClientTable.cfg_Skill_skillManager:TryGetValue(v.sid)
    if skillData.autoSkillType == AutoSkillEnum.SelfSelIndSkill or skillData.autoSkillType == AutoSkillEnum.SelfSelGroupSkill or skillData.autoSkillType == AutoSkillEnum.CommonSkill then
      skills[#skills + 1] = {
        id = v.sid
      }
    end
  end
  self.skillFrameTemp:SetData(skills)
end

function Preference_QiJiHelperUI:RefreshHpAndMp()
  local hp = QiJiHelperData.SettingData.recoverHp
  local hpNum = Mathf.Floor(hp * 100)
  local hpStr = string.format("%d%s", hpNum, "%")
  self.sl_hpThreshold:SetValue(hp)
  self.lab_hpThreshold:SetText(hpStr)
  local mp = QiJiHelperData.SettingData.recoverMp
  local mpNum = Mathf.Floor(mp * 100)
  local mpStr = string.format("%d%s", mpNum, "%")
  self.sl_mpThreshold:SetValue(mp)
  self.lab_mpThreshold:SetText(mpStr)
end

function Preference_QiJiHelperUI:RefreshPickupType()
  if QiJiHelperData.SettingData.selectPickupType == AutoPickupEnum.SelectAll then
    self.tog_all:SetIsOn(true)
    for i = 1, #self.AutoPickUpItemControls do
      self.AutoPickUpItemControls[i]:SetInteractable(false)
      self:RefreshPickTogTog(self.AutoPickUpItemControls[i])
    end
  else
    self.tog_select:SetIsOn(true)
    for i = 1, #self.AutoPickUpItemControls do
      self.AutoPickUpItemControls[i]:SetInteractable(true)
      self:RefreshPickTogTog(self.AutoPickUpItemControls[i])
    end
  end
end

function Preference_QiJiHelperUI:RefreshPickTogTog(tog)
  if tog.type ~= EItemType.Equipe and QiJiHelperData.SettingData.cantPickupTypes[tostring(tog.type)] then
    tog:SetIsOn(false)
  elseif tog.type == EItemType.Equipe then
    local rarityTab = string.split(tog.rarity, "#")
    local index = string.format("%s#%s", tog.type, rarityTab[1])
    if QiJiHelperData.SettingData.cantPickupTypes[index] then
      tog:SetIsOn(false)
    else
      tog:SetIsOn(true)
    end
  else
    tog:SetIsOn(true)
  end
end
