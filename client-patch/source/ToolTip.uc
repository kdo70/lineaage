class Tooltip extends UICommonAPI;

const TOOLTIP_MINIMUM_WIDTH = 144;
const TOOLTIP_SETITEM_MAX = 3;

var CustomTooltip m_Tooltip;
var DrawItemInfo m_Info;
var array<int> m_EquipmentIDs;
var array<string> m_EquipmentRows;
var array<int> m_EquipmentAttempts;

function OnLoad()
{
	RegisterEvent( EV_RequestTooltipInfo );
	RegisterEvent( EV_ChatMessage );
	RegisterEvent( EV_InventoryItemListEnd );
}

function OnEvent(int Event_ID, string param)
{
	switch( Event_ID )
	{
	case EV_ChatMessage:
		ReadEquipmentInfo(param);
		break;
	case EV_InventoryItemListEnd:
		RequestBypassToServer("_itemskills i");
		break;
	case EV_RequestTooltipInfo:
		HandleRequestTooltipInfo(param);
		break;
	}
}

function HandleRequestTooltipInfo(string param)
{
	local String TooltipType;
	local int SourceType;
	local ETooltipSourceType eSourceType;

	ClearTooltip();

	if (!ParseString(param, "TooltipType", TooltipType))
		return;

	if (!ParseInt(param, "SourceType", SourceType))
		return;

	eSourceType = ETooltipSourceType(SourceType);

	//////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////// Normal Tooltip /////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////////////
	if (TooltipType == "Text")
	{
		ReturnTooltip_NTT_TEXT(param, eSourceType, false);
	}
	else if (TooltipType == "Description")
	{
		ReturnTooltip_NTT_TEXT(param, eSourceType, true);
	}
	//////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////// ItemWnd Tooltip ////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////////////
	else if (TooltipType == "Action")
	{
		ReturnTooltip_NTT_ACTION(param, eSourceType);
	}
	else if (TooltipType == "Skill")
	{
		ReturnTooltip_NTT_SKILL(param, eSourceType);
	}
	else if (TooltipType == "NormalItem")
	{
		ReturnTooltip_NTT_NORMALITEM(param, eSourceType);
	}
	else if (TooltipType == "Shortcut")
	{
		ReturnTooltip_NTT_SHORTCUT(param, eSourceType);
	}
	else if (TooltipType == "AbnormalStatus")
	{
		ReturnTooltip_NTT_ABNORMALSTATUS(param, eSourceType);
	}
	else if (TooltipType == "RecipeManufacture")
	{
		ReturnTooltip_NTT_RECIPE_MANUFACTURE(param, eSourceType);
	}
	else if (TooltipType == "Recipe")
	{
		ReturnTooltip_NTT_RECIPE(param, eSourceType, false);
	}
	else if (TooltipType == "RecipePrice")
	{
		ReturnTooltip_NTT_RECIPE(param, eSourceType, true);
	}
	else if (TooltipType == "Inventory"
			|| TooltipType == "InventoryPrice1"
			|| TooltipType == "InventoryPrice2"
			|| TooltipType == "InventoryPrice1HideEnchant"
			|| TooltipType == "InventoryPrice1HideEnchantStackable"
			|| TooltipType == "InventoryPrice2PrivateShop")
	{
		ReturnTooltip_NTT_ITEM(param, TooltipType, eSourceType);
	}
	//////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////// ListCtrl Tooltip ///////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////////////
	else if (TooltipType == "PartyMatch")
	{
		ReturnTooltip_NTT_PARTYMATCH(param, eSourceType);
	}
	else if (TooltipType == "QuestInfo")
	{
		ReturnTooltip_NTT_QUESTINFO(param, eSourceType);
	}
	else if (TooltipType == "QuestList")
	{
		ReturnTooltip_NTT_QUESTLIST(param, eSourceType);
	}
	else if (TooltipType == "RaidList")
	{
		ReturnTooltip_NTT_RAIDLIST(param, eSourceType);
	}
	else if (TooltipType == "ClanInfo")
	{
		ReturnTooltip_NTT_CLANINFO(param, eSourceType);
	}
	/////////////////////////////////////////////////////
	// MANOR
	else if (TooltipType == "ManorSeedInfo"
			|| TooltipType == "ManorCropInfo"
			|| TooltipType == "ManorSeedSetting"
			|| TooltipType == "ManorCropSetting"
			|| TooltipType == "ManorDefaultInfo"
			|| TooltipType == "ManorCropSell")
	{
		ReturnTooltip_NTT_MANOR(param, TooltipType, eSourceType);
	}
}

function bool IsEnchantableItem(EItemParamType Type)
{
	return (Type == ITEMP_WEAPON || Type == ITEMP_ARMOR || Type == ITEMP_ACCESSARY || Type == ITEMP_SHIELD);
}

function ClearTooltip()
{
	m_Tooltip.SimpleLineCount = 0;
	m_Tooltip.MinimumWidth = 0;
	m_Tooltip.DrawList.Remove(0, m_Tooltip.DrawList.Length);
}

function StartItem()
{
	local DrawItemInfo infoClear;
	m_Info = infoClear;
}

function EndItem()
{
	m_Tooltip.DrawList.Length = m_Tooltip.DrawList.Length + 1;
	m_Tooltip.DrawList[m_Tooltip.DrawList.Length-1] = m_Info;
}

/////////////////////////////////////////////////////////////////////////////////
// TEXT
function ReturnTooltip_NTT_TEXT(string param, ETooltipSourceType eSourceType, bool bDesc)
{
	local string strText;
	local int ID;

	if (eSourceType == NTST_TEXT)
	{
		if (ParseString( param, "Text", strText))
		{
			if (Len(strText)>0)
			{
				if (bDesc)
				{
					m_Tooltip.MinimumWidth = TOOLTIP_MINIMUM_WIDTH;

					StartItem();
					m_Info.eType = DIT_TEXT;
					m_Info.t_color.R = 178;
					m_Info.t_color.G = 190;
					m_Info.t_color.B = 207;
					m_Info.t_color.A = 255;
					m_Info.t_strText = strText;
					EndItem();
				}
				else
				{
					StartItem();
					m_Info.eType = DIT_TEXT;
					m_Info.t_bDrawOneLine = true;
					m_Info.t_strText = strText;
					EndItem();
				}
			}
		}
		else if (ParseInt( param, "ID", ID))
		{
			if (ID>0)
			{
				StartItem();
				m_Info.eType = DIT_TEXT;
				m_Info.t_bDrawOneLine = true;
				m_Info.t_ID = ID;
				EndItem();
			}
		}
	}
	else
	{
		return;
	}

	ReturnTooltipInfo(m_Tooltip);
}

/////////////////////////////////////////////////////////////////////////////////
// INVENTORY Etc
function ReturnTooltip_NTT_ITEM(string param, String TooltipType, ETooltipSourceType eSourceType)
{
	local ItemInfo Item;

	local EItemType eItemType;
	local EEtcItemType eEtcItemType;

	local bool bLargeWidth;
	local string SlotString;
	local string strTmp;
	local int nTmp;
	local int idx;

	//제련효과
	local string ItemName;
	local int Quality;
	local int ColorR;
	local int ColorG;
	local int ColorB;
	local string strDesc1;
	local string strDesc2;
	local string strDesc3;

	//셋트아이템
	local array<int> arrID;
	local int SetID;
	local int ClassID;

	//아데나읽어주기
	local int weaponIconIndex;
	local string strAdena;
	local string strAdenaComma;
	local color	 AdenaColor;

	weaponIconIndex = -1;
	if (eSourceType == NTST_ITEM)
	{
		ParamToItemInfo(param, Item);
		RequestEquipmentInfo(Item.ServerID);

		eItemType = EItemType(Item.ItemType);
		if (eItemType == ITEM_WEAPON && (Item.RefineryOp1 != 0 || Item.RefineryOp2 != 0))
			Item.IconName = class'TooltipAugmentIcons'.static.Resolve(Item.ClassID, Item.IconName);
		eEtcItemType = EEtcItemType(Item.ItemSubType);

		//아이템 이름 취득
		ItemName = class'UIDATA_ITEM'.static.GetRefineryItemName( Item.Name, Item.RefineryOp1, Item.RefineryOp2 );

		//인첸트 ex) "+10"
		if (TooltipType != "InventoryPrice1HideEnchant"
			&& TooltipType != "InventoryPrice1HideEnchantStackable")
			AddTooltipItemEnchant(Item);

		//아이템 이름
		AddTooltipItemName(ItemName, Item);

		//Grade Mark
		AddTooltipItemGrade(Item);
		if (eItemType == ITEM_WEAPON)
		{
			strTmp = GetWeaponTypeString(Item.WeaponType);
			SlotString = GetSlotTypeString(Item.ItemType, Item.SlotBitType, Item.ArmorType);
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.bLineBreak = true;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_strText = SlotString;
			if (strTmp != "")
				m_Info.t_strText = strTmp $ " / " $ SlotString;
			EndItem();
			SetTooltipItemColor(176, 155, 121, 0);

			if (Item.IconName != "")
			{
				weaponIconIndex = m_Tooltip.DrawList.Length;
				StartItem();
				m_Info.eType = DIT_TEXTURE;
				m_Info.bLineBreak = true;
				m_Info.nOffSetY = -28;
				m_Info.u_strTexture = Item.IconName;
				m_Info.u_nTextureWidth = 32;
				m_Info.u_nTextureHeight = 32;
				m_Info.u_nTextureUWidth = 32;
				m_Info.u_nTextureUHeight = 32;
				EndItem();
			}
			AddItemTooltipDivider();
		}

		//아이템 갯수
		if (TooltipType != "InventoryPrice1HideEnchantStackable")
			AddTooltipItemCount(Item);

		//아이템이 아데나면, 읽어주기 스트링
		if (Item.ClassID==57)
		{
			//SimpleTooltip을 읽어주기스트링까지 보여준다.
			m_Tooltip.SimpleLineCount = 2;

			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.bLineBreak = true;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_strText = "(" $ ConvertNumToText(String(Item.ItemNum)) $ ")";
			EndItem();
		}

		//InventoryPrice1 타입
		if (TooltipType == "InventoryPrice1"
			|| TooltipType == "InventoryPrice1HideEnchant"
			|| TooltipType == "InventoryPrice1HideEnchantStackable")
		{
			strAdena = String(Item.Price);
			strAdenaComma = MakeCostString(strAdena);
			AdenaColor = GetNumericColor(strAdenaComma);

			//가격 : xxx,xxx,xxx
			AddTooltipItemOption(322, strAdenaComma $ " ", true, true, false);
			SetTooltipItemColor(AdenaColor.R, AdenaColor.G, AdenaColor.B, 0);

			//"아데나"
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_color = AdenaColor;
			m_Info.t_ID= 469;
			EndItem();

			//SimpleTooltip을 가격까지 보여준다.
			m_Tooltip.SimpleLineCount = 2;

			//읽어주기 스트링
			if (Item.Price>0)
			{
				m_Tooltip.SimpleLineCount = 3;
				AddTooltipItemOption(0, "(" $ ConvertNumToText(strAdena) $ ")", false, true, false);
				SetTooltipItemColor(AdenaColor.R, AdenaColor.G, AdenaColor.B, 0);
			}
		}

		//InventoryPrice2 타입
		if (TooltipType == "InventoryPrice2"
			|| TooltipType == "InventoryPrice2PrivateShop")
		{
			strAdena = String(Item.Price);
			strAdenaComma = MakeCostString(strAdena);
			AdenaColor = GetNumericColor(strAdenaComma);

			//가격 : 1개당
			AddTooltipItemOption2(322, 468, true, true, false);
			SetTooltipItemColor(AdenaColor.R, AdenaColor.G, AdenaColor.B, 0);

			//"xxx,xxx,xxx "
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_color = AdenaColor;
			m_Info.t_strText = " " $ strAdenaComma $ " ";
			EndItem();

			//"아데나"
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_color = AdenaColor;
			m_Info.t_ID= 469;
			EndItem();

			//SimpleTooltip을 가격까지 보여준다.
			m_Tooltip.SimpleLineCount = 2;

			//읽어주기 스트링
			if (Item.Price>0)
			{
				m_Tooltip.SimpleLineCount = 3;

				//"("
				StartItem();
				m_Info.eType = DIT_TEXT;
				m_Info.nOffSetY = 6;
				m_Info.bLineBreak = true;
				m_Info.t_bDrawOneLine = true;
				m_Info.t_color = AdenaColor;
				m_Info.t_strText = "(";
				EndItem();

				//"1개당"
				StartItem();
				m_Info.eType = DIT_TEXT;
				m_Info.nOffSetY = 6;
				m_Info.t_bDrawOneLine = true;
				m_Info.t_color = AdenaColor;
				m_Info.t_ID = 468;
				EndItem();

				StartItem();
				m_Info.eType = DIT_TEXT;
				m_Info.nOffSetY = 6;
				m_Info.t_bDrawOneLine = true;
				m_Info.t_color = AdenaColor;
				m_Info.t_strText = " " $ ConvertNumToText(strAdena) $ ")";
				EndItem();
			}
		}

		//InventoryPrice2PrivateShop 타입
		if (TooltipType == "InventoryPrice2PrivateShop")
			if (IsStackableItem(Item.ConsumeType) && Item.Reserved > 0)
			{
				//"구매개수 : xx"
				AddTooltipItemOption(808, String(Item.Reserved), true, true, false);
			}

		/////////////////////////////////////////////////////////////////////////////////////////
		// 아이템에 따른 각종 정보

		SlotString = GetSlotTypeString(Item.ItemType, Item.SlotBitType, Item.ArmorType);

		switch (eItemType)
		{

		// 1. WEAPON
		case ITEM_WEAPON:
			bLargeWidth = true;

			//Physical Damage
			AddWeaponTooltipAttack(Chr(1060) $ Chr(1080) $ Chr(1079) $ Chr(46) $ Chr(1040) $ Chr(1090) $ Chr(1082) $ Chr(46), Item.PhysicalDamage, GetPhysicalDamage(Item.WeaponType, Item.SlotBitType, Item.CrystalType, Item.Enchanted, Item.PhysicalDamage));

			//Masical Damage
			AddWeaponTooltipAttack(Chr(1052) $ Chr(1072) $ Chr(1075) $ Chr(46) $ Chr(1040) $ Chr(1090) $ Chr(1082) $ Chr(46), Item.MagicalDamage, GetMagicalDamage(Item.WeaponType, Item.SlotBitType, Item.CrystalType, Item.Enchanted, Item.MagicalDamage));

			//Attack Speed
			AddWeaponTooltipStat(Chr(1057) $ Chr(1082) $ Chr(1086) $ Chr(1088) $ Chr(46) $ Chr(1040) $ Chr(1090) $ Chr(1082) $ Chr(46), GetAttackSpeedString(Item.AttackSpeed));

			//SoulShot Count
			if (Item.SoulshotCount>0)
			{
				AddWeaponTooltipStat(Chr(1056) $ Chr(1072) $ Chr(1089) $ Chr(1093) $ Chr(1086) $ Chr(1076) $ Chr(32) $ Chr(1047) $ Chr(1072) $ Chr(1088) $ Chr(1103) $ Chr(1076) $ Chr(1086) $ Chr(1074) $ Chr(32) $ Chr(1044) $ Chr(1091) $ Chr(1096) $ Chr(1080), "X" $ FormatTooltipNumber(Item.SoulshotCount));
			}

			//SpiritShot Count
			if (Item.SpiritShotCount>0)
			{
				AddWeaponTooltipStat(Chr(1056) $ Chr(1072) $ Chr(1089) $ Chr(1093) $ Chr(1086) $ Chr(1076) $ Chr(32) $ Chr(1047) $ Chr(1072) $ Chr(1088) $ Chr(1103) $ Chr(1076) $ Chr(1086) $ Chr(1074) $ Chr(32) $ Chr(1044) $ Chr(1091) $ Chr(1093) $ Chr(1072), "X" $ FormatTooltipNumber(Item.SpiritshotCount));
			}

			//Weight
			AddTooltipItemOption(52, FormatTooltipNumber(Item.Weight), true, true, false);

			//MP Consume
			if (Item.MpConsume != 0)
			{
				AddTooltipItemOption(320, String(Item.MpConsume), true, true, false);
			}

			//제련효과
		break;

		// 2. ARMOR
		case ITEM_ARMOR:
			bLargeWidth = true;

			// Sheild
			if (Item.SlotBitType == 256 || Item.SlotBitType == 128)	//SBT_LHAND or SBT_RHAND
			{
				//Shield Defense
				AddTooltipItemOption(95, FormatTooltipNumber(GetShieldDefense(Item.CrystalType, Item.Enchanted, Item.ShieldDefense)), true, true, false);

				//Shield Defense Rate
				AddTooltipItemOption(317, String(Item.ShieldDefenseRate), true, true, false);

				//Avoid Modify
				AddTooltipItemOption(97, String(Item.AvoidModify), true, true, false);

				//Weight
				AddTooltipItemOption(52, FormatTooltipNumber(Item.Weight), true, true, false);
			}

			// Magical Armor
			else if (IsMagicalArmor(Item.ClassID))
			{
				//Slot Type
				if (Len(SlotString)>0)
					AddTooltipItemOption(0, SlotString, false, true, false);

				//MP Bonus
				AddTooltipItemOption(388, String(Item.MpBonus), true, true, false);

				//Physical Defense
				AddTooltipItemOption(95, FormatTooltipNumber(GetPhysicalDefense(Item.CrystalType, Item.Enchanted, Item.PhysicalDefense)), true, true, false);

				//Weight
				AddTooltipItemOption(52, FormatTooltipNumber(Item.Weight), true, true, false);
			}

			// Physical Armor
			else
			{
				//Slot Type
				if (Len(SlotString)>0)
					AddTooltipItemOption(0, SlotString, false, true, false);

				//Physical Defense
				AddTooltipItemOption(95, FormatTooltipNumber(GetPhysicalDefense(Item.CrystalType, Item.Enchanted, Item.PhysicalDefense)), true, true, false);

				//Weight
				AddTooltipItemOption(52, FormatTooltipNumber(Item.Weight), true, true, false);
			}

		break;

		// 3. ACCESSARY
		case ITEM_ACCESSARY:
			bLargeWidth = true;

			//Slot Type
			if (Len(SlotString)>0)
				AddTooltipItemOption(0, SlotString, false, true, false);

			//Masical Defense
			AddTooltipItemOption(99, FormatTooltipNumber(GetMagicalDefense(Item.CrystalType, Item.Enchanted, Item.MagicalDefense)), true, true, false);

			//Weight
			AddTooltipItemOption(52, FormatTooltipNumber(Item.Weight), true, true, false);
		break;

		// 4. QUEST
		case ITEM_QUESTITEM:
			bLargeWidth = true;

			//Slot Type
			if (Len(SlotString)>0)
				AddTooltipItemOption(0, SlotString, false, true, false);
		break;

		// 5. ETC
		case ITEM_ETCITEM:
			bLargeWidth = true;

			if (eEtcItemType == ITEME_PET_COLLAR)
			{
				//Pet Name
				if (Item.Damaged == 0)
					nTmp = 971;
				else
					nTmp = 970;
				AddTooltipItemOption2(969, nTmp, true, true, false);

				//Pet Level
				AddTooltipItemOption(88, String(Item.Enchanted), true, true, false);
			}
			else if (eEtcItemType == ITEME_TICKET_OF_LORD)
			{
				AddTooltipItemOption(972, String(Item.Enchanted), true, true, false);
			}
			else if (eEtcItemType == ITEME_LOTTO)
			{
				//Time
				AddTooltipItemOption(670, String(Item.Blessed), true, true, false);

				//Lotto Num
				AddTooltipItemOption(671, GetLottoString(Item.Enchanted, Item.Damaged), true, true, false);
			}
			else if (eEtcItemType == ITEME_RACE_TICKET)
			{
				//Time
				AddTooltipItemOption(670, String(Item.Enchanted), true, true, false);

				//Race Ticket Num
				AddTooltipItemOption(671, GetRaceTicketString(Item.Blessed), true, true, false);

				//Money
				AddTooltipItemOption(744, String(Item.Damaged*100), true, true, false);
			}
			//Weight
			AddTooltipItemOption(52, FormatTooltipNumber(Item.Weight), true, true, false);
		break;

		}
		/////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////

		//내구도 아이템
		if (Item.CurrentDurability >= 0 && Item.Durability > 0)
		{
			bLargeWidth = true;

			//빈공간
			AddTooltipItemBlank(12);

			//<투영 병기 정보>
			AddTooltipItemOption(1492, "", true, false, false);
			SetTooltipItemColor(255, 255, 255, 0);

			//사용가능 시간
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.bLineBreak = true;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_color.R = 163;
			m_Info.t_color.G = 163;
			m_Info.t_color.B = 163;
			m_Info.t_color.A = 255;
			m_Info.t_ID = 1493;
			EndItem();

			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.t_bDrawOneLine = true;
			if (Item.CurrentDurability+1 <= 5)
			{
				m_Info.t_color.R = 255;
				m_Info.t_color.G = 0;
				m_Info.t_color.B = 0;
			}
			else
			{
				m_Info.t_color.R = 176;
				m_Info.t_color.G = 155;
				m_Info.t_color.B = 121;
			}
			m_Info.t_color.A = 255;
			m_Info.t_strText = " " $ Item.CurrentDurability $ "/" $ Item.Durability;
			EndItem();

			//"교환/드롭 불가"
			AddTooltipItemOption(1491, "", true, false, false);

			//빈공간
			if (Len(Item.Description)>0)
			{
				AddTooltipItemBlank(12);
			}
		}

		//설명
		if (Len(Item.Description)>0)
		{
			bLargeWidth = true;
			AddItemTooltipDivider();

			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.bLineBreak = true;
			m_Info.t_color.R = 178;
			m_Info.t_color.G = 190;
			m_Info.t_color.B = 207;
			m_Info.t_color.A = 255;
			m_Info.t_strText = Item.Description;
			EndItem();
		}

		if (DrawEquipmentSkills(Item.ServerID))
			bLargeWidth = true;

		if (eItemType == ITEM_WEAPON && (Item.RefineryOp1 != 0 || Item.RefineryOp2 != 0))
		{
			//빈공간

			//"[제련효과]"
			AddItemSectionHeading(Chr(1069) $ Chr(1092) $ Chr(1092) $ Chr(1077) $ Chr(1082) $ Chr(1090) $ Chr(32) $ Chr(1079) $ Chr(1072) $ Chr(1095) $ Chr(1072) $ Chr(1088) $ Chr(1086) $ Chr(1074) $ Chr(1072) $ Chr(1085) $ Chr(1080) $ Chr(1103), "L2UI_CH3.QuestWnd.QuestWndInfoIcon_2");

			//컬러값 취득
			if (Item.RefineryOp2 != 0)
			{
				Quality = class'UIDATA_REFINERYOPTION'.static.GetQuality( Item.RefineryOp2 );
				GetRefineryColor(Quality, ColorR, ColorG, ColorB);
			}

			if (Item.RefineryOp1 != 0)
			{
				strDesc1 = "";
				strDesc2 = "";
				strDesc3 = "";
				if (class'UIDATA_REFINERYOPTION'.static.GetOptionDescription( Item.RefineryOp1, strDesc1, strDesc2, strDesc3 ))
				{
					if (Len(strDesc1)>0)
					{
						AddTooltipItemOption(0, strDesc1, false, true, false);
						SetTooltipItemColor(ColorR, ColorG, ColorB, 0);
					}
					if (Len(strDesc2)>0)
					{
						AddTooltipItemOption(0, strDesc2, false, true, false);
						SetTooltipItemColor(ColorR, ColorG, ColorB, 0);
					}
					if (Len(strDesc3)>0)
					{
						AddTooltipItemOption(0, strDesc3, false, true, false);
						SetTooltipItemColor(ColorR, ColorG, ColorB, 0);
					}
				}
			}

			if (Item.RefineryOp2 != 0)
			{
				strDesc1 = "";
				strDesc2 = "";
				strDesc3 = "";
				if (class'UIDATA_REFINERYOPTION'.static.GetOptionDescription( Item.RefineryOp2, strDesc1, strDesc2, strDesc3 ))
				{
					if (Len(strDesc1)>0)
					{
						AddTooltipItemOption(0, strDesc1, false, true, false);
						SetTooltipItemColor(ColorR, ColorG, ColorB, 0);

					}
					if (Len(strDesc2)>0)
					{
						AddTooltipItemOption(0, strDesc2, false, true, false);
						SetTooltipItemColor(ColorR, ColorG, ColorB, 0);
					}
					if (Len(strDesc3)>0)
					{
						AddTooltipItemOption(0, strDesc3, false, true, false);
						SetTooltipItemColor(ColorR, ColorG, ColorB, 0);
					}
				}
			}

			//"교환/드롭 불가"
			AddTooltipItemOption(1491, "", true, false, false);
			SetTooltipItemColor(ColorR, ColorG, ColorB, 0);

		}


		/////////////////////////////////////////////////////////////////////////////////////////
		// 셋트 아이템 정보
		if (Item.ClassID>0)
		{
			for (idx=0; idx<TOOLTIP_SETITEM_MAX; idx++)
			{
				//셋트아이템 리스트
				class'UIDATA_ITEM'.static.GetSetItemIDList(Item.ClassID, idx, arrID);
				for (SetID=0; SetID<arrID.Length; SetID++)
				{
					bLargeWidth = true;
					ClassID = arrID[SetID];
					if (Item.ClassID != ClassID)
					{
						strTmp = class'UIDATA_ITEM'.static.GetItemName(ClassID);
						if (Len(strTmp)>0)
						{
							StartItem();
							m_Info.eType = DIT_TEXT;
							m_Info.nOffSetY = 6;
							m_Info.bLineBreak = true;
							m_Info.t_bDrawOneLine = true;
							m_Info.t_color.R = 112;
							m_Info.t_color.G = 115;
							m_Info.t_color.B = 123;
							m_Info.t_color.A = 255;
							m_Info.t_strText = strTmp;
							ParamAdd(m_Info.Condition, "Type", "Equip");
							ParamAdd(m_Info.Condition, "ServerID", String(Item.ServerID));
							ParamAdd(m_Info.Condition, "EquipID", String(ClassID));
							ParamAdd(m_Info.Condition, "NormalColor", "112,115,123");
							ParamAdd(m_Info.Condition, "EnableColor", "176,185,205");
							EndItem();
						}
					}
				}
				//셋트효과
				strTmp = class'UIDATA_ITEM'.static.GetSetItemEffectDescription(Item.ClassID, idx);
				if (Len(strTmp)>0)
				{
					bLargeWidth = true;

					StartItem();
					m_Info.eType = DIT_TEXT;
					m_Info.nOffSetY = 6;
					m_Info.bLineBreak = true;
					m_Info.t_color.R = 128;
					m_Info.t_color.G = 127;
					m_Info.t_color.B = 103;
					m_Info.t_color.A = 255;
					m_Info.t_strText = strTmp;
					ParamAdd(m_Info.Condition, "Type", "SetEffect");
					ParamAdd(m_Info.Condition, "ServerID", String(Item.ServerID));
					ParamAdd(m_Info.Condition, "ClassID", String(Item.ClassID));
					ParamAdd(m_Info.Condition, "EffectID", String(idx));
					ParamAdd(m_Info.Condition, "NormalColor", "128,127,103");
					ParamAdd(m_Info.Condition, "EnableColor", "183,178,122");
					EndItem();
				}
			}
			//인첸트 셋트효과
			strTmp = class'UIDATA_ITEM'.static.GetSetItemEnchantEffectDescription(Item.ClassID);
			if (Len(strTmp)>0)
			{
				bLargeWidth = true;

				StartItem();
				m_Info.eType = DIT_TEXT;
				m_Info.nOffSetY = 6;
				m_Info.bLineBreak = true;
				m_Info.t_color.R = 74;
				m_Info.t_color.G = 92;
				m_Info.t_color.B = 104;
				m_Info.t_color.A = 255;
				m_Info.t_strText = strTmp;
				ParamAdd(m_Info.Condition, "Type", "EnchantEffect");
				ParamAdd(m_Info.Condition, "ServerID", String(Item.ServerID));
				ParamAdd(m_Info.Condition, "ClassID", String(Item.ClassID));
				ParamAdd(m_Info.Condition, "NormalColor", "74,92,104");
				ParamAdd(m_Info.Condition, "EnableColor", "111,146,169");
				EndItem();
			}
		}
	}
	else
	{
		return;
	}

	if (DrawFirstOwnership(Item.ServerID))
		bLargeWidth = true;

	if (bLargeWidth)
		m_Tooltip.MinimumWidth = TOOLTIP_MINIMUM_WIDTH;

	FitItemTooltipDecoration(weaponIconIndex);
	ReturnTooltipInfo(m_Tooltip);
}

/////////////////////////////////////////////////////////////////////////////////
// ACTION
function ReturnTooltip_NTT_ACTION(string param, ETooltipSourceType eSourceType)
{
	local ItemInfo Item;

	if (eSourceType == NTST_ITEM)
	{
		ParseString( param, "Name", Item.Name);
		ParseString( param, "Description", Item.Description);

		//액션 이름
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_strText = Item.Name;
		EndItem();

		//액션 설명
		if (Len(Item.Description)>0)
		{
			m_Tooltip.MinimumWidth = TOOLTIP_MINIMUM_WIDTH;

			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.t_bDrawOneLine = false;
			m_Info.bLineBreak = true;
			m_Info.t_color.R = 178;
			m_Info.t_color.G = 190;
			m_Info.t_color.B = 207;
			m_Info.t_color.A = 255;
			m_Info.t_strText = Item.Description;
			EndItem();
		}
	}
	else
	{
		return;
	}

	ReturnTooltipInfo(m_Tooltip);
}

/////////////////////////////////////////////////////////////////////////////////
// SKILL
function ReturnTooltip_NTT_SKILL(string param, ETooltipSourceType eSourceType)
{
	local ItemInfo Item;

	local EItemParamType eItemParamType;
	local EShortCutItemType eShortCutType;
	local int nTmp;
	local int SkillLevel;

	if (eSourceType == NTST_ITEM)
	{
		ParseString( param, "Name", Item.Name);
		ParseString( param, "AdditionalName", Item.AdditionalName);
		ParseString( param, "Description", Item.Description);
		ParseInt( param, "ClassID", Item.ClassID);
		ParseInt( param, "Level", Item.Level);

		eShortCutType = EShortCutItemType(Item.ItemSubType);
		eItemParamType = EItemParamType(Item.ItemType);
		SkillLevel = Item.Level;

		m_Tooltip.MinimumWidth = TOOLTIP_MINIMUM_WIDTH;

		//아이템 이름
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_strText = Item.Name;
		EndItem();

		if (Len(Item.AdditionalName)>0)
		{
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetX = 5;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_color.R = 255;
			m_Info.t_color.G = 217;
			m_Info.t_color.B = 105;
			m_Info.t_color.A = 255;
			m_Info.t_strText = Item.AdditionalName;
			EndItem();

			SkillLevel = class'UIDATA_SKILL'.static.GetEnchantSkillLevel( Item.ClassID, Item.Level );
		}

		//ex) " Lv "
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_strText = " ";
		EndItem();

		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_color.R = 163;
		m_Info.t_color.G = 163;
		m_Info.t_color.B = 163;
		m_Info.t_color.A = 255;
		m_Info.t_ID = 88;
		EndItem();

		//스킬 레빌
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_color.R = 176;
		m_Info.t_color.G = 155;
		m_Info.t_color.B = 121;
		m_Info.t_color.A = 255;
		m_Info.t_strText = " " $ SkillLevel;
		EndItem();

		//Operate Type
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.nOffSetY = 6;
		m_Info.bLineBreak = true;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_color.R = 176;
		m_Info.t_color.G = 155;
		m_Info.t_color.B = 121;
		m_Info.t_color.A = 255;
		m_Info.t_strText = class'UIDATA_SKILL'.static.GetOperateType( Item.ClassID, Item.Level );
		EndItem();

		//소모HP
		nTmp = class'UIDATA_SKILL'.static.GetHpConsume( Item.ClassID, Item.Level );
		if (nTmp>0)
		{
			AddTooltipItemOption(1195, String(nTmp), true, true, false);
		}

		//소모MP
		nTmp = class'UIDATA_SKILL'.static.GetMpConsume( Item.ClassID, Item.Level );
		if (nTmp>0)
		{
			AddTooltipItemOption(320, String(nTmp), true, true, false);
		}

		//유효거리
		nTmp = class'UIDATA_SKILL'.static.GetCastRange( Item.ClassID, Item.Level );
		if (nTmp>=0)
		{
			AddTooltipItemOption(321, String(nTmp), true, true, false);
		}

		//설명
		if (Len(Item.Description)>0)
		{
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.bLineBreak = true;
			m_Info.t_color.R = 178;
			m_Info.t_color.G = 190;
			m_Info.t_color.B = 207;
			m_Info.t_color.A = 255;
			m_Info.t_strText = Item.Description;
			EndItem();
		}
	}
	else
	{
		return;
	}

	ReturnTooltipInfo(m_Tooltip);
}

/////////////////////////////////////////////////////////////////////////////////
// ABNORMALSTATUS
function ReturnTooltip_NTT_ABNORMALSTATUS(string param, ETooltipSourceType eSourceType)
{
	local ItemInfo Item;

	local EItemParamType eItemParamType;
	local EShortCutItemType eShortCutType;

	if (eSourceType == NTST_ITEM)
	{
		ParseString( param, "Name", Item.Name);
		ParseString( param, "AdditionalName", Item.AdditionalName);
		ParseString( param, "Description", Item.Description);
		ParseInt( param, "ClassID", Item.ClassID);
		ParseInt( param, "Level", Item.Level);
		ParseInt( param, "Reserved", Item.Reserved);

		eShortCutType = EShortCutItemType(Item.ItemSubType);
		eItemParamType = EItemParamType(Item.ItemType);

		m_Tooltip.MinimumWidth = TOOLTIP_MINIMUM_WIDTH;

		//아이템 이름
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_strText = Item.Name;
		EndItem();

		if (Len(Item.AdditionalName)>0)
		{
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetX = 5;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_color.R = 255;
			m_Info.t_color.G = 217;
			m_Info.t_color.B = 105;
			m_Info.t_color.A = 255;
			m_Info.t_strText = Item.AdditionalName;
			EndItem();

			Item.Level = class'UIDATA_SKILL'.static.GetEnchantSkillLevel( Item.ClassID, Item.Level );
		}

		//ex) " Lv "
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_strText = " ";
		EndItem();

		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_color.R = 163;
		m_Info.t_color.G = 163;
		m_Info.t_color.B = 163;
		m_Info.t_color.A = 255;
		m_Info.t_ID = 88;
		EndItem();

		//스킬 레빌
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_color.R = 176;
		m_Info.t_color.G = 155;
		m_Info.t_color.B = 121;
		m_Info.t_color.A = 255;
		m_Info.t_strText = " " $ Item.Level;
		EndItem();

		//남은시간
		if (!IsDeBuff(Item.ClassID, Item.Level) && Item.Reserved>=0)
		{
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.bLineBreak = true;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_color.R = 163;
			m_Info.t_color.G = 163;
			m_Info.t_color.B = 163;
			m_Info.t_color.A = 255;
			m_Info.t_ID = 1199;
			EndItem();

			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_color.R = 163;
			m_Info.t_color.G = 163;
			m_Info.t_color.B = 163;
			m_Info.t_color.A = 255;
			m_Info.t_strText = " : ";
			EndItem();

			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_color.R = 176;
			m_Info.t_color.G = 155;
			m_Info.t_color.B = 121;
			m_Info.t_color.A = 255;
			m_Info.t_strText = MakeBuffTimeStr(Item.Reserved);
			ParamAdd(m_Info.Condition, "Type", "RemainTime");
			EndItem();
		}

		//설명
		if (Len(Item.Description)>0)
		{
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.bLineBreak = true;
			m_Info.t_color.R = 178;
			m_Info.t_color.G = 190;
			m_Info.t_color.B = 207;
			m_Info.t_color.A = 255;
			m_Info.t_strText = Item.Description;
			EndItem();
		}
	}
	else
	{
		return;
	}

	ReturnTooltipInfo(m_Tooltip);
}

/////////////////////////////////////////////////////////////////////////////////
// NORMALITEM
function ReturnTooltip_NTT_NORMALITEM(string param, ETooltipSourceType eSourceType)
{
	local ItemInfo Item;

	if (eSourceType == NTST_ITEM)
	{
		ParseString( param, "Name", Item.Name);
		ParseString( param, "Description", Item.Description);
		ParseString( param, "AdditionalName", Item.AdditionalName);
		ParseInt( param, "CrystalType", Item.CrystalType);

		//아이템 이름
		AddTooltipItemName(Item.Name, Item);

		//Grade Mark
		AddTooltipItemGrade(Item);

		//설명
		if (Len(Item.Description)>0)
		{
			m_Tooltip.MinimumWidth = TOOLTIP_MINIMUM_WIDTH;

			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.bLineBreak = true;
			m_Info.t_color.R = 178;
			m_Info.t_color.G = 190;
			m_Info.t_color.B = 207;
			m_Info.t_color.A = 255;
			m_Info.t_strText = Item.Description;
			EndItem();
		}
	}
	else
	{
		return;
	}

	ReturnTooltipInfo(m_Tooltip);
}

/////////////////////////////////////////////////////////////////////////////////
// RECIPE
function ReturnTooltip_NTT_RECIPE(string param, ETooltipSourceType eSourceType, bool bShowPrice)
{
	local ItemInfo Item;

	local string strAdena;
	local string strAdenaComma;
	local color	 AdenaColor;

	if (eSourceType == NTST_ITEM)
	{
		ParseString( param, "Name", Item.Name);
		ParseString( param, "Description", Item.Description);
		ParseString( param, "AdditionalName", Item.AdditionalName);
		ParseInt( param, "CrystalType", Item.CrystalType);
		ParseInt( param, "Weight", Item.Weight);
		ParseInt( param, "Price", Item.Price);

		//아이템 이름
		AddTooltipItemName(Item.Name, Item);

		//Grade Mark
		AddTooltipItemGrade(Item);

		//가격
		if (bShowPrice)
		{
			strAdena = String(Item.Price);
			strAdenaComma = MakeCostString(strAdena);
			AdenaColor = GetNumericColor(strAdenaComma);

			//가격 : xxx,xxx,xxx
			AddTooltipItemOption(641, strAdenaComma $ " ", true, true, false);
			SetTooltipItemColor(AdenaColor.R, AdenaColor.G, AdenaColor.B, 0);

			//"아데나"
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_color = AdenaColor;
			m_Info.t_ID= 469;
			EndItem();

			//읽어주기 스트링
			AddTooltipItemOption(0, "(" $ ConvertNumToText(strAdena) $ ")", false, true, false);
			SetTooltipItemColor(AdenaColor.R, AdenaColor.G, AdenaColor.B, 0);
		}

		//Weight
		AddTooltipItemOption(52, FormatTooltipNumber(Item.Weight), true, true, false);

		//설명
		if (Len(Item.Description)>0)
		{
			m_Tooltip.MinimumWidth = TOOLTIP_MINIMUM_WIDTH;

			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.bLineBreak = true;
			m_Info.t_color.R = 178;
			m_Info.t_color.G = 190;
			m_Info.t_color.B = 207;
			m_Info.t_color.A = 255;
			m_Info.t_strText = Item.Description;
			EndItem();
		}
	}
	else
	{
		return;
	}

	ReturnTooltipInfo(m_Tooltip);
}

/////////////////////////////////////////////////////////////////////////////////
// SHORTCUT
function ReturnTooltip_NTT_SHORTCUT(string param, ETooltipSourceType eSourceType)
{
	local ItemInfo Item;

	local EItemParamType eItemParamType;
	local EShortCutItemType eShortCutType;
	local string ItemName;

	if (eSourceType == NTST_ITEM)
	{
		ParseString( param, "Name", Item.Name);
		ParseString( param, "AdditionalName", Item.AdditionalName);
		ParseInt( param, "ClassID", Item.ClassID);
		ParseInt( param, "Level", Item.Level);
		ParseInt( param, "Reserved", Item.Reserved);
		ParseInt( param, "Enchanted", Item.Enchanted);
		ParseInt( param, "ItemType", Item.ItemType);
		ParseInt( param, "ItemSubType", Item.ItemSubType);
		ParseInt( param, "CrystalType", Item.CrystalType);
		ParseInt( param, "ConsumeType", Item.ConsumeType);
		ParseInt( param, "RefineryOp1", Item.RefineryOp1);
		ParseInt( param, "RefineryOp2", Item.RefineryOp2);
		ParseInt( param, "ItemNum", Item.ItemNum);
		ParseInt( param, "MpConsume", Item.MpConsume);

		eShortCutType = EShortCutItemType(Item.ItemSubType);
		eItemParamType = EItemParamType(Item.ItemType);

		//아이템 이름 취득
		ItemName = class'UIDATA_ITEM'.static.GetRefineryItemName( Item.Name, Item.RefineryOp1, Item.RefineryOp2 );

		switch (eShortCutType)
		{
		case SCIT_ITEM:
			//인첸트 ex) "+10"
			AddTooltipItemEnchant(Item);

			//아이템 이름
			AddTooltipItemName(ItemName, Item);

			//Grade Mark
			AddTooltipItemGrade(Item);

			//아이템 갯수
			AddTooltipItemCount(Item);
		break;
		case SCIT_SKILL:
			//아이템 이름
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_strText = ItemName;
			EndItem();

			if (Len(Item.AdditionalName)>0)
			{
				StartItem();
				m_Info.eType = DIT_TEXT;
				m_Info.nOffSetX = 5;
				m_Info.t_bDrawOneLine = true;
				m_Info.t_color.R = 255;
				m_Info.t_color.G = 217;
				m_Info.t_color.B = 105;
				m_Info.t_color.A = 255;
				m_Info.t_strText = Item.AdditionalName;
				EndItem();

				Item.Level = class'UIDATA_SKILL'.static.GetEnchantSkillLevel( Item.ClassID, Item.Level );
			}

			//ex) " Lv "
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_strText = " ";
			EndItem();

			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_color.R = 163;
			m_Info.t_color.G = 163;
			m_Info.t_color.B = 163;
			m_Info.t_color.A = 255;
			m_Info.t_ID = 88;
			EndItem();

			//스킬 레빌
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_color.R = 176;
			m_Info.t_color.G = 155;
			m_Info.t_color.B = 121;
			m_Info.t_color.A = 255;
			m_Info.t_strText = " " $ Item.Level;
			EndItem();

			//MP소모량
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_strText = " (";
			EndItem();

			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_ID = 91;
			EndItem();

			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_strText = ":" $ Item.MpConsume $ ")";
			EndItem();
		break;

		case SCIT_ACTION:
		case SCIT_MACRO:
		case SCIT_RECIPE:
			//아이템 이름
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_strText = ItemName;
			EndItem();
		break;
		}
	}
	else
	{
		return;
	}

	ReturnTooltipInfo(m_Tooltip);
}

/////////////////////////////////////////////////////////////////////////////////
// RECIPE_MANUFACTURE
function ReturnTooltip_NTT_RECIPE_MANUFACTURE(string param, ETooltipSourceType eSourceType)
{
	local ItemInfo Item;

	if (eSourceType == NTST_ITEM)
	{
		ParseString( param, "Name", Item.Name);
		ParseString( param, "Description", Item.Description);
		ParseString( param, "AdditionalName", Item.AdditionalName);
		ParseInt( param, "Reserved", Item.Reserved);
		ParseInt( param, "CrystalType", Item.CrystalType);
		ParseInt( param, "ItemNum", Item.ItemNum);

		m_Tooltip.MinimumWidth = TOOLTIP_MINIMUM_WIDTH;

		//아이템 이름
		AddTooltipItemName(Item.Name, Item);

		//Grade Mark
		AddTooltipItemGrade(Item);

		//ex) "필요수 : 2"
		AddTooltipItemOption(736, String(Item.Reserved), true, true, false);

		//ex) "보유수 : 0"
		AddTooltipItemOption(737, String(Item.ItemNum), true, true, false);

		//설명
		if (Len(Item.Description)>0)
		{
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.nOffSetY = 6;
			m_Info.bLineBreak = true;
			m_Info.t_color.R = 178;
			m_Info.t_color.G = 190;
			m_Info.t_color.B = 207;
			m_Info.t_color.A = 255;
			m_Info.t_strText = Item.Description;
			EndItem();
		}
	}
	else
	{
		return;
	}

	ReturnTooltipInfo(m_Tooltip);
}

/////////////////////////////////////////////////////////////////////////////////
// PLEDGEINFO
function ReturnTooltip_NTT_CLANINFO(string param, ETooltipSourceType eSourceType)
{
	local LVDataRecord record;

	if (eSourceType == NTST_LIST)
	{
		ParamToRecord( param, record );

		//ex) "직업 : 엘븐메이지"
		AddTooltipItemOption(391, GetClassType(int(record.LVDataList[2].szData)), true, true, true);
	}
	else
	{
		return;
	}

	ReturnTooltipInfo(m_Tooltip);
}

/////////////////////////////////////////////////////////////////////////////////
// PARTYMATCH
function ReturnTooltip_NTT_PARTYMATCH(string param, ETooltipSourceType eSourceType)
{
	local LVDataRecord record;

	if (eSourceType == NTST_LIST)
	{
		ParamToRecord( param, record );

		//ex) "직업 : 엘븐메이지"
		AddTooltipItemOption(391, GetClassType(int(record.LVDataList[1].szData)), true, true, true);
	}
	else
	{
		return;
	}

	ReturnTooltipInfo(m_Tooltip);
}

/////////////////////////////////////////////////////////////////////////////////
// QUESTLIST
function ReturnTooltip_NTT_QUESTLIST(string param, ETooltipSourceType eSourceType)
{
	local LVDataRecord record;

	local int nTmp;

	if (eSourceType == NTST_LIST)
	{
		ParamToRecord( param, record );

		//퀘스트 이름
		AddTooltipItemOption(1200, record.LVDataList[0].szData, true, true, true);

		//반복성
		switch(record.LVDataList[3].nReserved1)
		{
		case 0:
		case 2:
			nTmp = 861;
			break;
		case 1:
		case 3:
			nTmp = 862;
			break;
		}
		AddTooltipItemOption2(1202, nTmp, true, true, false);
	}
	else
	{
		return;
	}

	ReturnTooltipInfo(m_Tooltip);
}

/////////////////////////////////////////////////////////////////////////////////
// RAIDLIST
function ReturnTooltip_NTT_RAIDLIST(string param, ETooltipSourceType eSourceType)
{
	local LVDataRecord record;

	if (eSourceType == NTST_LIST)
	{
		ParamToRecord( param, record );

		if (Len(record.szReserved)<1)
			return;

		m_Tooltip.MinimumWidth = TOOLTIP_MINIMUM_WIDTH;

		//레이드 설명
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = false;
		m_Info.t_color.R = 178;
		m_Info.t_color.G = 190;
		m_Info.t_color.B = 207;
		m_Info.t_color.A = 255;
		m_Info.t_strText = record.szReserved;
		EndItem();
	}
	else
	{
		return;
	}

	ReturnTooltipInfo(m_Tooltip);
}

/////////////////////////////////////////////////////////////////////////////////
// QUESTINFO
function ReturnTooltip_NTT_QUESTINFO(string param, ETooltipSourceType eSourceType)
{
	local LVDataRecord record;

	local int nTmp;
	local int Width1;
	local int Width2;
	local int Height;

	if (eSourceType == NTST_LIST)
	{
		ParamToRecord( param, record );

		//퀘스트 이름
		AddTooltipItemOption(1200, record.LVDataList[0].szData, true, true, true);

		//수행조건
		AddTooltipItemOption(1201, record.LVDataList[1].szData, true, true, false);

		//Width결정!
		GetTextSize(GetSystemString(1200) $ " : " $ record.LVDataList[0].szData, Width1, Height);
		GetTextSize(GetSystemString(1201) $ " : " $ record.LVDataList[1].szData, Width2, Height);
		if (Width2>Width1)
			Width1 = Width2;
		if (TOOLTIP_MINIMUM_WIDTH>Width1)
			Width1 = TOOLTIP_MINIMUM_WIDTH;
		m_Tooltip.MinimumWidth = Width1 + 30;

		//추천레벨
		AddTooltipItemOption(922, record.LVDataList[2].szData, true, true, false);

		//반복성
		switch(record.LVDataList[3].nReserved1)
		{
		case 0:
		case 2:
			nTmp = 861;
			break;
		case 1:
		case 3:
			nTmp = 862;
			break;
		}
		AddTooltipItemOption2(1202, nTmp, true, true, false);

		//퀘스트설명
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.nOffSetY = 6;
		m_Info.t_bDrawOneLine = false;
		m_Info.bLineBreak = true;
		m_Info.t_color.R = 178;
		m_Info.t_color.G = 190;
		m_Info.t_color.B = 207;
		m_Info.t_color.A = 255;
		m_Info.t_strText = record.szReserved;
		EndItem();
	}
	else
	{
		return;
	}

	ReturnTooltipInfo(m_Tooltip);
}

/////////////////////////////////////////////////////////////////////////////////
// MANOR
function ReturnTooltip_NTT_MANOR(string param, string TooltipType, ETooltipSourceType eSourceType)
{
	local LVDataRecord record;

	local int idx1;
	local int idx2;
	local int idx3;

	if (eSourceType == NTST_LIST)
	{
		ParamToRecord( param, record );

		if (TooltipType == "ManorSeedInfo")
		{
			idx1 = 4;
			idx2 = 5;
			idx3 = 6;
		}
		else if (TooltipType == "ManorCropInfo")
		{
			idx1 = 5;
			idx2 = 6;
			idx3 = 7;
		}
		else if (TooltipType == "ManorSeedSetting")
		{
			idx1 = 7;
			idx2 = 8;
			idx3 = 9;
		}
		else if (TooltipType == "ManorCropSetting")
		{
			idx1 = 9;
			idx2 = 10;
			idx3 = 11;
		}
		else if (TooltipType == "ManorDefaultInfo")
		{
			idx1 = 1;
			idx2 = 4;
			idx3 = 5;
		}
		else if (TooltipType == "ManorCropSell")
		{
			idx1 = 7;
			idx2 = 8;
			idx3 = 9;
		}

		// 씨앗 or 작물 이름
		AddTooltipItemOption(0, record.LVDataList[0].szData, false, true, true);

		// 레벨
		AddTooltipItemOption(537, record.LVDataList[idx1].szData, true, true, false);

		// 보상 타입1
		AddTooltipItemOption(1134, record.LVDataList[idx2].szData, true, true, false);

		// 보상 타입2
		AddTooltipItemOption(1135, record.LVDataList[idx3].szData, true, true, false);
	}
	else
	{
		return;
	}

	ReturnTooltipInfo(m_Tooltip);
}

function string FormatTooltipNumber(int Value)
{
	local string Digits, Groups;
	local int FirstDigit;

	Digits = String(Value);
	if (Value < 0)
		FirstDigit = 1;
	while (Len(Digits) - FirstDigit > 3)
	{
		Groups = " " $ Right(Digits, 3) $ Groups;
		Digits = Left(Digits, Len(Digits) - 3);
	}
	return Digits $ Groups;
}


//"XXX : YYYY" 형태의 TooltipItem을 편하게 추가해 준다.
function AddWeaponTooltipAttack(string Title, int BaseDamage, int TotalDamage)
{
	AddWeaponTooltipStat(Title, FormatTooltipNumber(TotalDamage));
	if (TotalDamage <= BaseDamage)
		return;

	StartItem();
	m_Info.eType = DIT_TEXT;
	m_Info.nOffSetY = 6;
	m_Info.t_bDrawOneLine = true;
	m_Info.t_color.R = 163;
	m_Info.t_color.G = 163;
	m_Info.t_color.B = 163;
	m_Info.t_color.A = 255;
	m_Info.t_strText = " (" $ FormatTooltipNumber(BaseDamage);
	EndItem();

	m_Info.t_color.R = 128;
	m_Info.t_color.G = 201;
	m_Info.t_color.B = 148;
	m_Info.t_strText = " +" $ FormatTooltipNumber(TotalDamage - BaseDamage);
	EndItem();

	m_Info.t_color.R = 163;
	m_Info.t_color.G = 163;
	m_Info.t_color.B = 163;
	m_Info.t_strText = ")";
	EndItem();
}


function AddWeaponTooltipStat(string Title, string Value)
{
	local int titleIndex;

	titleIndex = m_Tooltip.DrawList.Length;
	AddTooltipItemOption(0, Value, true, true, false);
	m_Tooltip.DrawList[titleIndex].t_strText = Title;
}

function AddTooltipItemOption(int TitleID, string Content, bool bTitle, bool bContent, bool IamFirst)
{
	if (bTitle)
	{
		StartItem();
		m_Info.eType = DIT_TEXT;
		if (!IamFirst)
			m_Info.nOffSetY = 6;
		m_Info.bLineBreak = true;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_color.R = 163;
		m_Info.t_color.G = 163;
		m_Info.t_color.B = 163;
		m_Info.t_color.A = 255;
		m_Info.t_ID = TitleID;
		EndItem();
	}

	if (bContent)
	{
		if (bTitle)
		{
			StartItem();
			m_Info.eType = DIT_TEXT;
			if (!IamFirst)
				m_Info.nOffSetY = 6;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_color.R = 163;
			m_Info.t_color.G = 163;
			m_Info.t_color.B = 163;
			m_Info.t_color.A = 255;
			m_Info.t_strText = " : ";
			EndItem();
		}

		StartItem();
		m_Info.eType = DIT_TEXT;
		if (!IamFirst)
			m_Info.nOffSetY = 6;
		if (!bTitle)
			m_Info.bLineBreak = true;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_color.R = 176;
		m_Info.t_color.G = 155;
		m_Info.t_color.B = 121;
		m_Info.t_color.A = 255;
		m_Info.t_strText = Content;
		EndItem();
	}
}

//"XXX : YYYY" 형태의 TooltipItem을 편하게 추가해 준다.
//SYSSTRING : SYSSTRING
function AddTooltipItemOption2(int TitleID, int ContentID, bool bTitle, bool bContent, bool IamFirst)
{
	if (bTitle)
	{
		StartItem();
		m_Info.eType = DIT_TEXT;
		if (!IamFirst)
			m_Info.nOffSetY = 6;
		m_Info.bLineBreak = true;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_color.R = 163;
		m_Info.t_color.G = 163;
		m_Info.t_color.B = 163;
		m_Info.t_color.A = 255;
		m_Info.t_ID = TitleID;
		EndItem();
	}

	if (bContent)
	{
		if (bTitle)
		{
			StartItem();
			m_Info.eType = DIT_TEXT;
			if (!IamFirst)
				m_Info.nOffSetY = 6;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_color.R = 163;
			m_Info.t_color.G = 163;
			m_Info.t_color.B = 163;
			m_Info.t_color.A = 255;
			m_Info.t_strText = " : ";
			EndItem();
		}

		StartItem();
		m_Info.eType = DIT_TEXT;
		if (!IamFirst)
			m_Info.nOffSetY = 6;
		if (!bTitle)
			m_Info.bLineBreak = true;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_color.R = 176;
		m_Info.t_color.G = 155;
		m_Info.t_color.B = 121;
		m_Info.t_color.A = 255;
		m_Info.t_ID = ContentID;
		EndItem();
	}
}

//아이템의 색상을 다시 설정해준다.
function SetTooltipItemColor(int R, int G, int B, int Offset)
{
	local int idx;
	idx = m_Tooltip.DrawList.Length-1-Offset;
	m_Tooltip.DrawList[idx].t_color.R = R;
	m_Tooltip.DrawList[idx].t_color.G = G;
	m_Tooltip.DrawList[idx].t_color.B = B;
	m_Tooltip.DrawList[idx].t_color.A = 255;
}

//빈공간의 TooltipItem을 추가한다.
function FitItemTooltipDecoration(int WeaponIconIndex)
{
	local int i, rowWidth, maxWidth, width, height, headerWidth;
	local string caption;
	local DrawItemInfo item;

	maxWidth = Max(m_Tooltip.MinimumWidth, 140);
	for (i = 0; i < m_Tooltip.DrawList.Length; i++)
	{
		item = m_Tooltip.DrawList[i];
		if (i == WeaponIconIndex)
			headerWidth = maxWidth;
		if (item.bLineBreak)
			rowWidth = 0;

		if (item.eType == DIT_TEXTURE && (item.u_strTexture == "L2UI_CH3.InventoryWnd.inventory_tab2" || item.u_strTexture == "L2UI.Tooltip.Tool08"))
		{
			rowWidth = item.u_nTextureWidth;
		}
		else if (item.eType == DIT_TEXTURE)
		{
			rowWidth += item.nOffSetX + item.u_nTextureWidth;
		}
		else if (item.eType == DIT_TEXT && item.t_bDrawOneLine)
		{
			caption = item.t_strText;
			if (item.t_ID != 0)
				caption = GetSystemString(item.t_ID);
			GetTextSize(caption, width, height);
			rowWidth += item.nOffSetX + width;
		}
		maxWidth = Max(maxWidth, rowWidth);
	}
	if (WeaponIconIndex >= 0)
	{
		maxWidth = Max(maxWidth, headerWidth + 36);
		m_Tooltip.DrawList[WeaponIconIndex].nOffSetX = maxWidth - 32;
	}
	for (i = 0; i < m_Tooltip.DrawList.Length; i++)
	{
		item = m_Tooltip.DrawList[i];
		if (i == WeaponIconIndex)
			headerWidth = maxWidth;
		if (item.eType != DIT_TEXTURE)
			continue;
		if (item.u_strTexture == "L2UI_CH3.InventoryWnd.inventory_tab2")
		{
			m_Tooltip.DrawList[i].u_nTextureWidth = maxWidth;
			m_Tooltip.DrawList[i + 1].nOffSetX = 3 - maxWidth;
		}
		else if (item.u_strTexture == "L2UI.Tooltip.Tool08")
			m_Tooltip.DrawList[i].u_nTextureWidth = maxWidth;
	}
}

function AddItemTooltipDivider(optional bool Flush)
{
	if (!Flush)
		AddTooltipItemBlank(2);
	StartItem();
	m_Info.eType = DIT_TEXTURE;
	m_Info.bLineBreak = true;
	m_Info.u_strTexture = "L2UI.Tooltip.Tool08";
	m_Info.u_nTextureWidth = 140;
	m_Info.u_nTextureHeight = 1;
	m_Info.u_nTextureUWidth = 8;
	m_Info.u_nTextureUHeight = 1;
	EndItem();
	if (!Flush)
		AddTooltipItemBlank(2);
}

function AddItemSectionHeading(string Title, string Icon)
{
	AddTooltipItemBlank(3);
	AddItemTooltipDivider(true);

	StartItem();
	m_Info.eType = DIT_TEXTURE;
	m_Info.bLineBreak = true;
	m_Info.u_strTexture = "L2UI_CH3.InventoryWnd.inventory_tab2";
	m_Info.u_nTextureWidth = 140;
	m_Info.u_nTextureHeight = 16;
	m_Info.u_nTextureUWidth = 1;
	m_Info.u_nTextureUHeight = 1;
	EndItem();

	StartItem();
	m_Info.eType = DIT_TEXTURE;
	m_Info.nOffSetX = -137;
	m_Info.nOffSetY = 1;
	m_Info.u_strTexture = Icon;
	m_Info.u_nTextureWidth = 16;
	m_Info.u_nTextureHeight = 16;
	m_Info.u_nTextureUWidth = 16;
	m_Info.u_nTextureUHeight = 16;
	EndItem();

	StartItem();
	m_Info.eType = DIT_TEXT;
	m_Info.t_bDrawOneLine = true;
	m_Info.nOffSetY = 2;
	m_Info.t_strText = Title;
	EndItem();
	SetTooltipItemColor(190, 185, 173, 0);
	AddItemTooltipDivider(true);
}


function AddTooltipItemBlank(int Height)
{
	StartItem();
	m_Info.eType = DIT_BLANK;
	m_Info.b_nHeight = Height;
	EndItem();
}

//인첸트
function AddTooltipItemEnchant(ItemInfo Item)
{
	local EItemParamType eItemParamType;

	eItemParamType = EItemParamType(Item.ItemType);
	if (Item.Enchanted>0 && IsEnchantableItem(eItemParamType))
	{
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_color.R = 176;
		m_Info.t_color.G = 155;
		m_Info.t_color.B = 121;
		m_Info.t_color.A = 255;
		m_Info.t_strText = "+" $ FormatTooltipNumber(Item.Enchanted) $ " ";
		EndItem();
	}
}

//아이템 이름 + AdditionalName
function int EquipmentIndex(int ServerID, bool Create)
{
	local int i;
	if (ServerID <= 0)
		return -1;
	for (i = 0; i < m_EquipmentIDs.Length; i++)
		if (m_EquipmentIDs[i] == ServerID)
			return i;
	if (!Create)
		return -1;
	m_EquipmentIDs.Insert(i, 1);
	m_EquipmentRows.Insert(i, 1);
	m_EquipmentAttempts.Insert(i, 1);
	m_EquipmentIDs[i] = ServerID;
	return i;
}

function ReadEquipmentInfo(string param)
{
	local string text;
	local array<string> fields;
	local int idx;
	local int tag;

	if (!ParseString(param, "Msg", text))
		return;
	tag = InStr(text, "~ik~");
	if (tag < 0)
		return;
	text = Mid(text, tag + 4);
	if (text == "reset")
	{
		m_EquipmentIDs.Length = 0;
		m_EquipmentRows.Length = 0;
		m_EquipmentAttempts.Length = 0;
		return;
	}
	if (Split(text, ",", fields) < 2)
		return;
	idx = EquipmentIndex(int(fields[0]), true);
	if (idx >= 0)
		m_EquipmentRows[idx] = text;
}

function RequestEquipmentInfo(int ServerID)
{
	local int idx;
	idx = EquipmentIndex(ServerID, true);
	if (idx < 0 || Len(m_EquipmentRows[idx]) > 0 || m_EquipmentAttempts[idx] >= 3)
		return;
	m_EquipmentAttempts[idx] = m_EquipmentAttempts[idx] + 1;
	RequestBypassToServer("_itemskills " $ String(ServerID));
}

function ApplyEquipmentNameColor(int ServerID)
{
	local array<string> fields;
	local array<string> rgb;
	local int idx;
	idx = EquipmentIndex(ServerID, false);
	if (idx < 0 || Split(m_EquipmentRows[idx], ",", fields) < 2)
		return;
	if (Split(fields[1], "-", rgb) != 3)
		return;
	m_Info.t_color.R = int(rgb[0]);
	m_Info.t_color.G = int(rgb[1]);
	m_Info.t_color.B = int(rgb[2]);
	m_Info.t_color.A = 255;
}

function string GetItemProfileField(int ServerID, string marker)
{
	local array<string> fields;
	local int idx, count, i;

	idx = EquipmentIndex(ServerID, false);
	if (idx < 0)
		return "";
	count = Split(m_EquipmentRows[idx], ",", fields);
	for (i = 2; i < count; i++)
		if (Left(fields[i], 1) == marker)
			return Mid(fields[i], 1);
	return "";
}

function string DecodeItemProfile(string encoded)
{
	local int i, j, digit, value;
	local string output;

	if (Len(encoded) > 140 || Len(encoded) % 4 != 0)
		return "";
	for (i = 0; i < Len(encoded); i += 4)
	{
		value = 0;
		for (j = 0; j < 4; j++)
		{
			digit = InStr("0123456789abcdef", Mid(encoded, i + j, 1));
			if (digit < 0)
				return "";
			value = value * 16 + digit;
		}
		output = output $ Chr(value);
	}
	return output;
}

function bool DrawFirstOwnership(int ServerID)
{
	local string creator, date;
	creator = DecodeItemProfile(GetItemProfileField(ServerID, "c"));
	date = GetItemProfileField(ServerID, "d");
	if (creator == "" || date == "")
		return false;

	AddItemSectionHeading(Chr(1057) $ Chr(1074) $ Chr(1077) $ Chr(1076) $ Chr(1077) $ Chr(1085) $ Chr(1080) $ Chr(1103) $ Chr(32) $ Chr(1086) $ Chr(32) $ Chr(1074) $ Chr(1083) $ Chr(1072) $ Chr(1076) $ Chr(1077) $ Chr(1083) $ Chr(1100) $ Chr(1094) $ Chr(1077), "L2UI_CH3.QuestWnd.QuestWndInfoIcon_1");
	AddTooltipItemOption(0, (Chr(1055) $ Chr(1077) $ Chr(1088) $ Chr(1074) $ Chr(1099) $ Chr(1081) $ Chr(32) $ Chr(1074) $ Chr(1083) $ Chr(1072) $ Chr(1076) $ Chr(1077) $ Chr(1083) $ Chr(1077) $ Chr(1094)) $ ": ", false, true, false);
	SetTooltipItemColor(163, 163, 163, 0);
	StartItem();
	m_Info.eType = DIT_TEXT;
	m_Info.t_bDrawOneLine = true;
	m_Info.nOffSetY = 6;
	m_Info.t_strText = creator;
	EndItem();
	SetTooltipItemColor(176, 155, 121, 0);
	AddTooltipItemOption(0, (Chr(1044) $ Chr(1072) $ Chr(1090) $ Chr(1072)) $ ": ", false, true, false);
	SetTooltipItemColor(163, 163, 163, 0);
	StartItem();
	m_Info.eType = DIT_TEXT;
	m_Info.t_bDrawOneLine = true;
	m_Info.nOffSetY = 6;
	m_Info.t_strText = date;
	EndItem();
	SetTooltipItemColor(176, 155, 121, 0);
	return true;
}

function string EquipmentSkillType(string kind, int id, int level)
{
	switch (kind)
	{
	case "a": return Chr(1040) $ Chr(1082) $ Chr(1090) $ Chr(1080) $ Chr(1074) $ Chr(1085) $ Chr(1086) $ Chr(1077);
	case "p": return Chr(1055) $ Chr(1072) $ Chr(1089) $ Chr(1089) $ Chr(1080) $ Chr(1074) $ Chr(1085) $ Chr(1086) $ Chr(1077);
	case "c": return Chr(1064) $ Chr(1072) $ Chr(1085) $ Chr(1089) $ Chr(1086) $ Chr(1074) $ Chr(1086) $ Chr(1077);
	case "t": return Chr(1055) $ Chr(1077) $ Chr(1088) $ Chr(1077) $ Chr(1082) $ Chr(1083) $ Chr(1102) $ Chr(1095) $ Chr(1072) $ Chr(1077) $ Chr(1084) $ Chr(1086) $ Chr(1077);
	case "o": return Chr(1044) $ Chr(1088) $ Chr(1091) $ Chr(1075) $ Chr(1086) $ Chr(1077);
	}
	return class'UIDATA_SKILL'.static.GetOperateType(id, level);
}

function bool DrawEquipmentSkills(int ServerID)
{
	local array<string> fields;
	local array<string> pair;
	local int idx, i, id, level, count;
	local string title, icon, description, types, skillType;
	local bool drawn;

	idx = EquipmentIndex(ServerID, false);
	if (idx < 0)
		return false;
	types = GetItemProfileField(ServerID, "k");
	count = Split(m_EquipmentRows[idx], ",", fields);
	if (count <= 2)
		return false;
	for (i = 2; i < count && i < 12; i++)
	{
		pair.Length = 0;
		if (Split(fields[i], "-", pair) != 2)
			continue;
		id = int(pair[0]);
		level = int(pair[1]);
		if (id <= 0 || level <= 0)
			continue;
		if (!drawn)
		{
			AddItemSectionHeading(Chr(1069) $ Chr(1092) $ Chr(1092) $ Chr(1077) $ Chr(1082) $ Chr(1090) $ Chr(32) $ Chr(1084) $ Chr(1086) $ Chr(1076) $ Chr(1080) $ Chr(1092) $ Chr(1080) $ Chr(1082) $ Chr(1072) $ Chr(1094) $ Chr(1080) $ Chr(1080), "L2UI_CH3.QuestWnd.QuestWndInfoIcon_3");
			AddTooltipItemBlank(2);
			drawn = true;
		}
		else
			AddItemTooltipDivider();
		title = class'UIDATA_SKILL'.static.GetName(id, level);
		skillType = EquipmentSkillType(Mid(types, i - 2, 1), id, level);
		icon = class'UIDATA_SKILL'.static.GetIconName(id, level);
		description = class'UIDATA_SKILL'.static.GetDescription(id, level);
		if (title == "")
			title = "Skill " $ String(id);
		if (icon != "")
		{
			StartItem();
			m_Info.eType = DIT_TEXTURE;
			m_Info.bLineBreak = true;
			m_Info.u_strTexture = icon;
			m_Info.u_nTextureWidth = 16;
			m_Info.u_nTextureHeight = 16;
			m_Info.u_nTextureUWidth = 32;
			m_Info.u_nTextureUHeight = 32;
			EndItem();
		}
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.bLineBreak = icon == "";
		m_Info.t_bDrawOneLine = true;
		m_Info.t_strText = " " $ title;
		EndItem();
		SetTooltipItemColor(190, 186, 177, 0);

		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_strText = " Lv. " $ String(level);
		EndItem();
		SetTooltipItemColor(176, 155, 121, 0);
		if (skillType != "")
		{
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.t_bDrawOneLine = true;
			m_Info.t_strText = " - " $ skillType;
			EndItem();
			SetTooltipItemColor(176, 155, 121, 0);
		}
		if (description != "")
		{
			StartItem();
			m_Info.eType = DIT_TEXT;
			m_Info.bLineBreak = true;
			m_Info.t_strText = description;
			EndItem();
			SetTooltipItemColor(178, 190, 207, 0);
		}
	}
	return drawn;
}

function AddTooltipItemName(string Name, ItemInfo Item)
{
	local string itemTitle;
	itemTitle = DecodeItemProfile(GetItemProfileField(Item.ServerID, "t"));
	if (Len(itemTitle) == 0)
		itemTitle = Item.AdditionalName;

	StartItem();
	m_Info.eType = DIT_TEXT;
	m_Info.t_bDrawOneLine = true;
	m_Info.t_strText = Name;
	ApplyEquipmentNameColor(Item.ServerID);
	EndItem();

	//Additional Name
	if (Len(itemTitle) > 0)
	{
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_color.R = 255;
		m_Info.t_color.G = 217;
		m_Info.t_color.B = 105;
		m_Info.t_color.A = 255;
		m_Info.t_strText = " " $ itemTitle;
		EndItem();
	}
}

//Grade Mark
function AddTooltipItemGrade(ItemInfo Item)
{
	local string strTmp;

	strTmp = GetItemGradeString(Item.CrystalType);
	if (Len(strTmp)>0)
	{
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_strText = " ";
		EndItem();

		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_strText = "`" $ strTmp $ "`";
		EndItem();
	}
}

//Stackable Count
function AddTooltipItemCount(ItemInfo Item)
{
	if (IsStackableItem(Item.ConsumeType))
	{
		StartItem();
		m_Info.eType = DIT_TEXT;
		m_Info.t_bDrawOneLine = true;
		m_Info.t_strText = " (" $ MakeCostString(String(Item.ItemNum)) $ ")";
		EndItem();
	}
}

//제련 색상
function GetRefineryColor(int Quality, out int R, out int G, out int B)
{
	switch (Quality)
	{
	case 1:
		R = 187;
		G = 181;
		B = 138;
	break;
	case 2:
		R = 132;
		G = 174;
		B = 216;
	break;
	case 3:
		R = 193;
		G = 112;
		B = 202;
	break;
	case 4:
		R = 225;
		G = 109;
		B = 109;
	break;
	default:
		R = 187;
		G = 181;
		B = 138;
	break;
	}
}
