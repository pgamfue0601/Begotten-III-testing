--[[
	Begotten III: Jesus Wept
	By: DETrooper, cash wednesday, gabs, alyousha35

	Other credits: kurozael, Alex Grist, Mr. Meow, zigbomb
--]]

local Clockwork = Clockwork;
local RunConsoleCommand = RunConsoleCommand;
local pairs = pairs;
local ScrH = ScrH;
local ScrW = ScrW;
local table = table;
local vgui = vgui;
local math = math;

local PANEL = {};

-- Called when the panel is initialized.
function PANEL:Init()
	local smallTextFont = Clockwork.option:GetFont("menu_text_small");
	local scrH = ScrH();
	local scrW = ScrW();

	self.createTime = SysTime();
	
	self:SetPos(0, 0);
	self:SetSize(scrW, scrH);
	self:SetPaintBackground(false);
	self:SetMouseInputEnabled(true);
	self:SetKeyboardInputEnabled(true);
	
	self.panelList = vgui.Create("cwPanelList", self);
 	self.panelList:SetPadding(2);
 	self.panelList:SetSpacing(3);
 	self.panelList:SizeToContents();
	
	self.disconnectButton = vgui.Create("cwLabelButton", self);
	self.disconnectButton:SetFont(smallTextFont);
	self.disconnectButton:SetText("DESCONECTAR");
	self.disconnectButton:FadeIn(0.5);
	self.disconnectButton:SetCallback(function(panel)
		RunConsoleCommand("disconnect");
	end);
	self.disconnectButton:SizeToContents();
	self.disconnectButton:SetMouseInputEnabled(true);
	self.disconnectButton:SetPos((scrW * 0.2) - (self.disconnectButton:GetWide() / 2), scrH * 0.9);
		
	self.continueButton = vgui.Create("cwLabelButton", self);
	self.continueButton:SetFont(smallTextFont);
	self.continueButton:SetText("CONTINUAR");
	self.continueButton:FadeIn(0.5);
	self.continueButton:SetCallback(function(panel)
		netstream.Start("QuizCompleted", true);
	end);
	self.continueButton:SizeToContents();
	self.continueButton:SetMouseInputEnabled(true);
	self.continueButton:SetPos((scrW * 0.8) - (self.continueButton:GetWide() / 2), scrH * 0.9);
end;

-- Called when the panel is painted.
function PANEL:Paint(w, h)
	Clockwork.kernel:RegisterBackgroundBlur(self, self.createTime);
	
	derma.SkinHook("Paint", "Panel", self);
	
	return true;
end;

-- A function to populate the panel.
function PANEL:Populate()
	local smallTextFont = Clockwork.option:GetFont("menu_text_small");
	local quizQuestions = Clockwork.quiz:GetQuestions();
	local questions = {};
	local scrH = ScrH();
	local scrW = ScrW();
	
	self.questionsForm = vgui.Create("DForm");
	self.questionsForm:SetName(Clockwork.quiz:GetName());
	self.questionsForm:SetPadding(4);
	self.questionsForm.Header:SetEnabled(false);
	
	self.panelList:Clear(true);
	
	local label = vgui.Create("cwInfoText", self);
		label:SetText("Si alguna de las respuestas son incorrectas, serás expulsado.");
		label:SetInfoColor("orange");
	self.panelList:AddItem(label);

	self.panelList:AddItem(self.questionsForm);
	
	for k, v in pairs(quizQuestions) do
		questions[k] = {k, v};
	end;
	
	table.sort(questions, function(a, b)
		return a[2].question < b[2].question;
	end);
	
	for k, v in pairs(questions) do
		local panel = vgui.Create("DComboBox", self.questionsForm);
		local question = vgui.Create("DLabel", self.questionsForm);
		local key = v[1];
			
		self.questionsForm:AddItem(question);
			
		question:SetText(v[2].question);
		question:SetDark(true);
		question:SizeToContents();
		question:SetTextColor(Color(255, 255, 255, 255));
			
		-- Called when an option is selected.
		function panel:OnSelect(index, value, data)
			netstream.Start("QuizAnswer", {key, index});
		end;
			
		for k2, v2 in pairs(v[2].possibleAnswers) do
			panel:AddChoice(v2);
		end;
		
		self.questionsForm:AddItem(panel);
	end;
end;

-- Called when the layout should be performed.
function PANEL:PerformLayout(w, h)
	local scrW = ScrW();
	local scrH = ScrH();
	
	self.panelList:SetSize(scrW * 0.5, math.min(self.panelList.pnlCanvas:GetTall() + 32, ScrH() * 0.75));
	self.panelList:SetPos((scrW / 2) - (self.panelList:GetWide() / 2), (scrH / 2) - (self.panelList:GetTall() / 2));
	
	derma.SkinHook("Layout", "Panel", self);
end;

-- Called each frame.
function PANEL:Think()
	self:InvalidateLayout(true);
end;

vgui.Register("cwQuiz", PANEL, "DPanel");