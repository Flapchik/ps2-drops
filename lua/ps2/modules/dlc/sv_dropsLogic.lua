function Pointshop2.Drops.AwardPlayerDrop( ply )
	if not IsValid( ply ) then
		return
	end
	
	if  not ply.PS2_Inventory then
		timer.Simple( 2, function( )
			Pointshop2.Drops.AwardPlayerDrop( ply )
		end )
	end
	
	local dropMap = Pointshop2.GetSetting( "Pointshop 2 DLC", "DropsTableSettings.DropsData" )
	
	--Generate cumulative sum table
	local sumTbl = {}
	local sum = 0
	for k, info in pairs( dropMap ) do
		sum = sum + info.chance
		local factoryClass = getClass( info.factoryClassName )
		if not factoryClass then
			continue
		end
		
		local instance = factoryClass:new( )
		instance.settings = info.factorySettings
		
		table.insert( sumTbl, {sum = sum, factory = instance, chance = info.chance })
	end

	--Pick element
	local r = math.random() * sum
	local factory, chance
	for _, info in ipairs( sumTbl ) do
		if info.sum > r then
			factory, chance = info.factory, info.chance
			break
		end
	end
	
	if not factory then 
		return
	end
	
	local item = factory:CreateItem( )
	:Then( function( item )
		local price = item.class:GetBuyPrice( ply )
		item.purchaseData = {
			time = os.time( ),
			origin = "Drop"
		}
		if price.points then
			item.purchaseData.amount = price.points
			item.purchaseData.currency = "points" 
		elseif price.premiumPoints then
			item.purchaseData.amount = price.points
			item.purchaseData.currency = "premiumPoints" 
		else
			item.purchaseData.amount = 0
			item.purchaseData.currency = "points" 
		end
		return item:save( )
	end )
	:Then( function( item )
		KInventory.ITEMS[item.id] = item
		return ply.PS2_Inventory:addItem( item )
		:Then( function( )
			item:OnPurchased( )
			Pointshop2Controller:getInstance( ):startView( "Pointshop2View", "displayItemAddedNotify", ply, item )
			return item
		end )
	end )
	:Then( function( item )
		if not Pointshop2.GetSetting( "Pointshop 2 DLC", "DropsSettings.BroadcastDrops" ) then 
			return
		end
		
		net.Start( "PS2D_AddChatText" )
			net.WriteTable{
				Color( 151, 211, 255 ),
				"Player ",
				Color( 255, 255, 0 ),
				ply:Nick( ),
				Color( 151, 211, 255 ),
				" found ",
				Pointshop2.Drops.RarityColorMap[chance],
				item:GetPrintName( ),
				Color( 151, 211, 255 ),
				"!"
			}
		net.Broadcast( )
	end )
end

function Pointshop2.Drops.PerformDrops( )
	if not Pointshop2.GetSetting( "Pointshop 2 DLC", "DropsSettings.EnableDrops" ) then
		return
	end
	
	local dropChanceInPercent = Pointshop2.GetSetting( "Pointshop 2 DLC", "DropsSettings.DropChance" )
	for k, v in pairs( player.GetAll( ) ) do
		if math.random( ) * 100 > dropChanceInPercent then
			continue
		end
		
		pcall( function( ) 
			WhenAllFinished{ v.outfitsReceivedPromise:Promise( ), v.dynamicsReceivedPromise:Promise( ) }
			:Done( function( )
				Pointshop2.Drops.AwardPlayerDrop( v )
			end )
		end )
	end
end
hook.Add( "Pointshop2GmIntegration_RoundEnded", "DoDrops", function( )
	Pointshop2.Drops.PerformDrops( )
end )

function Pointshop2.Drops.RegisterTimer( )
	timer.Remove( "Pointshop2_DOT" )
	
	--Drops over time is disabled for gamemodes with integration plugins
	if Pointshop2.IsCurrentGamemodePluginPresent( ) and Pointshop2.GetSetting( "Pointshop 2 DLC", "DropsSettings.UseGamemodeDrops" ) then
		return
	end
	
	local delayInSeconds = Pointshop2.GetSetting( "Pointshop 2 DLC", "DropsSettings.DropFrequency" ) * 60
	timer.Create( "Pointshop2_DOT", delayInSeconds, 0, function( )
		Pointshop2.Drops.PerformDrops( )
	end )
end

hook.Add( "PS2_OnSettingsUpdate", "Change", function( )
	Pointshop2.Drops.RegisterTimer( )
end )
Pointshop2.SettingsLoadedPromise:Done( function( )
	Pointshop2.Drops.RegisterTimer( )
end )