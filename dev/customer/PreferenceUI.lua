PreferenceUI = class(BaseUI)
PreferenceUI.layer = UILayer.Panel
PreferenceUI.orderInLayer = 0
PreferenceUI.hideType = UIHideType.WaitDestroy
PreferenceUI.hideFunc = UIHideFunc.MoveOutOfScreen
PreferenceUI.escClose = UIEscClose.DontClose

function PreferenceUI:InitControls()
  self.btn_closeBg = self:GetControl("btn_closeBg")
  self.tog_baseSet = self:GetControl("img_tabFrame/toggles/tog_baseSet")
  self.tog_KillMonster = self:GetControl("img_tabFrame/toggles/tog_KillMonster")
  self.tog_showSet = self:GetControl("img_tabFrame/toggles/tog_showSet")
  self.tog_exchange = self:GetControl("img_tabFrame/toggles/tog_exchange")
  self.tog_invite = self:GetControl("img_tabFrame/toggles/tog_invite")
  self.btn_resetBasic = self:GetControl("panel_baseSet/btn_resetBasic")
  self.go_lock_android = self:GetControl("panel_baseSet/go_lock_android")
  self.btn_lockScreen = self:GetControl("panel_baseSet/go_lock_android/btn_lockScreen")
  self.btn_exitGame = self:GetControl("panel_baseSet/btn_exitGame")
  self.btn_selectRole = self:GetControl("panel_baseSet/btn_selectRole")
  self.pushoffpanel = self:GetControl("panel_baseSet/pushoffpanel")
  self.btn_GeneralPush = self:GetControl("panel_baseSet/pushoffpanel/pushbtn1")
  self.btn_GeneralPush_on = self:GetControl("panel_baseSet/pushoffpanel/pushbtn1/on")
  self.btn_GeneralPush_off = self:GetControl("panel_baseSet/pushoffpanel/pushbtn1/off")
  self.btn_nightPush = self:GetControl("panel_baseSet/pushoffpanel/pushbtn2")
  self.btn_nightPush_on = self:GetControl("panel_baseSet/pushoffpanel/pushbtn2/on")
  self.btn_nightPush_off = self:GetControl("panel_baseSet/pushoffpanel/pushbtn2/off")
  self.sl_bgmSound = self:GetControl("panel_baseSet/go_sound/go_backgroundSound/sl_bgmSound")
  self.sl_effectSound = self:GetControl("panel_baseSet/go_sound/go_soundEffects/sl_effectSound")
  self.go_speechSounds = self:GetControl("panel_baseSet/go_sound/go_speechSounds")
  self.sl_speechSound = self:GetControl("panel_baseSet/go_sound/go_speechSounds/sl_speechSound")
  self.go_setting_android = self:GetControl("panel_baseSet/go_setting_android")
  self.tog_fixedRocker = self:GetControl("panel_baseSet/go_setting_android/rockerTgGroup/tog_fixedRocker")
  self.tog_movingRocker = self:GetControl("panel_baseSet/go_setting_android/rockerTgGroup/tog_movingRocker")
  self.tog_autoApply = self:GetControl("panel_baseSet/go_setting_android/tog_autoApply")
  self.go_settingsScreen_pc = self:GetControl("panel_baseSet/go_settingsScreen_pc")
  self.go_settingsResolution_pc = self:GetControl("panel_baseSet/go_settingsResolution_pc")
  self.btn_test = self:GetControl("panel_baseSet/btn_test")
  self.btn_resetDisplay = self:GetControl("panel_showSet/btn_resetDisplay")
  self.dp_hidePlayerModel = self:GetControl("panel_showSet/go_sceneShow/hidePlayerModel/dp_hidePlayerModel")
  self.dp_hidePlayerSkillEffect = self:GetControl("panel_showSet/go_sceneShow/hidePlayerSkillEffect/dp_hidePlayerSkillEffect")
  self.hidePlayerWing = self:GetControl("panel_showSet/go_sceneShow/hidePlayerWing/hidePlayerWing")
  self.hidePlayerBoot = self:GetControl("panel_showSet/go_sceneShow/hidePlayerBoot/hidePlayerBoot")
  self.tog_hideSummonMonsterModel = self:GetControl("panel_showSet/go_sceneShow/tog_hideSummonMonsterModel")
  self.tog_hideMonsterModel = self:GetControl("panel_showSet/go_sceneShow/tog_hideMonsterModel")
  self.tog_hideMonsterSkillEffect = self:GetControl("panel_showSet/go_sceneShow/tog_hideMonsterSkillEffect")
  self.lab_playerCount = self:GetControl("panel_showSet/go_playerShowLimit/lab_playerCount")
  self.sl_playerShowLimit = self:GetControl("panel_showSet/go_playerShowLimit/sl_playerShowLimit")
  self.tog_playerShowLimit = self:GetControl("panel_showSet/go_playerShowLimit/tog_playerShowLimit")
  self.tog_LD = self:GetControl("panel_showSet/go_revolution/toggles/tog_LD")
  self.tog_MD = self:GetControl("panel_showSet/go_revolution/toggles/tog_MD")
  self.tog_HD = self:GetControl("panel_showSet/go_revolution/toggles/tog_HD")
  self.tog_fps_low = self:GetControl("panel_showSet/go_fps/toggles/tog_fps_low")
  self.tog_fps_middle = self:GetControl("panel_showSet/go_fps/toggles/tog_fps_middle")
  self.tog_fps_high = self:GetControl("panel_showSet/go_fps/toggles/tog_fps_high")
  self.tog_lowQuality = self:GetControl("panel_showSet/go_performanceOptimizing/toggles/tog_lowQuality")
  self.tog_mediumQuality = self:GetControl("panel_showSet/go_performanceOptimizing/toggles/tog_mediumQuality")
  self.tog_highQuality = self:GetControl("panel_showSet/go_performanceOptimizing/toggles/tog_highQuality")
  self.input_exchangeFrame = self:GetControl("panel_exchange/input_exchangeFrame")
  self.btn_exchange = self:GetControl("panel_exchange/btn_exchange")
  self.inviteCount = self:GetControl("panel_invite/inviteCount")
  self.input_inviteCodeFrame = self:GetControl("panel_invite/input_inviteCodeFrame")
  self.btn_random = self:GetControl("panel_invite/btn_random")
  self.btn_copy = self:GetControl("panel_invite/btn_copy")
  self.btn_close = self:GetControl("btn_close")
  self.ScrollView = self:GetControl("go_KillMonster/ScrollView")
  self.tog_StrikeBack = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/BaseSet/tog_StrikeBack")
  self.tog_Return = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/BaseSet/tog_Return")
  self.InputField = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/BaseSet/tog_Return/InputField")
  self.tog_buff = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/BaseSet/tog_buff")
  self.ExpUp = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/ExpUp")
  self.go_ExpUpItem = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/ExpUp/ScrollView/Viewport/Content/go_ExpUpItem")
  self.go_DamageSkillSet = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/go_DamageSkillSet")
  self.Img_SingleSkillBg = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/go_DamageSkillSet/Img_SingleSkillBg")
  self.Img_SingleSkillIcon = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/go_DamageSkillSet/Img_SingleSkillBg/Img_SingleSkillIcon")
  self.Img_DoubleSkillBg = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/go_DamageSkillSet/Img_DoubleSkillBg")
  self.Img_DoubleSkillIcon = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/go_DamageSkillSet/Img_DoubleSkillBg/Img_DoubleSkillIcon")
  self.Img_SelfSelectSkillBg = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/go_DamageSkillSet/Img_SelfSelectSkillBg")
  self.go_SkillSet = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/go_SkillSet")
  self.Img_autoFightSkillBg = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/go_SkillSet/go_SkillSet/Img_autoFightSkillBg")
  self.go_SummonSkillSet = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/go_SummonSkillSet")
  self.Img_SummonSkillBg = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/go_SummonSkillSet/Img_SummonSkillBg")
  self.Img_SummonSkillIcon = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/go_SummonSkillSet/Img_SummonSkillBg/Img_SummonSkillIcon")
  self.go_BUFFSkillSet = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/go_BUFFSkillSet")
  self.Img_BUFFSkillBg = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/go_BUFFSkillSet/go_BUFFSkillGroup/Img_BUFFSkillBg")
  self.Img_BUFFSkillBg = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/go_BUFFSkillSet/go_BUFFSkillGroup/Img_BUFFSkillBg")
  self.sv_SelectSkill = self:GetControl("go_KillMonster/sv_SelectSkill")
  self.img_SkillFrame = self:GetControl("go_KillMonster/sv_SelectSkill/Viewport/Content/img_SkillFrame")
  self.lab_hpThreshold = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/AutoUseItem/lab_hpFloor/lab_hpThreshold")
  self.sl_hpThreshold = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/AutoUseItem/lab_hpFloor/sl_hpThreshold")
  self.lab_mpFloor = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/AutoUseItem/lab_mpFloor")
  self.lab_mpThreshold = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/AutoUseItem/lab_mpFloor/lab_mpThreshold")
  self.sl_mpThreshold = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/AutoUseItem/lab_mpFloor/sl_mpThreshold")
  self.go_Collect = self:GetControl("go_Collect")
  self.tog_all = self:GetControl("go_Collect/go_autoPickup/tog_all")
  self.tog_select = self:GetControl("go_Collect/go_autoPickup/tog_select")
  self.tog_gem = self:GetControl("go_Collect/go_autoPickup/tog_gem")
  self.tog_greyishWhiteEquip = self:GetControl("go_Collect/go_autoPickup/tog_greyishWhiteEquip")
  self.tog_skillBook = self:GetControl("go_Collect/go_autoPickup/tog_skillBook")
  self.tog_orangeEquip = self:GetControl("go_Collect/go_autoPickup/tog_orangeEquip")
  self.tog_gold = self:GetControl("go_Collect/go_autoPickup/tog_gold")
  self.tog_blueEquip = self:GetControl("go_Collect/go_autoPickup/tog_blueEquip")
  self.tog_diamond = self:GetControl("go_Collect/go_autoPickup/tog_diamond")
  self.tog_goldenEquip = self:GetControl("go_Collect/go_autoPickup/tog_goldenEquip")
  self.tog_material = self:GetControl("go_Collect/go_autoPickup/tog_material")
  self.tog_greenEquip = self:GetControl("go_Collect/go_autoPickup/tog_greenEquip")
  self.tog_purpleEquip = self:GetControl("go_Collect/go_autoPickup/tog_purpleEquip")
  self.tog_redEquip = self:GetControl("go_Collect/go_autoPickup/tog_redEquip")
  self.btn_resetPickup = self:GetControl("go_Collect/btn_resetPickup")
  self.lab_KillMonsterScope = self:GetControl("go_KillMonster/ScrollView/Viewport/Content/KillMonsterScope/lab_KillMonsterScope")
  self.btn_autoFight = self:GetControl("go_KillMonster/btn_autoFight")
  self.tog_qijibi = self:GetControl("go_Collect/go_autoPickup/tog_qijibi")
  self.tog_agreement = self:GetControl("img_tabFrame/toggles/tog_agreement")
  self.panel_agreement = self:GetControl("panel_agreement")
  self.panel_agreementContent = self:GetControl("panel_agreement/sw_protectionAgreement/Viewport/Content")
  self.btn_UserRegistration = self:GetControl("panel_agreement/sw_protectionAgreement/Viewport/Content/btn_UserRegistration")
  self.btn_ChildProtection = self:GetControl("panel_agreement/sw_protectionAgreement/Viewport/Content/btn_ChildProtection")
  self.btn_UserInformation = self:GetControl("panel_agreement/sw_protectionAgreement/Viewport/Content/btn_UserInformation")
  self.btn_UserPrivacy = self:GetControl("panel_agreement/sw_protectionAgreement/Viewport/Content/btn_UserPrivacy")
  self.btn_ThirdInformation = self:GetControl("panel_agreement/sw_protectionAgreement/Viewport/Content/btn_ThirdInformation")
  self.btn_CancelAccount = self:GetControl("panel_agreement/btn_CancelAccount")
  self.tog_accountSet = self:GetControl("img_tabFrame/toggles/tog_accountSet")
  self.panel_account = self:GetControl("panel_account")
  self.btn_ReissueNoReceivedItem = self:GetControl("panel_account/Btn/btn_ReissueNoReceivedItem")
  self.btn_account = self:GetControl("panel_account/Btn/btn_CancelAccount")
  self.server_text = self:GetControl("panel_account/playerInformation/server/lab_name")
  self.playerName_text = self:GetControl("panel_account/playerInformation/playerName/lab_name")
  self.pinID_text = self:GetControl("panel_account/playerInformation/PinID/lab_name")
  self.btn_Copy = self:GetControl("panel_account/playerInformation/btn_copy")
  self.btn_GameInformation = self:GetControl("panel_account/Btn/btn_GameInformation")
  self.btn_ChangeChannel = self:GetControl("panel_account/Btn/btn_ChangeChannel")
  self.btn_Community = self:GetControl("panel_baseSet/btns/btn_Community")
  self.btn_Questionnaires = self:GetControl("panel_baseSet/btns/btn_Questionnaires")
  self.go_language = self:GetControl("panel_baseSet/go_language")
  self.btn_dropdown = self:GetControl("panel_baseSet/go_language/btn_dropdown")
  self.btn_Deregister = self:GetControl("panel_baseSet/btn_Deregister")
  self.btn_Facebook = self:GetControl("panel_account/Btn/btn_Facebook")
  self.btn_Discord = self:GetControl("panel_account/Btn/btn_Discord")
  self.BindAccount = self:GetControl("panel_account/BindAccount")
  self.level_Item = self:GetControl("panel_account/BindAccount/go_gift/Viewport/grid_reward/level_Item")
  self.btn_BindAccount = self:GetControl("panel_account/BindAccount/BindAccount")
  self.btn_getReward = self:GetControl("panel_account/BindAccount/getReward")
  self.btn_received = self:GetControl("panel_account/BindAccount/received")
  self.tog_fullScreen = self:GetControl("panel_baseSet/go_settingsScreen_pc/toggles/tog_fullScreen")
  self.tog_windowScreen = self:GetControl("panel_baseSet/go_settingsScreen_pc/toggles/tog_windowScreen")
  self.btnset1920 = self:GetControl("panel_baseSet/go_settingsResolution_pc/sw_resolution/Viewport/Content/tog_resolution")
  self.itemShortcutKey = self:GetControl("panel_Keymapping/sw_keymapping/Viewport/Content/Keymapping")
  self.btn_ShortcutKeyReset = self:GetControl("panel_Keymapping/btn_Reset")
  self.btn_ShortcutKeySave = self:GetControl("panel_Keymapping/btn_Save")
  self.tog_keymapping = self:GetControl("img_tabFrame/toggles/tog_keymapping")
end

function PreferenceUI:Init()
  self.windowScreen = "windowScreen_x_y"
  self.FullScreenAndNotFullScree = "FullScreenAndNotFullScree_x_y"
  self.permissionsData = {pushAllow = false, nightPushAllow = false}
  self.ispc = not PlatformData.PlatformCheck("iOS") and not PlatformData.PlatformCheck("Android")
end

function PreferenceUI:OnCreate()
  self:InitControls()
  self:InitCollections()
  self:InitControlsParams()
  self:InitKillMonsterToggle()
  self:InitPickupToggle()
  self:InitUI()
  self:RegistUIEvents()
end

function PreferenceUI:InitKillMonsterToggle()
  self.killMonsters = {}
  for i = 1, 8 do
    self.killMonsters[#self.killMonsters + 1] = self.lab_KillMonsterScope:GetChild("Img_black_" .. i)
    self.killMonsters[#self.killMonsters].distance = i
  end
end

function PreferenceUI:InitPickupToggle()
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
    self.tog_redEquip,
    self.tog_qijibi
  }
  self.tog_gem.type = EItemType.GemStone
  self.tog_skillBook.type = EItemType.SkillBook
  self.tog_gold.type = EResourcesType.gold
  self.tog_qijibi.type = EResourcesType.QiJiBi
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

local function OnLevelItemCreate(ctr)
  ctr.go_model = UIControl(ctr.transform, "go_model")
  ctr.lab_num = UIControl(ctr.transform, "lab_num")
end

local function OnLevelItemRefresh(ctr, _, data, ui)
  if data == nil then
    return
  end
  if ctr.itemcelldata == nil then
    ctr.itemcelldata = ItemCellData()
  end
  local itemData = ItemUtility.GenerateItemData(data.itemId)
  ctr.itemcelldata:RefreshData(itemData)
  ItemUtility.ShowItemCell(ctr, ctr.itemcelldata, ui, true)
  ctr.lab_num:SetText(data.count)
end

function PreferenceUI:InitUI()
  self.go_speechSounds:SetActive(VoiceUtility.isAllowYvVoice())
  self:InitDropDownOptions()
  self:InitLanguageOptions()
  self:BuffSkillContainerInit()
  self:InitAgreementPanel()
  self.btn_ItemContainer = UIUtility.BindUIContainerTemp(self.btnset1920, LuaComponentTemplates.Toggle_SingleToggleTemplate, self)
  self:InitSceen()
  self.level_ItemContainer = UIContainer(self.level_Item, self, OnLevelItemCreate, OnLevelItemRefresh)
  self.shortcutKeyContainerTemplate = UIUtility.BindUIContainerTemp(self.itemShortcutKey, LuaComponentTemplates.ShortcutKeyItemSetTemplate, self)
end

function PreferenceUI:InitPush()
  CS.MuInterface.Instance:GetSDKPushNotification()
end

function PreferenceUI:InitAgreementPanel()
  local globalId = 0
  local isShowAgreement = false
  if FucShowOrHideController.FuncSystemIsOpen(FunctionSystemEnumId.Preference, true) then
    isShowAgreement = true
    globalId = 4020010
  end
  if FucShowOrHideController.FuncSystemIsOpen(FunctionSystemEnumId.Preference2, true) then
    isShowAgreement = true
    globalId = 4020011
  end
  self.tog_agreement:SetActive(isShowAgreement)
  if globalId ~= 0 then
    local globalTable = ClientTable.cfg_Global_globalManager:TryGetValue(globalId)
    if globalTable == nil then
      return
    end
    local globalSplit = string.split(globalTable.effect, "#")
    for i = 1, #globalSplit do
      local tempBtn = UIControl(self.panel_agreementContent.transform, globalSplit[i])
      if tempBtn ~= nil then
        tempBtn:SetActive(true)
      end
    end
  end
end

function PreferenceUI:InitCollections()
  self.DisplayCampDpControls = {
    self.dp_hidePlayerModel,
    self.dp_hidePlayerSkillEffect,
    self.hidePlayerWing,
    self.hidePlayerBoot
  }
  self.ResolutionTogControls = {
    self.tog_LD,
    self.tog_MD,
    self.tog_HD
  }
  self.FPSTogControls = {
    self.tog_fps_low,
    self.tog_fps_middle,
    self.tog_fps_high
  }
  self.QualityTogControls = {
    self.tog_lowQuality,
    self.tog_mediumQuality,
    self.tog_highQuality
  }
end

function PreferenceUI:InitControlsParams()
  self.dp_hidePlayerModel.hideCampKey = "hidePlayerModelCamp"
  self.dp_hidePlayerSkillEffect.hideCampKey = "hideSkillEffectCamp"
  self.hidePlayerWing.hideCampKey = "hidePlayerWingCamp"
  self.hidePlayerBoot.hideCampKey = "hidePlayerBootCamp"
  self.tog_LD.resolution = C_ResolutionQuality.SD
  self.tog_MD.resolution = C_ResolutionQuality.HD
  self.tog_HD.resolution = C_ResolutionQuality.FHD
  self.tog_fps_low.fps = C_FrameRate.LOW
  self.tog_fps_middle.fps = C_FrameRate.MID
  self.tog_fps_high.fps = C_FrameRate.HIGH
  self.tog_lowQuality.quality = EPerformanceQuality.Low
  self.tog_mediumQuality.quality = EPerformanceQuality.Middle
  self.tog_highQuality.quality = EPerformanceQuality.High
end

function PreferenceUI:InitDropDownOptions()
  local campDesc
  for i = 1, #self.DisplayCampDpControls do
    self.DisplayCampDpControls[i].dropdown:ClearOptions()
    campDesc = LocalizationUtility.GetBattleCampPlayerDesc(EBattleCamp.None)
    self.DisplayCampDpControls[i].dropdown:AddOption(campDesc)
    campDesc = LocalizationUtility.GetBattleCampPlayerDesc(EBattleCamp.All)
    self.DisplayCampDpControls[i].dropdown:AddOption(campDesc)
    campDesc = LocalizationUtility.GetBattleCampPlayerDesc(EBattleCamp.League)
    self.DisplayCampDpControls[i].dropdown:AddOption(campDesc)
    campDesc = LocalizationUtility.GetBattleCampPlayerDesc(EBattleCamp.OpLeague)
    self.DisplayCampDpControls[i].dropdown:AddOption(campDesc)
    campDesc = LocalizationUtility.GetBattleCampPlayerDesc(EBattleCamp.OtherPlayer)
    self.DisplayCampDpControls[i].dropdown:AddOption(campDesc)
  end
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
    local tabletemp = ClientTable.cfg_Item_tipsManager:TryGetValue(skill.description)
    local itemTip = ""
    if tabletemp ~= nil then
      itemTip = tabletemp.content
    end
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

function PreferenceUI:SwitchSelfSelectSkill(control)
  QiJiHelperController.SetSelfSelSkill(control.skillId, control.toggle.isOn)
end

function PreferenceUI:DontDoNothing(control)
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

local function ItemShortcutKeyCreate(control)
  control.lab_Des = UIControl(control.transform, "Key/lab_Des")
  control.btn_Key = UIControl(control.transform, "Key/btn_Key")
  control.lab_KeyName = UIControl(control.transform, "Key/btn_Key/lab_KeyName")
end

local function ItemShortcutKeyRefresh(control, index, data, ui)
  if data == nil then
    return
  end
  control.lab_Des:SetText(data:GetShortcutKeyName())
  control.lab_KeyName:SetText(data:GetKeyMapPingName())
  local keyMapPingConfig = data:GetKeyMapPingConfig()
  if keyMapPingConfig == nil or next(keyMapPingConfig) == nil then
    return
  end
  control.btn_Key.groupId = keyMapPingConfig.groupId
  control.btn_Key.shortcutKeyId = keyMapPingConfig.id
end

function PreferenceUI:ShortcutKeyOnClick(control)
  CustomShortcutKeysManager:SetCurrentSelectedControl(control)
end

function PreferenceUI:BuffSkillContainerInit()
  self.buffSkillTemp = UIContainer(self.Img_BUFFSkillBg, self, OnCreateBuffSkill, OnRefreshBuffSkill)
  self.skillFrameTemp = UIContainer(self.img_SkillFrame, self, OnCreateSkillFrame, OnRefreshSkillFrame)
  self.allSkillSetTemp = UIContainer(self.Img_autoFightSkillBg, self, OnCreateAllSkillFrame, OnRefreshAllSkillFrame)
end

function PreferenceUI:SetAutoFightSkill(control)
  local skillConfig = ClientTable.cfg_Skill_skillManager:TryGetValue(control.skillId)
  if skillConfig.autoSkillType == AutoSkillEnum.BuffSkill then
    QiJiHelperController.SetMeBuffSkill(control.skillId, control:GetIsOn())
  else
    QiJiHelperController.SetSelfSelSkill(control.skillId, control:GetIsOn())
  end
end

function PreferenceUI:OnShow()
  EventManager.Dispatch(Event.Fuc_SingleRefresh, {
    4000001,
    4000003,
    4000005,
    4000009,
    4000015,
    4000016
  })
  self:RegistEvents()
  self:Refresh()
  self.pushoffpanel:SetActive(false)
end

function PreferenceUI:OnHide()
  self.input_inviteCodeFrame:GetChild("lab_exchangeNum"):SetActive(false)
  self.input_inviteCodeFrame:SetInputText("")
  self.tog_baseSet:SetIsOn(true)
  self.ScrollView:SetNormalizedPosition(1, 1)
  QiJiHelperController.Save()
  self:SavemaxVisiblePlayers()
end

function PreferenceUI:SavemaxVisiblePlayers()
  if self.isChangeMaxVisiblePlayers then
    networkRequest.ReqSaveClientData({
      [SerRecordIntType.maxVisiblePlayers] = GameSettingsData.maxVisiblePlayers
    })
  end
  self.isChangeMaxVisiblePlayers = false
end

function PreferenceUI:OnDestroy()
end

function PreferenceUI:Update()
  CustomShortcutKeysManager:OnUpdate()
end

function PreferenceUI:RegistUIEvents()
  self.btn_closeBg:SetOnClick(self, self.btn_closeOnClick)
  self.btn_close:SetOnClick(self, self.btn_closeOnClick)
  self.sl_bgmSound:SetOnSliderValueChanged(self, self.sl_bgmSoundOnValueChanged)
  self.sl_effectSound:SetOnSliderValueChanged(self, self.sl_effectSoundOnValueChanged)
  self.sl_speechSound:SetOnSliderValueChanged(self, self.sl_speechSoundOnValueChanged)
  self.tog_fixedRocker:SetOnToggleChanged(self, self.tog_fixedRockerOnValueChanged)
  self.tog_movingRocker:SetOnToggleChanged(self, self.tog_movingRockerOnValueChanged)
  self.tog_autoApply:SetOnToggleChanged(self, self.AutoApplyTeam)
  self.btn_exitGame:SetOnClick(self, self.btn_exitGameOnClick)
  self.btn_selectRole:SetOnClick(self, self.btn_selectRoleOnClick)
  self.btn_resetBasic:SetOnClick(self, self.btn_resetBasicOnClick)
  self.dp_hidePlayerModel:SetOnDropDownValueChanged(self, self.dp_hidePlayerModelValueChanged)
  self.dp_hidePlayerSkillEffect:SetOnDropDownValueChanged(self, self.dp_hidePlayerSkillEffectValueChanged)
  self.hidePlayerWing:SetOnDropDownValueChanged(self, self.HidePlayerWingValueChanged)
  self.hidePlayerBoot:SetOnDropDownValueChanged(self, self.HidePlayerBootValueChanged)
  self.tog_hideSummonMonsterModel:SetOnToggleChanged(self, self.tog_hideSummonMonsterModelValueChanged)
  self.tog_hideMonsterModel:SetOnToggleChanged(self, self.tog_hideMonsterModelValueChanged)
  self.tog_hideMonsterSkillEffect:SetOnToggleChanged(self, self.tog_hideMonsterSkillEffectValueChanged)
  self.tog_playerShowLimit:SetOnToggleChanged(self, self.OnPlayerShowLimitChanged)
  self.sl_playerShowLimit:SetOnSliderValueChanged(self, self.sl_playerShowLimitOnValueChanged)
  for i = 1, #self.ResolutionTogControls do
    self.ResolutionTogControls[i]:SetOnToggleChanged(self, self.OnResolutionChanged)
  end
  for i = 1, #self.FPSTogControls do
    self.FPSTogControls[i]:SetOnToggleChanged(self, self.OnFPSChanged)
  end
  for i = 1, #self.QualityTogControls do
    self.QualityTogControls[i]:SetOnToggleChanged(self, self.OnPerfermanceQualityChanged)
  end
  self.btn_resetDisplay:SetOnClick(self, self.btn_resetDisplayOnClick)
  self.btn_exchange:SetOnClick(self, self.btn_exchangeOnClick)
  self.Img_SummonSkillBg:SetOnClick(self, self.UpdateSummonSkill)
  self.btn_resetPickup:SetOnClick(self, self.ResetPickup)
  self.tog_StrikeBack:SetOnToggleChanged(self, self.SetStrikeBack)
  self.tog_Return:SetOnToggleChanged(self, self.SetReturnHome)
  self.tog_buff:SetOnToggleChanged(self, self.SetTeammateBuff)
  self.InputField:SetOnEndEdit(self, self.SetReturnHomeTime)
  self.sl_hpThreshold:SetOnSliderValueChanged(self, self.UpdateHpValueChange)
  self.sl_mpThreshold:SetOnSliderValueChanged(self, self.UpdateMpValueChange)
  self.tog_all:SetOnToggleChanged(self, self.SelectAllPickup)
  self.tog_select:SetOnToggleChanged(self, self.SelectPartPickup)
  self.btn_autoFight:SetOnClick(self, self.OpenAutoFight)
  for i = 1, #self.killMonsters do
    self.killMonsters[i]:SetOnToggleChanged(self, self.SetKillMonsterDistance)
  end
  self.btn_random:SetOnClick(self, self.ReqGenerateInviteCode)
  self.btn_copy:SetOnClick(self, self.CopyInviteCode)
  self.btn_lockScreen:SetOnClick(self, self.BtnLockScreenOnClick)
  self.btn_UserRegistration:SetOnClick(self, self.btn_UserRegistrationOnClick)
  self.btn_ChildProtection:SetOnClick(self, self.btn_ChildProtectionOnClick)
  self.btn_UserInformation:SetOnClick(self, self.btn_UserInformationOnClick)
  self.btn_UserPrivacy:SetOnClick(self, self.btn_UserPrivacyOnClick)
  self.btn_ThirdInformation:SetOnClick(self, self.btn_ThirdInformationOnClick)
  self.btn_CancelAccount:SetOnClick(self, self.btn_CancelAccountOnClick)
  self.btn_GeneralPush:SetOnClick(self, self.btn_GeneralPushClick)
  self.btn_nightPush:SetOnClick(self, self.btn_nightPushClick)
  self.btn_ReissueNoReceivedItem:SetOnClick(self, self.btn_ReissueNoReceivedItemOnClick)
  self.btn_account:SetOnClick(self, self.btn_AccountOnClick)
  self.btn_Copy:SetOnClick(self, self.btn_CopyOnClick)
  self.btn_GameInformation:SetOnClick(self, self.btn_GameInformationOnClick)
  self.btn_ChangeChannel:SetOnClick(self, self.btn_ChangeChannelOnClick)
  self.btn_Community:SetOnClick(self, self.btn_CommunityOnClick)
  self.btn_Questionnaires:SetOnClick(self, self.btn_QuestionnairesOnClick)
  self.tog_fullScreen:SetOnToggleChanged(self, self.OnFullScreenChanged)
  self.tog_windowScreen:SetOnToggleChanged(self, self.OnWindowScreenChanged)
  self.btn_Facebook:SetOnClick(self, self.btn_FacebookOnClick)
  self.btn_Discord:SetOnClick(self, self.btn_DiscordOnClick)
  self:OnShowKoreaPersimi()
  self.btn_dropdown:SetOnDropDownValueChanged(self, self.OnDropDownValueChangedCallback)
  self.btn_Deregister:SetOnClick(self, self.btn_CancelAccountOnClick)
  self.btn_ShortcutKeyReset:SetOnClick(self, self.btn_ShortcutKeyResetOnClick)
  self.btn_ShortcutKeySave:SetOnClick(self, self.btn_ShortcutKeySaveOnClick)
  self.btn_BindAccount:SetOnClick(self, self.btn_BindAccountOnClick)
  self.btn_getReward:SetOnClick(self, self.btn_getRewardOnClick)
end

function PreferenceUI:btn_QuestionnairesOnClick(control, index)
end

function PreferenceUI:InitSceenTemps()
  local screenSize = ClientTable.cfg_Global_globalManager:GetScreenSize()
  local screendata = {}
  for i = 1, #screenSize do
    local dataScree = {
      name = screenSize[i],
      toggleCallback = function(control, ison)
        local windowWh = PlayerPrefs.GetString(self.windowScreen)
        if ison and not string.isNullOrEmpty(windowWh) then
          local name = control.name
          if name then
            local names = string.split(name, "x")
            if 1 < #names then
              PlayerPrefs.SetString(self.windowScreen, name)
              do
                local screendata = PlayerPrefs.GetString(self.FullScreenAndNotFullScree)
                if not string.isNullOrEmpty(screendata) then
                  if self.Coroutine ~= nil then
                    Coroutine.Stop(self.Coroutine)
                  end
                  self.Coroutine = Coroutine.Start(function()
                    Screen.SetResolution(tonumber(names[1]), tonumber(names[2]), false)
                    Coroutine.Wait(1)
                    UIManager.RefreshScaleRatio()
                  end)
                end
              end
            end
          end
        end
      end
    }
    local screenAndFullScreen = PlayerPrefs.GetString(self.FullScreenAndNotFullScree)
    local windowWh = PlayerPrefs.GetString(self.windowScreen)
    if not string.isNullOrEmpty(screenAndFullScreen) then
      if windowWh == screenSize[i] then
        dataScree.isOn = true
      end
    elseif i == #screenSize then
      dataScree.isOn = true
    end
    table.insert(screendata, dataScree)
  end
  self.btn_ItemContainer:SetData(screendata)
end

function PreferenceUI:InitSceen()
  if not PlatformData.PlatformCheck(PlatformNameEnum.UNITY_STANDALONE_WIN) then
    return
  end
  local screenAndFullScreen = PlayerPrefs.GetString(self.FullScreenAndNotFullScree)
  if string.isNullOrEmpty(screenAndFullScreen) then
    self.tog_fullScreen:SetIsOn(true)
    PlayerPrefs.DeleteKey(self.FullScreenAndNotFullScree)
    self:SetScreenOnClickActive(false)
  else
    self.tog_windowScreen:SetIsOn(true)
    CS.UnityEngine.Screen.fullScreen = false
    PlayerPrefs.SetString(self.FullScreenAndNotFullScree, "1")
    self:SetScreenOnClickActive(true)
  end
  local windowWh = PlayerPrefs.GetString(self.windowScreen)
  if string.isNullOrEmpty(windowWh) then
    PlayerPrefs.SetString(self.windowScreen, "1920x1080")
  end
  self:InitSceenTemps()
end

function PreferenceUI:OnFullScreenChanged(control, ison)
  if ison then
    CS.UnityEngine.Screen.fullScreen = true
    PlayerPrefs.DeleteKey(self.FullScreenAndNotFullScree)
    self:SetScreenOnClickActive(false)
  end
end

function PreferenceUI:OnWindowScreenChanged(control, ison)
  if ison then
    CS.UnityEngine.Screen.fullScreen = false
    PlayerPrefs.SetString(self.FullScreenAndNotFullScree, "1")
    local windowWh = PlayerPrefs.GetString(self.windowScreen, "")
    if string.isNullOrEmpty(windowWh) then
      PlayerPrefs.SetString(self.windowScreen, "1920x1080")
    end
    self:SetScreenOnClickActive(true)
  end
end

function PreferenceUI:SetScreenOnClickActive(vluae)
  local pageTemplate
  if type(self.btn_ItemContainer) == "table" and type(self.btn_ItemContainer.items) == "table" then
    for k, v in pairs(self.btn_ItemContainer.items) do
      pageTemplate = v.itemTemp
      if pageTemplate.onSetInteractable ~= nil then
        pageTemplate:onSetInteractable(vluae)
      end
    end
  end
end

function PreferenceUI:btn_getRewardOnClick(control)
  local giftId = 670001
  NetManager.Send(RechargeMessage.ReqGetGift, {
    id = {giftId}
  })
end

function PreferenceUI:btn_BindAccountOnClick(control)
  local callRet, info = pcall(function()
    CS.MuInterface.Instance:OnChangePartner_Android("")
  end)
end

function PreferenceUI:btn_FacebookOnClick(control)
  local name = ClientTable.cfg_Function_functionManager:GetKoreaWebView(4000015)
  if name then
    PlatformData.OpenURL(name)
  end
end

function PreferenceUI:btn_DiscordOnClick(control)
  local name = ClientTable.cfg_Function_functionManager:GetKoreaWebView(4000016)
  if name then
    PlatformData.OpenURL(name)
  end
end

function PreferenceUI:OnShowKoreaPersimi(control)
end

function PreferenceUI:btn_ReissueNoReceivedItemOnClick(control)
  networkRequest.ReqReissue(LoginData.service_code, 2)
end

function PreferenceUI:btn_AccountOnClick(control)
  UIManager.Show(UIID.System_CaptchaTipsUI)
end

function PreferenceUI:btn_CopyOnClick(control)
  CS.UnityEngine.GUIUtility.systemCopyBuffer = tostring(LoginData.userId)
  FloatingTipUtility.QuickMsg(ClientTable.cfg_Text_ClientManager:GetDes(719))
end

function PreferenceUI:btn_GameInformationOnClick(control)
  local name = ClientTable.cfg_Function_functionManager:GetKoreaWebView(4000003)
  if name then
    CS.MuInterface.Instance:OnWebviewClick(name)
  end
end

function PreferenceUI:btn_ChangeChannelOnClick(control)
  LoginData.LogoutAccount()
  NetManager.Send(UserMessage.ReqLogout, {
    reason = ELogoutType.LogOut
  })
  gameMgr:GetAvatarManager():RemoveAllAvatar()
end

function PreferenceUI:btn_CommunityOnClick(control)
  UIManager.Show(UIID.Community_GiftUI)
  UIManager.Hide(UIID.PreferenceUI)
end

function PreferenceUI:btn_GeneralPushClick()
  if self.permissionsData.pushAllow == true then
    if self.permissionsData.nightPushAllow == true then
      self:onShowPushTip(40, function()
        self.permissionsData.pushAllow = false
        self.permissionsData.nightPushAllow = false
        CS.MuInterface.Instance:SetSDKPushNotification(json.encode(self.permissionsData))
      end)
    else
      self:onShowPushTip(37, function()
        self.permissionsData.pushAllow = false
        self.permissionsData.nightPushAllow = false
        CS.MuInterface.Instance:SetSDKPushNotification(json.encode(self.permissionsData))
      end)
    end
  else
    self:onShowPushTip(36, function()
      self.permissionsData.pushAllow = true
      CS.MuInterface.Instance:SetSDKPushNotification(json.encode(self.permissionsData))
    end)
  end
end

function PreferenceUI:btn_nightPushClick()
  if self.permissionsData.pushAllow == true then
    if self.permissionsData.nightPushAllow == true then
      self:onShowPushTip(39, function()
        self.permissionsData.nightPushAllow = false
        CS.MuInterface.Instance:SetSDKPushNotification(json.encode(self.permissionsData))
      end)
    else
      self:onShowPushTip(38, function()
        self.permissionsData.nightPushAllow = true
        CS.MuInterface.Instance:SetSDKPushNotification(json.encode(self.permissionsData))
      end)
    end
  else
  end
end

function PreferenceUI:ShowPushSet(_, data)
  local jsonData
  if data then
    jsonData = json.decode(data)
  end
  if jsonData then
    if jsonData.pushAllow and jsonData.pushAllow == true then
      self.permissionsData.pushAllow = true
    else
      self.permissionsData.pushAllow = false
    end
    if jsonData.nightPushAllow and jsonData.nightPushAllow == true then
      self.permissionsData.nightPushAllow = true
    else
      self.permissionsData.nightPushAllow = false
    end
  end
  self.btn_GeneralPush_on:SetActive(self.permissionsData.pushAllow)
  self.btn_GeneralPush_off:SetActive(not self.permissionsData.pushAllow)
  self.btn_nightPush_on:SetActive(self.permissionsData.nightPushAllow)
  self.btn_nightPush_off:SetActive(not self.permissionsData.nightPushAllow)
end

function PreferenceUI:onShowPushTip(id, callback)
  local data = ClientTable.cfg_Ui_promptwordManager:GetKoreaTipData(id)
  local currentTime = os.date("*t")
  local formattedDate = string.format("%04d.%02d.%02d", currentTime.year, currentTime.month, currentTime.day)
  formattedDate = string.format(data.content, formattedDate)
  if data then
    UIManager.Show(UIID.PromptTipUI, {
      title = data.title,
      autoClose = false,
      isframe = true,
      textContent = formattedDate,
      okText = data.rightButton,
      cancelText = data.leftButton,
      cancel = function()
        UIManager.Hide(UIID.PromptTipUI)
      end,
      ok = callback
    })
  end
end

function PreferenceUI:btn_UserRegistrationOnClick(control)
  UIManager.Show(UIID.Login_UserRegistrationUI)
end

function PreferenceUI:btn_ChildProtectionOnClick(control)
  UIManager.Show(UIID.Login_ChildProtectionUI)
end

function PreferenceUI:btn_UserInformationOnClick(control)
  UIManager.Show(UIID.Login_UserInformationUI)
end

function PreferenceUI:btn_UserPrivacyOnClick(control)
  if LoginData.OperEnum[LoginData.operId] == "tanwan" then
    LoginController.CallSDKUserAgreement()
    return
  end
  UIManager.Show(UIID.Login_UserPrivacyUI, {canCancelProtocol = true})
end

function PreferenceUI:btn_ThirdInformationOnClick(control)
  UIManager.Show(UIID.Login_ThirdInformationUI)
end

function PreferenceUI:btn_CancelAccountOnClick(content)
  local uiWord = ClientTable.cfg_Ui_promptwordManager:TryGetValue(13)
  UIManager.Show(UIID.PromptTipUI, {
    title = uiWord.title,
    textContent = uiWord.content,
    ok = function(okArgs)
      LoginController.AccountCancellation()
      NetManager.Send(UserMessage.ReqLogout, {
        reason = ELogoutType.LogOut
      })
      gameMgr:GetAvatarManager():RemoveAllAvatar()
    end
  })
end

function PreferenceUI:BtnLockScreenOnClick(control)
  self:btn_closeOnClick()
  UIManager.Show(UIID.LockScreenUI)
end

function PreferenceUI:CopyInviteCode(control)
  if self.input_inviteCodeFrame:GetInputText() ~= "" then
    UnityEngineLua.GUIUtility.systemCopyBuffer = self.input_inviteCodeFrame:GetInputText()
  else
    FloatingWordUtility.QuickMsg(ClientTable.cfg_Text_ClientManager:GetDes(720))
  end
end

function PreferenceUI:ReqGenerateInviteCode(control)
  if self.usedAll then
    FloatingTipUtility.QuickMsg(ClientTable.cfg_Text_ClientManager:GetDes(721))
  else
    self.input_inviteCodeFrame:GetChild("lab_exchangeNum"):SetActive(true)
    NetManager.Send(UserMessage.ReqGenInviteCode)
  end
end

function PreferenceUI:SetTeammateBuff(control)
  QiJiHelperController.SetTeammateBuff(false)
end

function PreferenceUI:OpenAutoFight(control)
  if QiJiHelperData.isAutoFight then
    FloatingWordUtility.QuickMsg(ClientTable.cfg_Text_ClientManager:GetDes(722))
  else
    QiJiHelperData.openReturnHome = true
    RoleManager.me:SetAutoFight(AutoFightStrKey.AutoFight)
    UIManager.Hide(UIID.PreferenceUI)
  end
end

local blackColor = "0x8A8A8AFF"
local whiteColor = "0xFFFFFFFF"

function PreferenceUI:SetKillMonsterDistance(control)
  control:SetColor(control:GetIsOn() and whiteColor or blackColor)
  QiJiHelperController.SetSkillMonsterRange(control.distance)
end

function PreferenceUI:SetBuffSkillSwitch(control)
  QiJiHelperController.SetMeBuffSkill(control.skillId, control.toggle.isOn)
end

function PreferenceUI:SetStrikeBack(control)
  QiJiHelperController.SetSTrikeBack(control.toggle.isOn)
end

function PreferenceUI:SetReturnHome(control)
  QiJiHelperController.SetReturnHome(control.toggle.isOn)
  self:SetInputTextInteract(control.toggle.isOn)
end

function PreferenceUI:SetInputTextInteract(isOn)
  self.InputField:SetInteractable(isOn)
end

function PreferenceUI:SetReturnHomeTime(control)
  if control:GetInputText() == "" then
    QiJiHelperController.SetReturnHomeTime(10)
  else
    local returnTime
    if tonumber(control:GetInputText()) < 1 then
      returnTime = 1
    else
      returnTime = tonumber(control:GetInputText())
    end
    QiJiHelperController.SetReturnHomeTime(returnTime)
    self.InputField:SetInputText(QiJiHelperData.SettingData.ReturnHome.ReturnTime)
  end
end

function PreferenceUI:SetAutoTreat(control)
  QiJiHelperController.SetAutoTreat(control.toggle.isOn)
end

function PreferenceUI:ShowSelectSkill(control)
  self.showSkillType = "allDamage"
  BlockerUtility.Show(self.sv_SelectSkill)
  self:RefreshAllSelfSelSkill()
end

function PreferenceUI:UpdateSummonSkill(control)
  self.showSkillType = "summon"
  BlockerUtility.Show(self.sv_SelectSkill)
  self.selfSelectSkillType = AutoSkillEnum.SummonSkill
  self:RefreshSelfSelSkill(AutoSkillEnum.SummonSkill)
end

function PreferenceUI:SetSelfSelSkill(control)
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

function PreferenceUI:UpdateHpValueChange(control)
  local value = control:GetValue()
  value = Mathf.Floor(value * 100 + 0.5) / 100
  local num, b = math.modf(value * 100)
  local valueStr = string.format("%s%s", num, "%")
  self.lab_hpThreshold:SetText(string.format(ClientTable.cfg_Text_ClientManager:GetDes(1173), valueStr))
  QiJiHelperController.SetAutoRecoverHp(value)
  UIUtility.RefreshAutoRoleMpHpSetting()
end

function PreferenceUI:UpdateMpValueChange(control)
  local value = control:GetValue()
  value = Mathf.Floor(value * 100 + 0.5) / 100
  local num, b = math.modf(value * 100)
  local valueStr = string.format("%s%s", num, "%")
  self.lab_mpThreshold:SetText(string.format(ClientTable.cfg_Text_ClientManager:GetDes(1174), valueStr))
  QiJiHelperController.SetAutoRecoverMp(value)
  UIUtility.RefreshAutoRoleMpHpSetting()
end

function PreferenceUI:SelectAllPickup(control)
  if not control.toggle.isOn then
    return
  end
  QiJiHelperController.SetAutoPickupType(AutoPickupEnum.SelectAll)
  for i = 1, #self.AutoPickUpItemControls do
    self.AutoPickUpItemControls[i]:SetInteractable(false)
  end
end

function PreferenceUI:SelectPartPickup(control)
  if not control.toggle.isOn then
    return
  end
  QiJiHelperController.SetAutoPickupType(AutoPickupEnum.SelectPart)
  for i = 1, #self.AutoPickUpItemControls do
    self.AutoPickUpItemControls[i]:SetInteractable(true)
  end
end

function PreferenceUI:PickUpTogOnValueChanged(control)
  QiJiHelperController.SetCantPickupType(control.toggle.isOn, control.type, control.rarity)
  EventManager.Dispatch(Event.QiJiHelper_SetAutoPickup)
end

function PreferenceUI:ResetPickup(control)
  QiJiHelperController.SetDefaultAutoPickup()
  self:RefreshPickupType()
  EventManager.Dispatch(Event.QiJiHelper_SetAutoPickup)
end

function PreferenceUI:btn_exitGameOnClick(control)
  NetManager.Send(UserMessage.ReqLogout, {
    reason = ELogoutType.LogOut
  })
  gameMgr:GetAvatarManager():RemoveAllAvatar()
end

function PreferenceUI:btn_selectRoleOnClick(control)
  NetManager.Send(UserMessage.ReqLogout, {
    reason = ELogoutType.BackToChoose
  })
  gameMgr:GetAvatarManager():RemoveAllAvatar()
end

function PreferenceUI:sl_bgmSoundOnValueChanged(control, value)
  GameSettingsController.SetMusicVolume(value)
end

function PreferenceUI:sl_effectSoundOnValueChanged(control, value)
  GameSettingsController.SetSoundVolume(value)
end

function PreferenceUI:sl_speechSoundOnValueChanged(control, value)
  GameSettingsController.SetSpeechVolume(value)
end

function PreferenceUI:OnPlayerShowLimitChanged(control, isOn)
  GameSettingsController.SetLimitShowPlayers(isOn)
  self.sl_playerShowLimit:SetInteractable(isOn)
  ColorUtility.SetUIColor(self.lab_playerCount, isOn and Color.white or Color.gray)
end

function PreferenceUI:sl_playerShowLimitOnValueChanged(control, value)
  value = math.floor(value)
  self.lab_playerCount:SetText(tostring(value))
  GameSettingsController.SetPlayerShowLimitCount(value)
  self.isChangeMaxVisiblePlayers = true
end

function PreferenceUI:tog_fixedRockerOnValueChanged(control, isOn)
  if isOn then
    GameSettingsController.SetJoyStickMode(EJoyStickMode.Fixed)
  end
end

function PreferenceUI:tog_movingRockerOnValueChanged(control, isOn)
  if isOn then
    GameSettingsController.SetJoyStickMode(EJoyStickMode.Free)
  end
end

function PreferenceUI:ShowAutoApplyTeam()
  TeamData.SetAutoApplyTeamFlag()
  self.tog_autoApply.toggle.isOn = TeamData.isApplyAutoTeam
end

function PreferenceUI:AutoApplyTeam()
  local autoApply = self.tog_autoApply.toggle.isOn
  TeamData.SetApplyAutoInTeam(autoApply)
end

function PreferenceUI:btn_resetBasicOnClick(control)
  GameSettingsController.ResetBasic()
  self:RefreshBasic()
  self:Refresh()
end

local testa = false

function PreferenceUI:btn_testOnClick(ctr)
  testa = not testa
  CS.Main.TestNewFunc(testa)
  local t = not testa and ClientTable.cfg_Text_ClientManager:GetDes(723) or ClientTable.cfg_Text_ClientManager:GetDes(724)
  ctr:GetChild("Text"):SetText(t)
end

function PreferenceUI:dp_hidePlayerModelValueChanged(control, value)
  GameSettingsController.SetHidePlayerModelType(value + 1)
end

function PreferenceUI:dp_hidePlayerSkillEffectValueChanged(control, value)
  GameSettingsController.SetHideModelSkillEffectType(value + 1)
end

function PreferenceUI:HidePlayerWingValueChanged(control, value)
  GameSettingsController.SetHidePlayerWingType(value + 1)
end

function PreferenceUI:HidePlayerBootValueChanged(control, value)
  GameSettingsController.SetHidePlayerBootType(value + 1)
end

function PreferenceUI:tog_hideSummonMonsterModelValueChanged(control, value)
  GameSettingsController.SetSummonMonsterModelType(value)
end

function PreferenceUI:tog_hideMonsterModelValueChanged(control, value)
  GameSettingsController.SetHideMonsterModel(value)
end

function PreferenceUI:tog_hideMonsterSkillEffectValueChanged(control, value)
  GameSettingsController.SetHideMonsterSkillEffect(value)
end

function PreferenceUI:OnResolutionChanged(control, isOn)
  if isOn then
    GameSettingsController.SetResolution(control.resolution)
  end
end

function PreferenceUI:OnFPSChanged(control, isOn)
  if isOn then
    GameSettingsController.SetFrameRate(control.fps)
  end
end

function PreferenceUI:OnPerfermanceQualityChanged(control, isOn)
  if isOn then
    GameSettingsController.ResetPerformQuality(control.quality)
    self:RefreshDisplay()
  end
end

function PreferenceUI:btn_resetDisplayOnClick(control)
  GameSettingsController.ResetDisplay()
  self:RefreshDisplay()
end

function PreferenceUI:btn_exchangeOnClick(control)
  local cdkey = self.input_exchangeFrame:GetInputText()
  if string.isNullOrEmpty(cdkey) then
    return
  end
  NetManager.Send(BagMessage.ReqUseCDKey, {cdKey = cdkey})
  self.input_exchangeFrame:SetInputText("")
end

function PreferenceUI:btn_closeOnClick(control)
  GameSettingsController.Save()
  UIManager.Hide(UIID.PreferenceUI)
end

function PreferenceUI:RegistEvents()
  self:RegistEvent(Event.Skill_SkillRedPoint, self.RefreshLearnSkill, self)
  self:RegistEvent(Event.RefreshInviteUI, self.RefreshInviteUI, self)
  self:RegistEvent(Event.PreferenceUI_ExchangeRefresh, self.RefreshExchange, self)
  self:RegistEvent(Event.KoreaSDKPush_CALLBACK, self.ShowPushSet, self)
  self:RegistEvent(Event.RefreshAllShortcutKeys, self.RefreshAllShortcutKeys, self)
  self:RegistEvent(Event.RefreshTempItemShortcutKeys, self.RefreshTempItemShortcutKeys, self)
end

function PreferenceUI:RefreshLearnSkill()
  if self.showSkillType == "summon" then
    self:RefreshSelfSelSkill(AutoSkillEnum.SummonSkill)
  elseif self.showSkillType == "allDamage" then
    self:RefreshAutoFightSkill()
  end
end

function PreferenceUI:RefreshInviteUI(_, msg)
  self.usedAll = msg.usedAll
  if msg.usedAll then
    self.inviteCount:SetText(ClientTable.cfg_Text_ClientManager:GetDes(725))
  else
    self.inviteCount:SetText(string.format(ClientTable.cfg_Text_ClientManager:GetDes(726), msg.cur))
    self.input_inviteCodeFrame:SetInputText(msg.code)
  end
end

function PreferenceUI:Refresh()
  EventManager.Dispatch(Event.Fuc_SingleRefresh, {2600001})
  NetManager.Send(UserMessage.ReqInviteCodeView)
  self:SetActiveByAndroidOrPc()
  self:RefreshPreferenceBasic()
  self:RefreshDisplay()
  self.showSkillType = ""
  self:RefreshUIByCareer()
  self:RefreshBasic()
  if RoleUtility.GetBasicCareer(RoleManager.me.career) == ERoleCareer.Magic then
    self.tog_buff:SetActive(false)
  elseif RoleUtility.GetBasicCareer(RoleManager.me.career) == ERoleCareer.Archer then
    self.tog_buff:SetActive(false)
    self:RefreshSummonSkill()
  elseif RoleUtility.GetBasicCareer(RoleManager.me.career) == ERoleCareer.SwordMan then
    self.tog_buff:SetActive(false)
  end
  self:RefreshAutoFightSkill()
  self:RefreshHpAndMp()
  self:RefreshPickupType()
  if self.args and self.args.togName == "tog_KillMonster" then
    self.tog_KillMonster:SetIsOn(true)
  end
  if self.args and self.args.togName == "tog_accountSet" then
    self.tog_accountSet:SetIsOn(true)
  end
  self:ShowAutoApplyTeam()
  if PlatformData.GetAuditPlatfromID() > 0 and self.tog_invite then
    self.tog_invite:SetActive(false)
  end
  self:RefreshExchange()
  self:SetAccountText()
  self:InitPush()
  self:RefreshLanguage()
  self:RefreshBindAccount()
  self:RefreshAllShortcutKeys()
  self.tog_keymapping:SetActive(self.ispc)
end

function PreferenceUI:SetActiveByAndroidOrPc()
  local isAndroidOrPc = PlatformData.PlatformCheck("Android") or PlatformData.PlatformCheck("iOS")
  self.go_setting_android:SetActive(isAndroidOrPc)
  self.go_lock_android:SetActive(isAndroidOrPc)
  self.go_settingsScreen_pc:SetActive(not isAndroidOrPc)
  self.go_settingsResolution_pc:SetActive(not isAndroidOrPc)
end

function PreferenceUI:SetAccountText()
  self.server_text:SetText(LoginData.GetServerName())
  self.playerName_text:SetText(ViewData.meData.name)
  self.pinID_text:SetText(LoginData.userId)
end

function PreferenceUI:RefreshExchange()
  if PlatformData.PlatformCheck(PlatformNameEnum.UNITY_IOS) then
    if self.tog_exchange then
      self.tog_exchange:SetActive(false)
    end
  else
    if PlayerControlForceData.exchangeOpenState == false then
      local funcTbl = ClientTable.cfg_Function_functionManager:TryGetValue(FunctionSystemEnumId.Exchange)
      if funcTbl and funcTbl.condition then
        local isOpen = self.tog_exchange:GetActive()
        for i, v in ipairs(funcTbl.condition) do
          if ConditionManager.GenerateSingleCondition(v[1]):Check() then
            isOpen = ConditionManager.Check4D(funcTbl.condition)
            break
          end
        end
        if isOpen then
          ServerDataRecordData.SendSaveData({
            dataInt = {
              [SerRecordIntType.exchangeOpen] = 1
            }
          })
          PlayerControlForceData.exchangeOpenState = true
        end
      end
    end
    self.tog_exchange:SetActive(PlayerControlForceData.exchangeOpenState)
  end
end

function PreferenceUI:RefreshAutoFightSkill()
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

function PreferenceUI:RefreshUIByCareer()
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

function PreferenceUI:RefreshBasic()
  local scope = QiJiHelperData.SettingData.KillMonsterScope
  if scope > 8 then scope = 8 end
  if scope < 1 then scope = 1 end
  self.killMonsters[scope].toggle.isOn = true
  self.tog_StrikeBack.toggle.isOn = QiJiHelperData.SettingData.StrikeBack
  self.tog_Return.toggle.isOn = QiJiHelperData.SettingData.ReturnHome.IsReturn
  self.tog_buff.toggle.isOn = QiJiHelperData.SettingData.AddBuffToTeammate
  self.InputField:SetInputText(QiJiHelperData.SettingData.ReturnHome.ReturnTime)
end

function PreferenceUI:RefreshSummonSkill()
  local summonSkillData = ClientTable.cfg_Skill_skillManager:TryGetValue(QiJiHelperData.SettingData.selfSelSummonSkill)
  if summonSkillData then
    self.Img_SummonSkillIcon:SetActive(true)
    self:SetSprite("Atlas_Skill", summonSkillData.icon, self.Img_SummonSkillIcon)
  else
    self.Img_SummonSkillIcon:SetActive(false)
  end
end

function PreferenceUI:RefreshSelfSelSkill(skillType)
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

function PreferenceUI:RefreshAllSelfSelSkill()
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

function PreferenceUI:RefreshHpAndMp()
  local hp = QiJiHelperData.SettingData.recoverHp
  local hpNum = Mathf.Floor(hp * 100)
  local hpStr = string.format("%d%s", hpNum, "%")
  self.sl_hpThreshold:SetValue(hp)
  self.lab_hpThreshold:SetText(string.format(ClientTable.cfg_Text_ClientManager:GetDes(1173), hpStr))
  local mp = QiJiHelperData.SettingData.recoverMp
  local mpNum = Mathf.Floor(mp * 100)
  local mpStr = string.format("%d%s", mpNum, "%")
  self.sl_mpThreshold:SetValue(mp)
  self.lab_mpThreshold:SetText(string.format(ClientTable.cfg_Text_ClientManager:GetDes(1174), mpStr))
end

function PreferenceUI:RefreshPickupType()
  for i = 1, #self.AutoPickUpItemControls do
    self.AutoPickUpItemControls[i]:SetOnToggleChanged(self, self.DontDoNothing)
  end
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
  for i = 1, #self.AutoPickUpItemControls do
    self.AutoPickUpItemControls[i]:SetOnToggleChanged(self, self.PickUpTogOnValueChanged)
  end
end

function PreferenceUI:DontDoNothing()
end

function PreferenceUI:RefreshPickTogTog(tog)
  if tog.type ~= EItemType.Equipe and QiJiHelperData.pickupTab[tostring(tog.type)] then
    tog:SetIsOn(false)
  elseif tog.type == EItemType.Equipe then
    local rarityTab = string.split(tog.rarity, "#")
    local index = string.format("%s#%s", tog.type, rarityTab[1])
    if QiJiHelperData.pickupTab[index] then
      tog:SetIsOn(false)
    else
      tog:SetIsOn(true)
    end
  else
    tog:SetIsOn(true)
  end
end

function PreferenceUI:RefreshPreferenceBasic()
  self.sl_bgmSound.slider.value = GameSettingsData.musicVolume
  self.sl_effectSound.slider.value = GameSettingsData.soundVolume
  self.sl_speechSound.slider.value = GameSettingsData.speechVolume
  if GameSettingsData.joyStickMode == EJoyStickMode.Fixed then
    self.tog_fixedRocker.toggle.isOn = true
  else
    self.tog_movingRocker.toggle.isOn = true
  end
  self.btn_Deregister:SetActive(PlatformData.GetAuditPlatfromID() > 0)
end

function PreferenceUI:RefreshDisplay()
  for i = 1, #self.DisplayCampDpControls do
    self.DisplayCampDpControls[i].dropdown:SetValueWithoutNotify(GameSettingsData[self.DisplayCampDpControls[i].hideCampKey] - 1)
  end
  self.tog_hideSummonMonsterModel.toggle.isOn = GameSettingsData.hideSummonMonster
  self.tog_hideMonsterModel.toggle.isOn = GameSettingsData.hideMonsterModel
  self.tog_hideMonsterSkillEffect.toggle.isOn = GameSettingsData.hideMonsterSkillEffect
  self.tog_playerShowLimit.toggle.isOn = GameSettingsData.limitMaxVisiblePlayers
  local maxShowPlayerCount = math.min(GameSettingsData.maxVisiblePlayers, C_DefaultGameSettings.optionalMaxPlayers)
  self.sl_playerShowLimit:SetInteractable(GameSettingsData.limitMaxVisiblePlayers)
  ColorUtility.SetUIColor(self.lab_playerCount, GameSettingsData.limitMaxVisiblePlayers and Color.white or Color.gray)
  self.lab_playerCount:SetText(string.format("%d", maxShowPlayerCount))
  self.sl_playerShowLimit.slider.maxValue = C_DefaultGameSettings.optionalMaxPlayers
  self.sl_playerShowLimit.slider:SetValueWithoutNotify(maxShowPlayerCount)
  for i = 1, #self.FPSTogControls do
    if GameSettingsData.frameRate == self.FPSTogControls[i].fps then
      self.FPSTogControls[i].toggle.isOn = true
      break
    end
  end
  for i = 1, #self.ResolutionTogControls do
    if GameSettingsData.resolution == self.ResolutionTogControls[i].resolution then
      self.ResolutionTogControls[i].toggle.isOn = true
      break
    end
  end
  for i = 1, #self.QualityTogControls do
    if GameSettingsData.performQuality == self.QualityTogControls[i].quality then
      self.QualityTogControls[i].toggle.isOn = true
      break
    end
  end
end

function PreferenceUI:InitLanguageOptions()
  self.btn_dropdown:ClearOptions()
  self.btn_dropdown:AddOptions(ClientTable.cfg_Language_languageManager:GetOptionDataList())
end

function PreferenceUI:RefreshLanguage()
  self.go_language:SetActive(table.count(ClientTable.cfg_Language_languageManager:GetLanguageSortList()) > 1)
  self.btn_dropdown:SetSelectValue(Localization:GetCurSelectIndex())
end

function PreferenceUI:OnDropDownValueChangedCallback(ui, index)
  if Localization:GetCurSelectIndex() == index then
    return
  end
  local newLanguageCfg = ClientTable.cfg_Language_languageManager:GetLanguageSortList()[index + 1]
  local uiword = ""
  local langaugeStr = ""
  local newLang = newLanguageCfg.languageAcronym
  if newLanguageCfg.languageAcronym ~= "CN" then
    uiword = ClientTable.cfg_Ui_promptwordManager:TryGetValue(83)
    langaugeStr = uiword["content_" .. newLanguageCfg.languageAcronym]
  else
    langaugeStr = string.split(ClientTable.cfg_Global_globalManager:TryGetValue(2430022).effect, "&")[2]
  end
  local tipData = {
    id = 83,
    newLang = newLang,
    contentFormatArgs = string.format(langaugeStr, newLanguageCfg.showText),
    closeCallBack = function()
      self:RefreshLanguage()
    end,
    cancelAction = function()
      self:RefreshLanguage()
    end,
    okAction = function()
      if newLanguageCfg then
        Localization:SetLanguage(newLanguageCfg.languageAcronym)
      end
    end
  }
  TipUtility.QuickShowPrompt(tipData)
end

function PreferenceUI:RefreshBindAccount()
  local funcData = ClientTable.cfg_Function_functionManager:TryGetValue(4000023)
  if not funcData then
    return
  end
  local isShow = ConditionManager.Check4D(funcData.condition)
  self.BindAccount:SetActive(isShow)
  if not isShow then
    return
  end
  local giftData = ClientTable.cfg_Gift_giftManager:TryGetValue(670001)
  if giftData and giftData.reward then
    local boxData = ConfigManager.FindConfigs("cfg_Box_box", "boxId", giftData.reward)
    if boxData and 0 < #boxData then
      self.level_ItemContainer:SetData(boxData)
    end
  end
  local loginType = tonumber(LoginData.loginType)
  if not loginType then
    return
  end
  self.btn_BindAccount:SetActive(loginType == 1)
  self.btn_getReward:SetActive(not RefreshData.GetRefreshByKey(15000101) and loginType ~= 1)
  self.btn_received:SetActive(RefreshData.GetRefreshByKey(15000101) and loginType ~= 1)
  EventManager.Dispatch(Event.Fuc_SingleRefresh, {4000022})
end

function PreferenceUI:OnBindAccountSuccess(_, data)
  LoginData.loginType = data
  self:RefreshBindAccount()
end

function PreferenceUI:OnCountsRefresh(_, data)
  self:RefreshBindAccount()
end

function PreferenceUI:RefreshAllShortcutKeys()
  CustomShortcutKeysManager:ResetCurrentSelectedCustomParamData()
  local infoData = ShortcutKeysManager:GetAllShortcutKeysInfoData()
  if infoData == nil or next(infoData) == nil then
    return
  end
  self.shortcutKeyContainerTemplate:SetData(infoData)
end

function PreferenceUI:SetShortcutKeyEffectVisibleState(_shortcutKeyId)
  if _shortcutKeyId == nil then
    return
  end
  if self.shortcutKeyContainerTemplate == nil or self.shortcutKeyContainerTemplate.items == nil then
    return
  end
  for i, v in pairs(self.shortcutKeyContainerTemplate.items) do
    if v and v.itemTemp and v.itemTemp.data and v.itemTemp.SetEffectVisibleState then
      v.itemTemp:SetEffectVisibleState(_shortcutKeyId)
    end
  end
end

function PreferenceUI:RefreshTempItemShortcutKeys()
  if self.shortcutKeyContainerTemplate == nil or self.shortcutKeyContainerTemplate.items == nil then
    return
  end
  for i, v in pairs(self.shortcutKeyContainerTemplate.items) do
    if v and v.itemTemp and v.itemTemp.data and v.itemTemp.data:GetTempMappingId() then
      v.itemTemp:SetTempKeyMapPingName()
    end
  end
end

function PreferenceUI:btn_ShortcutKeyResetOnClick()
  TipUtility.QuickShowPrompt({
    id = PromptWordType.ShortcutKeyReset,
    cancelAction = function()
      UIManager.Hide(UIID.PromptTipUI)
    end,
    okAction = function()
      ShortcutKeysManager:Reset()
      ShortcutKeysManager:Save()
      ClientTable.cfg_Ui_wordManager:ShowContentQuickMsg("shortcutKeyResetSuccess")
      UIManager.Hide(UIID.PromptTipUI)
    end
  })
end

function PreferenceUI:btn_ShortcutKeySaveOnClick()
  TipUtility.QuickShowPrompt({
    id = PromptWordType.ShortcutKeySave,
    cancelAction = function()
      UIManager.Hide(UIID.PromptTipUI)
    end,
    okAction = function()
      ShortcutKeysManager:Save()
      ClientTable.cfg_Ui_wordManager:ShowContentQuickMsg("shortcutKeySaveSuccess")
      EventManager.Dispatch(Event.RefreshSaveShortcutKeys)
      UIManager.Hide(UIID.PromptTipUI)
    end
  })
end
