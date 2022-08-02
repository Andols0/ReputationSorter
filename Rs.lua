----Version 9.0.2  Game Version 9.0.2
local AChange, q, ToggleUnused, Rs_info, Update_Rs_order, CleanRsorder, AddRsorder, newrow

local function Framecreation(num)
	local parent=_G["ReputationBar"..num]
	local ContainerFrame =CreateFrame("Frame", "$parentF", parent, BackdropTemplateMixin and "BackdropTemplate")
	ContainerFrame:SetHeight(20)
	ContainerFrame:SetWidth(48)
	ContainerFrame:SetPoint("TOPRIGHT",parent, "TOPRIGHT",-5,-1)
	ContainerFrame:SetBackdrop({bgFile = "Interface/TutorialFrame/TutorialFrameBackground",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }})
	ContainerFrame:SetBackdropColor(0,0,0,0)
	ContainerFrame:SetScript("OnLeave",function(self)
		if not(self:GetParent():IsMouseOver()) then
			self:Hide()
		end
	end)
	local UpArrow=CreateFrame("Button", "$parentSortUp",_G["ReputationBar"..num.."F"],"SSortUpArrowTemplate",num)
	local DownArrow = CreateFrame("Button", "$parentSortDown",_G["ReputationBar"..num.."F"],"SSortDownArrowTemplate",num)
	UpArrow:Show()
	DownArrow:Show()
	ContainerFrame:Hide()
end


local function eventHandler(self, event, ...)
	if event=="ADDON_LOADED" and ...=="ReputationSorter" then
		--Setup Buttonsetup
		for i=1,NUM_FACTIONS_DISPLAYED do
				Framecreation(i)
			_G["ReputationBar"..i]:HookScript("OnEnter", function (self)
				if _G[self:GetName().."ExpandOrCollapseButton"]:IsVisible() and not(self.child) then
					_G[self:GetName().."F"]:Show()
				end
			end)
			_G["ReputationBar"..i]:HookScript("OnLeave", function (self)
				if GetMouseFocus() then
					if GetMouseFocus():GetParent() then
						local fname=GetMouseFocus():GetParent():GetName()
						if not(string.find(fname, self:GetName())) then
							_G[self:GetName().."F"]:Hide()
						end
					else
						_G[self:GetName().."F"]:Hide()
					end
				else
					_G[self:GetName().."F"]:Hide()
				end
			end)
		end
		if Rs_order.collapsed then
			Rs_order.collapsed=nil
		end
	end
end


local eventframe = CreateFrame("FRAME", "RsEventframe");
eventframe:SetScript("OnEvent", eventHandler);
eventframe:RegisterEvent("ADDON_LOADED")

--local Rs_info
Rs_order={}

local function ReputationUpdate(showLFGPulse)
ReputationFrame.paragonFramesPool:ReleaseAll();

local numFactions = GetNumFactions();

Rs_info={}
Rs_info.numhead=0
for i=1, numFactions do
	Rs_info[i]={GetFactionInfo(i)}
	if Rs_info[i][9] then
		Rs_info.numhead=Rs_info.numhead+1
	end
end
-----Add a few extra rows for safety
	for i=#Rs_info+1,NUM_FACTIONS_DISPLAYED+5 do
		Rs_info[i]={}
	end


--------------------------First time setup-----------------------------------
	if not(Rs_order.Firsttime) then
		q=1
		for i=1, numFactions do
			local name,_,_,_,_,_,_,_, isHeader,_,_,_,isChild= unpack(Rs_info[i]);
			if isHeader and not(isChild) then
				if Rs_order[q] and not(i==Rs_order[q].start) then
					Rs_order[q].stop=i-1
					q=q+1
				end
				Rs_order[q]={}
				Rs_order[q].name=name
				Rs_order[q].start=i
			end
			if i==numFactions then
				Rs_order[q].stop=i
			end
		end
	Rs_order.Firsttime=1
	Rs_order.Nummax=numFactions
	end
-------------------------Did anything unexpected happend-------------------
	if not(AChange) and Rs_order.Nummax~=numFactions then
		AChange=true
		newrow=true
	end
-------------------------If a change----------------------------------------
	if AChange==true then

		AChange=false
		if ToggleUnused==true or newrow then
			ToggleUnused=false
			newrow=false
			if #Rs_order~=Rs_info.numhead then
				if #Rs_order>Rs_info.numhead then
					CleanRsorder(numFactions)
				else
					AddRsorder(numFactions)
				end
			end
		end
		Update_Rs_order(numFactions)
	end



--------------Make the list-------------------------------------------

	local Rs_Listan={}
	q=1
	for i=1 ,#Rs_order do
		for e=Rs_order[i].start,Rs_order[i].stop do
			Rs_Listan[q]=e
			q=q+1
		end
	end
	--To avoid nil errors
	for i=#Rs_Listan+1, NUM_FACTIONS_DISPLAYED+5 do
		table.insert(Rs_Listan,i,i)
	end


	-- Update scroll frame
	if ( not FauxScrollFrame_Update(ReputationListScrollFrame, numFactions, NUM_FACTIONS_DISPLAYED, REPUTATIONFRAME_FACTIONHEIGHT ) ) then
		ReputationListScrollFrameScrollBar:SetValue(0);
	end
	local factionOffset = FauxScrollFrame_GetOffset(ReputationListScrollFrame);

	local gender = UnitSex("player");

	for i=1, NUM_FACTIONS_DISPLAYED, 1 do
		local factionIndex = Rs_Listan[factionOffset + i];
		local factionRow = _G["ReputationBar"..i];
		local factionBar = _G["ReputationBar"..i.."ReputationBar"];
		local factionTitle = _G["ReputationBar"..i.."FactionName"];
		local factionButton = _G["ReputationBar"..i.."ExpandOrCollapseButton"];
		local factionStanding = _G["ReputationBar"..i.."ReputationBarFactionStanding"];
		local factionBackground = _G["ReputationBar"..i.."Background"];
		if ( factionIndex <= numFactions ) then
			local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canSetInactive = GetFactionInfo(factionIndex);
			factionRow.child=isChild
			factionTitle:SetText(name);
			if ( isCollapsed ) then
				factionButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
			else
				factionButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
			end
			factionRow.index = factionIndex;
			factionRow.isCollapsed = isCollapsed;

			local colorIndex = standingID;
			local factionStandingtext;

			if ( factionID and C_Reputation.IsFactionParagon(factionID) ) then
				local paragonFrame = ReputationFrame.paragonFramesPool:Acquire();
				paragonFrame.factionID = factionID;
				paragonFrame:SetPoint("RIGHT", factionRow, 11, 0);
				local currentValue, threshold, rewardQuestID, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID);
				C_Reputation.RequestFactionParagonPreloadRewardData(factionID);
				paragonFrame.Glow:SetShown(hasRewardPending);
				paragonFrame.Check:SetShown(hasRewardPending);
				paragonFrame:Show();
			end
			local isCapped;
			if (standingID == MAX_REPUTATION_REACTION) then
				isCapped = true;
			end

			-- check if this is a friendship faction
			local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID);
			if (friendID ~= nil) then
				factionStandingtext = friendTextLevel;
				if ( nextFriendThreshold ) then
					barMin, barMax, barValue = friendThreshold, nextFriendThreshold, friendRep;
				else
					-- max rank, make it look like a full bar
					barMin, barMax, barValue = 0, 1, 1;
					isCapped = true;
				end
				colorIndex = 5;								-- always color friendships green
				factionRow.friendshipID = friendID;			-- for doing friendship tooltip
			else
				factionStandingtext = GetText("FACTION_STANDING_LABEL"..standingID, gender);
				factionRow.friendshipID = nil;
			end

			factionStanding:SetText(factionStandingtext);

			--Normalize Values
			barMax = barMax - barMin;
			barValue = barValue - barMin;
			barMin = 0;

			factionRow.standingText = factionStandingtext;
			if ( isCapped ) then
				factionRow.rolloverText = nil;
			else
				factionRow.rolloverText = HIGHLIGHT_FONT_COLOR_CODE.." "..format(REPUTATION_PROGRESS_FORMAT, BreakUpLargeNumbers(barValue), BreakUpLargeNumbers(barMax))..FONT_COLOR_CODE_CLOSE;
			end
			factionBar:SetFillStyle("STANDARD_NO_RANGE_FILL");
			factionBar:SetMinMaxValues(0, barMax);
			factionBar:SetValue(barValue);
			local color = FACTION_BAR_COLORS[colorIndex];
			factionBar:SetStatusBarColor(color.r, color.g, color.b);

			factionBar.BonusIcon:SetShown(hasBonusRepGain);

			

			ReputationFrame_SetRowType(factionRow, isChild, isHeader, hasRep);

			factionRow:Show();

			-- Update details if this is the selected faction
			if ( atWarWith ) then
				_G["ReputationBar"..i.."ReputationBarAtWarHighlight1"]:Show();
				_G["ReputationBar"..i.."ReputationBarAtWarHighlight2"]:Show();
			else
				_G["ReputationBar"..i.."ReputationBarAtWarHighlight1"]:Hide();
				_G["ReputationBar"..i.."ReputationBarAtWarHighlight2"]:Hide();
			end
			if ( factionIndex == GetSelectedFaction() ) then
				if ( ReputationDetailFrame:IsShown() ) then
					ReputationDetailFactionName:SetText(name);
					ReputationDetailFactionDescription:SetText(description);
					if ( atWarWith ) then
						ReputationDetailAtWarCheckBox:SetChecked(true);
					else
						ReputationDetailAtWarCheckBox:SetChecked(false);
					end
					if ( canToggleAtWar and (not isHeader)) then
						ReputationDetailAtWarCheckBox:Enable();
						ReputationDetailAtWarCheckBoxText:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
					else
						ReputationDetailAtWarCheckBox:Disable();
						ReputationDetailAtWarCheckBoxText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
					end
					if ( not canSetInactive ) then
						ReputationDetailInactiveCheckBox:Enable();
						ReputationDetailInactiveCheckBoxText:SetTextColor(ReputationDetailInactiveCheckBoxText:GetFontObject():GetTextColor());
					else
						ReputationDetailInactiveCheckBox:Disable();
						ReputationDetailInactiveCheckBoxText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
					end
					if ( IsFactionInactive(factionIndex) ) then
						ReputationDetailInactiveCheckBox:SetChecked(true);
					else
						ReputationDetailInactiveCheckBox:SetChecked(false);
					end
					if ( isWatched ) then
						ReputationDetailMainScreenCheckBox:SetChecked(true);
					else
						ReputationDetailMainScreenCheckBox:SetChecked(false);
					end
					_G["ReputationBar"..i.."ReputationBarHighlight1"]:Show();
					_G["ReputationBar"..i.."ReputationBarHighlight2"]:Show();
				end
			else
				_G["ReputationBar"..i.."ReputationBarHighlight1"]:Hide();
				_G["ReputationBar"..i.."ReputationBarHighlight2"]:Hide();
			end
		else
			factionRow:Hide();
		end
	end
	if ( GetSelectedFaction() == 0 ) then
		ReputationDetailFrame:Hide();
	end
end


function Update_Rs_order(numFactions)
	local temp={}
	for i=1, #Rs_order do
		temp[Rs_order[i].name]=i
	end
	local lastname=unpack(Rs_info[1])
	for i=1, numFactions do
		local name,_,_,_,_,_,_,_,isHeader,_,_,_,isChild= unpack(Rs_info[i]);
		if isHeader and not(isChild) then
			if lastname ~=name then
				Rs_order[temp[lastname]].stop=i-1
			end
			lastname=name
			Rs_order[temp[name]]={}
			Rs_order[temp[name]].name=name
			Rs_order[temp[name]].start=i
		end
		if i==numFactions then
			Rs_order[temp[lastname]].stop=i
		end
		Rs_order.Nummax=numFactions
	end
end


hooksecurefunc("ReputationFrame_Update",ReputationUpdate)

----------------------------------Remove/Add Headers-------------------------

function CleanRsorder(numFactions)
	local temp={}
	for i=1, #Rs_order do
		temp[Rs_order[i].name]=i
	end
	for i=1, numFactions do
		local name,_,_,_,_,_,_,_,isHeader,_,_,_,isChild= unpack(Rs_info[i]);
		if isHeader and not(isChild) then
			if temp[name] then
				temp[name]=nil
			end
		end
		if i==numFactions then
			for k,v in pairs(temp) do
				table.remove(Rs_order,v)
			end
		end
	end
end

function AddRsorder(numFactions)
	local temp={}
	local kaboom --Lovely variable name
	for i=1, #Rs_order do
		temp[Rs_order[i].name]=i
	end
	for i=1, numFactions do
		local name,_,_,_,_,_,_,_,isHeader,_,_,_,isChild=unpack(Rs_info[i])
		if isHeader and not(isChild) then
			if not(temp[name]) then
				kaboom=1
				for k,k in pairs(temp) do
					kaboom=kaboom+1
				end
				temp[name]=kaboom
			Rs_order[temp[name]]={}
			Rs_order[temp[name]].name=name
			end
		end
	end
end

---------------------------------------Move up/down
function Rs_MoveUp(self)
	AChange=true
	local i=1
	local id=self:GetID()
	local namn,start,stop
	for i=1, #Rs_order do
		if Rs_order[i].name==_G["ReputationBar"..id.."FactionName"]:GetText() and i~=1 then
			namn=Rs_order[i].name
			start=Rs_order[i].start
			stop=Rs_order[i].stop
			table.remove(Rs_order,i)
			table.insert(Rs_order,i-1,{})
			Rs_order[i-1].name=namn
			Rs_order[i-1].start=start
			Rs_order[i-1].stop=stop
			break
		end
	end
	ReputationFrame_Update()
end


function Rs_MoveDown(self)
	AChange=true
	local i=1
	local id=self:GetID()
	local namn,start,stop
	for i=1, #Rs_order do
		if Rs_order[i].name==_G["ReputationBar"..id.."FactionName"]:GetText() and i~=#Rs_order then
			namn=Rs_order[i].name
			start=Rs_order[i].start
			stop=Rs_order[i].stop
			table.remove(Rs_order,i)
			table.insert(Rs_order,i+1,{})
			Rs_order[i+1].name=namn
			Rs_order[i+1].start=start
			Rs_order[i+1].stop=stop
			break
		end
	end
	ReputationFrame_Update()
end
-----------------------------------------------










