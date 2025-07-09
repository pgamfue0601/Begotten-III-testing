--[[
	Begotten 3
	Created by cash wednesday, gabs, DETrooper and alyousha35
--]]

local assassinDist = (800 * 800);
local bannerDist = (1024 * 1024);
local markedDist = (384 * 384);
local overlay;

local animalModels = {
	"models/animals/deer1.mdl",
	"models/animals/goat.mdl",
	"models/animals/bear.mdl",
	"models/animal_ragd/piratecat_leopard.mdl",
	"models/begotten/creatures/wolf.mdl",
};

function cwBeliefs:ClockworkInitialized()
	Clockwork.directory:AddCategory("Beliefs", "Beliefs are the primary means of progression in Begotten III. Faith (experience) can be earned from a variety of sources, such as dealing damage, consuming items, crafting and performing rituals, or residually over time in dangerous areas. Once enough faith has concentrated, your character will advance to their next Sacrament Level, granting the use of an Epiphany (skill point). Epiphanies can then be spent on unlocking beliefs.\n\nThere are several belief trees, each with different purposes and unique belief tree finishers. Belief trees or individual beliefs may be locked depending on several factors, such as the faith or subfaith of your character, their faction or subfaction, and traits or other beliefs taken.")
end

function cwBeliefs:PlayerCharacterInitialized(data)
	-- Reset belief outlines on character respawn.
	if self.highlightTargetOverride then
		self.highlightTargetOverride = nil;
	end
	
	if self.upgradedWarcryActive then
		self.upgradedWarcryActive = nil;
	end
	
	--[[if self.trout then
		self.trout = nil;
	end]]--
	
	if timer.Exists("tasteOfBloodTimer") then
		timer.Remove("tasteOfBloodTimer");
	end
	
	if timer.Exists("warcryTimer") then
		timer.Remove("warcryTimer");
	end
	
	for _, v in _player.Iterator() do
		if v.warcryTarget then
			v.warcryTarget = false;
		end
		
		if timer.Exists("deceitfulHighlightTimer_"..v:EntIndex()) then
			timer.Remove("deceitfulHighlightTimer_"..v:EntIndex());
		end
	end;
end

-- Called when a player's character screen info should be adjusted.
function cwBeliefs:PlayerAdjustCharacterScreenInfo(character, info)
	info.level = character.level or 1;
end

function cwBeliefs:PlayerCanSeeCommand(commandTable)
	if commandTable.requiredbeliefs then
		for i, v in ipairs(commandTable.requiredbeliefs) do
			if !Clockwork.Client:HasBelief(v) then
				return false;
			end
		end
	end
	
	if commandTable.onerequiredbelief then
		local has_belief = false;
		
		for i, v in ipairs(commandTable.onerequiredbelief) do
			if Clockwork.Client:HasBelief(v) then
				has_belief = true;
				
				break;
			end
		end
		
		if !has_belief then
			return false;
		end
	end
end

function cwBeliefs:GetEntityMenuOptions(entity, options)
	if (entity:GetClass() == "prop_ragdoll") then
		local player = Clockwork.entity:GetPlayer(entity);

		if (!player or !player:Alive()) then
			if entity:GetNWEntity("Player"):IsPlayer() or entity:GetNWEntity("Player") == game.GetWorld() or table.HasValue(animalModels, entity:GetModel()) then
				if (self:HasBelief("savage")) then
					options["Mutilate"] = "cwCorpseMutilate";
				end;
				
				if (self:HasBelief("heart_eater")) then
					options["Eat Heart"] = "cwEatHeart";
				end;
				
				if (self:HasBelief("primeval")) then
					options["Harvest Bones"] = "cwHarvestBones";
				end;
			end
		elseif player and player:Alive() then
			if self:HasBelief("doctor") then
				if !Clockwork.Client:IsWeaponRaised() then
					options["Diagnose"] = "cwDiagnose";
				end
			end
		end;
	elseif entity:IsPlayer() and entity:Alive() then
		if self:HasBelief("doctor") then
			if !Clockwork.Client:IsWeaponRaised() then
				options["Diagnose"] = "cwDiagnose";
			end
		end
	end;
end;

function cwBeliefs:CanPlayerDualWield()
	return self:HasBelief({"man_become_beast", "murder_artform", "repentant", "witch_druid"}, true);
end

local bearTrapDist = (256 * 256);
local warcryColor = Color(180, 0, 0, 255);
local troutColor = Color(120, 120, 120, 255);
local ravenColor = Color(0, 180, 0);
local iconoclastColor = Color(150, 150, 150);

-- This can be optimized more.
function cwBeliefs:AddEntityOutlines(outlines)
	if self.highlightTargetOverride then
		if IsValid(self.highlightTargetOverride) then
			self:DrawPlayerOutline(self.highlightTargetOverride, outlines, warcryColor);
		end
	end
	
	local localPlayer = Clockwork.Client;
	local playerPos = localPlayer:GetPos();
	
	if localPlayer:GetNetVar("faith") == "Faith of the Dark" then
		local hasAssassin = self:HasBelief("assassin");
		local hasDarkness = self:HasBelief("embrace_the_darkness");
		local isCOS = (localPlayer:GetFaction() == "Children of Satan");
		
		for _, v in _player.Iterator() do
			if v ~= localPlayer and v:HasInitialized() and v:Alive() and v:GetColor().a > 0 then
				if isCOS or hasDarkness then
					if v:GetNetVar("yellowBanner") then
						if (v:GetPos():DistToSqr(playerPos) <= bannerDist) then
							self:DrawPlayerOutline(v, outlines, Color(200, 200, 0, 255));
							
							continue;
						end
					end
					
					if isCOS then
						if v:GetNetVar("kinisgerOverride") then
							if (v:GetPos():DistToSqr(playerPos) <= assassinDist) then
								self:DrawPlayerOutline(v, outlines, Color(0, 225, 225, 255));
								
								continue;
							end
						end
					end
				end
				
				if hasAssassin and (v:Health() < v:GetMaxHealth() / 4 or v:IsRagdolled()) then
					if (v:GetPos():DistToSqr(playerPos) <= assassinDist) then
						self:DrawPlayerOutline(v, outlines, warcryColor);
						
						continue;
					end
				end
				
				if v:GetNetVar("markedBySatanist") then
					if (v:GetPos():DistToSqr(playerPos) <= markedDist) then
						self:DrawPlayerOutline(v, outlines, Color(150, 0, 150, 255));
					end
				end
			end;
		end;
	end
	
	if self.upgradedWarcryActive then
	
		if self.raven then
			for _, v in _player.Iterator() do
				if v.warcryTarget and v:Alive() and v:GetColor().a > 0 then
					self:DrawPlayerOutline(v, outlines, ravenColor);
				end;
			end;
		end;
		
		if self.iconoclast then
			for _, v in _player.Iterator() do
				if v.warcryTarget and v:Alive() and v:GetColor().a > 0 then
					self:DrawPlayerOutline(v, outlines, iconoclastColor);
				end;
			end;
		end; 
	end
	
	if cwSenses and self:HasBelief("the_black_sea") then
		if localPlayer:GetNetVar("senses") then
			for i, v in ipairs(ents.FindByClass("cw_bear_trap")) do
				if v:GetNWString("state") == "trap" then
					if playerPos:DistToSqr(playerPos) < bearTrapDist then
						if Clockwork.player:CanSeeEntity(Clockwork.Client, v) then
							outlines:Add(v, Color(200, 0, 0, 255), 2, true);
						end
					end
				end
			end
		end
	end
end

function cwBeliefs:DrawPlayerOutline(player, outlines, color)
	local moveType = player:GetMoveType();
	
	if (moveType == MOVETYPE_WALK or moveType == MOVETYPE_LADDER) then
		outlines:Add(player, color, 2, true);
		
		if IsValid(player.clothesEnt) then
			outlines:Add(player.clothesEnt, color, 2, true);
		end
	elseif player:IsRagdolled() then
		local ragdollEntity = player:GetRagdollEntity();
		
		if IsValid(ragdollEntity) then
			outlines:Add(ragdollEntity, color, 2, true);
			
			if IsValid(ragdollEntity.clothesEnt) then
				outlines:Add(ragdollEntity.clothesEnt, color, 2, true);
			end
		end
	end;
end;

-- Called when the target's marked status should be drawn.
function cwBeliefs:DrawTargetPlayerMarked(target, alpha, x, y)
	if(target:GetSharedVar("isThrall")) then return; end

	if target:GetNetVar("markedBySatanist") == true then
		if (target:Alive()) then
			if Clockwork.Client:GetNetVar("faith") == "Faith of the Dark" then
				local gender = "He";
				
				if (target:GetGender() == GENDER_FEMALE) then
					gender = "She";
				end;
			
				y = Clockwork.kernel:DrawInfo(Clockwork.kernel:ParseData(gender.." is marked for death for transgressions against the Dark Lord!"), x, y, Color(200, 0, 0), alpha);
				
				return y;
			end
		end
	end
end;

function cwBeliefs:ModifyStatusEffects(tab)
	if self:HasBelief("favored") then
		table.insert(tab, {text = "(+) Favored", color = Color(0, 225, 0)});
	end
end

netstream.Hook("DeceitfulHighlight", function(data)
	if IsValid(data) and data:IsPlayer() then
		cwBeliefs.highlightTargetOverride = data;
	end
	
	if timer.Exists("deceitfulHighlightTimer_"..data:EntIndex()) then
		timer.Remove("deceitfulHighlightTimer_"..data:EntIndex());
	end
	
	timer.Create("deceitfulHighlightTimer_"..data:EntIndex(), 30, 1, function()
		cwBeliefs.highlightTargetOverride = nil;
	end);
end);

netstream.Hook("TasteofBloodHighlight", function(data)
	local cwBeliefs = cwBeliefs;

	cwBeliefs.highlightTargetOverride = data;
	
	if timer.Exists("tasteOfBloodTimer") then
		timer.Remove("tasteOfBloodTimer");
	end
	
	if IsValid(data) and data:IsPlayer() then
		timer.Create("tasteOfBloodTimer", 180, 1, function()
			cwBeliefs.highlightTargetOverride = nil;
		end);
	end
end);

netstream.Hook("UpgradedWarcry", function(data)
	local cwBeliefs = cwBeliefs;
	
	cwBeliefs.upgradedWarcryActive = true;
	
	if cwBeliefs:HasBelief("watchful_raven") then
		if data then
			for i, v in ipairs(data) do
				if IsValid(v) then
					v.warcryTarget = true;
				end
			end
		end
		
		cwBeliefs.raven = true;
		
		timer.Simple(15, function()
			cwBeliefs.raven = false;
			
			for _, v in _player.Iterator() do
				if v.warcryTarget then
					v.warcryTarget = nil;
				end
			end
		end);
	
		return;
	end
	
	local faction = Clockwork.Client:GetFaction();
	local faith = Clockwork.Client:GetNetVar("faith");
	
	if faction == "Goreic Warrior" then
		local subfaction = Clockwork.Client:GetSubfaction()
					
		if subfaction == "Clan Grock" then
			if data then 
				for i, v in ipairs(data) do
					if IsValid(v) then
						v.warcryTarget = true;
					end
				end
			end
			
			cwBeliefs.iconoclast = true;
			
			timer.Simple(15, function()
				cwBeliefs.iconoclast = false;
				
				for _, v in _player.Iterator() do
					if v.warcryTarget then
						v.warcryTarget = nil;
					end
				end
			end);
		
			return;
		end
	end
	
	for _, v in _player.Iterator() do
		if v ~= Clockwork.Client and (v:HasInitialized()) then
			--if v:GetNetVar("faith") ~= faith then
				local vFaction = v:GetNetVar("kinisgerOverride") or v:GetFaction();
				
				if faction == "Errante" or vFaction ~= faction then
					if (v:GetPos():DistToSqr(Clockwork.Client:GetPos()) <= (800 * 800)) then
						v.warcryTarget = true;
					end;
				end
			--end
		end;
	end;
	
	--[[if cwBeliefs:HasBelief("fearsome_wolf") then
		if timer.Exists("warcryTimer") then
			timer.Remove("warcryTimer");
		end
		
		timer.Create("warcryTimer", 20, 1, function()
			cwBeliefs.upgradedWarcryActive = false;
			
			for _, v in _player.Iterator() do
				v.warcryTarget = false;
			end;
		end);
	else]]
		--[[if cwBeliefs:HasBelief("daring_trout") then
			cwBeliefs.trout = true;
		end]]--
		
		if timer.Exists("warcryTimer") then
			timer.Remove("warcryTimer");
		end
	
		timer.Create("warcryTimer", 10, 1, function()
			--[[if cwBeliefs.trout then
				cwBeliefs.trout = false;
			end]]--
			
			cwBeliefs.upgradedWarcryActive = false;
			
			--[[for _, v in _player.Iterator() do
				v.warcryTarget = false;
			end;]]--
		end);
	--end
end);