local PANEL = {}

function PANEL:Init( )
	self:SetSkin( Pointshop2.Config.DermaSkin )
	self.settings = {}
	
	self:SetSize( 850, 600 )
	self:SetTitle( "Drops Configuration" )
	
	self.infoPanel = vgui.Create( "DInfoPanel", self )
	self.infoPanel:Dock( TOP )
	self.infoPanel:SetInfo( "Drops System", 
[[The drops system works like this: 
- Every few minutes (or after every round) each player gets a chance to get a drop
- If a player is lucky they get a drop. To decide which drop they receive, the table below is used.
If a gamemode has an integration plugin, drops are given at round end, else they are given at the configured interval.
]] )
	self.infoPanel:DockMargin( 0, 5, 0, 0 )
	
	self.actualSettings = vgui.Create( "DSettingsPanel", self )
	self.actualSettings:Dock( LEFT )
	self.actualSettings:AutoAddSettingsTable( { 
		DropsSettings = Pointshop2.GetModule( "Pointshop 2 DLC" ).Settings.Server.DropsSettings,
		BroadcastDropsSettings = Pointshop2.GetModule( "Pointshop 2 DLC" ).Settings.Server.BroadcastDropsSettings,
		DropsTableSettings = Pointshop2.GetModule( "Pointshop 2 DLC" ).Settings.Server.DropsTableSettings
	} )
	self.actualSettings:DockMargin( 0, 0, 0, 5 )
	self.actualSettings:SetWide( 250 )
	
	self.itemsTable = vgui.Create( "DItemChanceTable", self )
	self.itemsTable:Dock( FILL )
	self.itemsTable:DockMargin( 5, 5, 5, 5 )
	self.itemsTable:DockPadding( 5, 5, 5, 5 )
	Derma_Hook( self.itemsTable, "Paint", "Paint", "InnerPanel" )
	
	self.bottom = vgui.Create( "DPanel", self )
	self.bottom:Dock( BOTTOM )
	self.bottom:DockMargin( 5, 0, 5, 5 )
	self.bottom:SetTall( 40 )
	self.bottom:DockPadding( 5, 0, 0, 0 )
	Derma_Hook( self.bottom, "Paint", "Paint", "InnerPanelBright" )
	self.bottom:MoveToBack( )
	
	self.save = vgui.Create( "DButton", self.bottom )
	self.save:SetText( "Save" )
	self.save:SetImage( "pointshop2/floppy1.png" )
	self.save:SetWide( 180 )
	self.save.m_Image:SetSize( 16, 16 )
	self.save:Dock( RIGHT )
	function self.save.DoClick( )
		self:Save( )
	end
end

function PANEL:SetData( data )
	self.actualSettings:SetData( data )
	self.itemsTable:LoadSaveData( data["DropsTableSettings.DropsData"] )
end

function PANEL:Save( )
	self.actualSettings.settings["DropsTableSettings.DropsData"] = self.itemsTable:GetSaveData( )
	Pointshop2View:getInstance( ):saveSettings( self.mod, "Server", self.actualSettings.settings )
	self:Remove( )
end

function PANEL:SetModule( mod )
	self.mod = mod
end

vgui.Register( "DPointshopDropsConfigurator", PANEL, "DFrame" )
vgui.Register( "DPointshop2DropsConfigurator", PANEL, "DFrame" )