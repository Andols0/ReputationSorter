RS_Save = RS_Save or {headers = {}, numheaders = 0,order = {}}
ReputationSorter = {}

local function Storeheaders(data, lastheader)
	local SavedHeaders = RS_Save.headers
	if data.isChild == false then
		if not SavedHeaders[data.name] then
			SavedHeaders[data.name] = {
				pos = #RS_Save.order + 1
			}
			RS_Save.numheaders = RS_Save.numheaders + 1
			tinsert(RS_Save.order, data.name)
		end
	end
end

local function BuildList(numFactions)
	if numFactions == 0 then --in theory to a "loaded to early" check
		return --nope the way all our of here!
	end
	local lastheader
	local lastsubheader
	local headers = {}
	local RepInfo = {}

	for i = 1,  numFactions do
		local data =  C_Reputation.GetFactionDataByIndex(i)
		if data then
			data.factionIndex = i
			if data.isHeader then
				Storeheaders(data, lastheader)
				if data.isChild == false then
					if lastheader then
						headers[lastheader].last = i-1
					end
					lastheader = data.name
					headers[data.name] = {
						start = i,
					}
				end

			end
			RepInfo[i] = data
		end
	end
	headers[lastheader].last = numFactions

	local modRepInfo = {}
	for _,v in ipairs(RS_Save.order) do
		if headers[v] then
			for i = headers[v].start, headers[v].last do
				tinsert(modRepInfo,RepInfo[i])
			end
		end
	end
	return modRepInfo
end

local function CreateArrowButtons()
	for i, frame in pairs(ReputationFrame.ScrollBox:GetFrames()) do
		if not(frame.SortUpArrow) then
			CreateFrame("Button", nil, frame ,"SSortUpArrowTemplate", i)
			CreateFrame("Button", nil, frame ,"SSortDownArrowTemplate", i)
			frame:HookScript("OnEnter", function (self)
				if self.elementData.isHeader then
					self.SortUpArrow:Show()
					self.SortDownArrow:Show()
				end
			end)
			frame:HookScript("OnLeave", function (self)
				self.SortUpArrow:Hide()
				self.SortDownArrow:Hide()
			end)
		end
	end
end

local function Mod_RepFrame_Update()
	local numFactions = C_Reputation.GetNumFactions();
	local newDataProvider = CreateDataProvider(BuildList(numFactions));
	ReputationFrame.ScrollBox:SetDataProvider(newDataProvider, ScrollBoxConstants.RetainScrollPosition);
	CreateArrowButtons()
end

hooksecurefunc(ReputationFrame,"Update",Mod_RepFrame_Update)

function ReputationSorter.MoveUp(frame)
	local name = frame:GetParent().elementData.name
	local pos = RS_Save.headers[name].pos
	if pos == 1 then return end
	RS_Save.headers[name].pos  = pos - 1
	tremove(RS_Save.order,pos)
	tinsert(RS_Save.order, pos - 1, name)
	RS_Save.headers[RS_Save.order[pos]].pos = pos
	Mod_RepFrame_Update()
end

function ReputationSorter.MoveDown(frame)
	local name = frame:GetParent().elementData.name
	local pos = RS_Save.headers[name].pos
	if pos == #RS_Save.order then return end
	RS_Save.headers[name].pos = pos + 1
	tremove(RS_Save.order,pos)
	tinsert(RS_Save.order, pos + 1, name)
	RS_Save.headers[RS_Save.order[pos]].pos = pos
	Mod_RepFrame_Update()
end

	local Button = CreateFrame("Button","$parentRevertButton",ReputationFrame)
	Button:SetHeight(22)
	Button:SetWidth(22)
	Button:SetPoint("RIGHT",ReputationFrame.filterDropdown,"LEFT",-5)
	Button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
	Button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
	Button:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled");
	Button:Show()
	Button:SetFrameStrata("HIGH")
	Button:SetScript("OnEnter", function()
		GameTooltip:SetOwner(Button,"ANCHOR_RIGHT")
		GameTooltip:SetText("Reset to default sorting")
	end)
	Button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	Button:SetScript("OnClick", function()
	RS_Save = {headers = {}, numheaders = 0, order = {}}
	Mod_RepFrame_Update()
	end	)