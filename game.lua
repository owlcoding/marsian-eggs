
local movieclip = require ( "movieclip" )
local storyboard = require ( "storyboard" )
local scene = storyboard.newScene ( )

local widget = require ( "widget" )
local physics = require ( "physics" )

-- some constants
local TYPE_EGG, TYPE_FUEL, TYPE_WALL, TYPE_BASKET = 1, 2, 3, 4

local fuelConsumptionPerSec = 6
local fuelInCan = 20
local eggsResistance = 4
local startLifes = 3

-- local vars
local cannons
local basket
local cannonsPositions = {
    -- { x, y, height index }
    {5, 100, 3},
    {5, 200, 2},
    {5, 300, 1},
    {315, 140, 3},
    {315, 240, 2},
    {315, 340, 1},
}
local spawningTimer
local fuelPercentage
local bottomLine
local points

local pointsLabel
local fuelBar
local lifesIcons


local rand = math.random

local function increasePoints ( ) 
    points = points + 1
    pointsLabel.text = "Points: " .. points
end

local function decreaseLifes ()
    local lifeIcon = table.popLast ( lifesIcons )
    local cross = display.newImageRect ( "assets/cross.png", 40, 50 )
    cross.x, cross.y, cross.z = lifeIcon.x, lifeIcon.y, lifeIcon.z + 10
    scene.view:insert ( cross )
    
    if ( #lifesIcons <= 0 ) then
        -- game over
        timer.performWithDelay ( 10, function ()
            physics.stop () 
        end)
        storyboard.gotoScene ( "gameOver", {effect="crossFade", params= { eggs = points }})        
    end
end


local function spawnFlyingObject ( )
    local originCannon = cannons [ rand ( #cannons ) ]

    -- random type: 5 - egg, 6 - fuel
    local r = rand ( 6 )
    local type = TYPE_EGG
    if r == 6 and basket.fuel < 80 then 
        type = TYPE_FUEL
    end
    
    local flyingObject = display.newCircle( originCannon.x, originCannon.y, 10 )
    flyingObject.type = type
    if flyingObject.type == TYPE_EGG then
        flyingObject:setFillColor ( 255, 255, 0 )
        flyingObject.resistanceLeft = eggsResistance
    else
        flyingObject:setFillColor ( 0, 255, 0 )
    end
    
	physics.addBody ( flyingObject, "dynamic", {density=1, friction=0.1, bounce=1, radius = 10 })
    local xForce, yForce = 30, -30
    if originCannon.x > 240 then
        xForce = - xForce
        flyingObject.x = flyingObject.x - 30
    else
        flyingObject.x = flyingObject.x + 30
    end
    
    yForce = yForce * originCannon.heightIndex 
    -- xForce = xForce * originCannon.heightIndex
    if originCannon.heightIndex == 1 then
        xForce = 2 * xForce
    end
    
    flyingObject:applyForce ( xForce, yForce )
    
    flyingObject.decreaseResistance = function ( self )
        self.resistanceLeft = self.resistanceLeft - 1
        self.alpha = ( self.resistanceLeft ) / eggsResistance
        print ( " >> Decrease resistance << ")
        if ( self.resistanceLeft == 0 ) then
            self:removeSelf ()
            print (" >> Die << ")
            decreaseLifes ()
        end
    end
    
    flyingObject.collision = function ( self, event )
        if ( "began" == event.phase ) then
            local other = event.other
            if ( self.type == TYPE_EGG and other.type ~= TYPE_BASKET ) then
                self:decreaseResistance ()
            end
            if ( other.type == TYPE_EGG ) then
                other:decreaseResistance ()
            end
            
            if ( other.type == TYPE_BASKET ) then
                print ( " >> collision with basket!!! << ")
                if ( self.type == TYPE_EGG ) then
                    -- consume the egg
                    increasePoints ()
                    self:removeSelf ()
                end
                if ( self.type == TYPE_FUEL ) then
                    -- refill the fuel
                    other.fuel = math.min ( 100, other.fuel + fuelInCan )
                    self:removeSelf ()
                end
            end            
        end
    end
    flyingObject:addEventListener ( "collision" )
    
    scene.view:insert ( flyingObject )
    
end

local function eachFrame ( event )
    -- check basket state, if propulsion is on ( animation frame = 2 ) then lower fuel
    if basket:currentFrame () == 2 then
        basket.fuel = basket.fuel - fuelConsumptionPerSec / 30
        print ( basket.fuel )
    end
    if basket.fuel <= 0 then
        basket:showFrame ( 1 )
        basket.fuel = 0
    end
    if basket:currentFrame () == 2 then
        basket:applyForce ( 0, -40 )
    end
    local fuelScale = basket.fuel / 100
    
    if fuelScale <= 0 then
        fuelScale = 1
        fuelBar.isVisible = false
    else
        fuelBar.isVisible = true
    end
    fuelBar.xScale = fuelScale 
    if ( basket.fuel < 20 ) then
        fuelBar:setFillColor ( 255, 100, 100 )
    elseif ( basket.fuel < 50 ) then
        fuelBar:setFillColor ( 255, 255, 100 )
    else
        fuelBar:setFillColor ( 100, 255, 100 )
    end
end
local function touchListener ( event )
    if ( "began" == event.phase and basket.fuel > 0 ) then
        print ( "XX" )
        basket:showFrame ( 2 )
    end
    if ( "ended" == event.phase ) then
        basket:showFrame ( 1 )
    end
end

function scene:createScene ( event )
	-- load audios here
	local view = scene.view
    
	physics.start()   -- must do this before any other physics call!
	physics.setGravity( 0, event.params.gravity )
	physics.setScale( 30 )
    -- physics.setDrawMode( "hybrid" ) -- overlays collision outlines on normal Corona objects
	physics.pause()
    local planet = display.newText ( "Planet: " .. event.params.planetName .. ", gravity: " .. event.params.gravity .. " m/s^2", 10, 10, native.systemFont, 10 )
    view:insert ( planet )
    
    cannons = {}
    for _, cannonPos in pairs ( cannonsPositions ) do
        local cannon = display.newImageRect ( view, "assets/cannon.png", 30, 15 )
        cannon.x, cannon.y, cannon.z = cannonPos [ 1 ], cannonPos [ 2 ], 10
        cannon.heightIndex = cannonPos [ 3 ]
        cannons [ _ ] = cannon
    end
    
	local line1 = display.newLine( view, 0, 0, 0, 480 )
	local line2 = display.newLine( view, 320, 0, 320, 480 )

	local rectVert = {
		-5, 0, 5, 0, 5, 480, -5, 480
		}
	local rectHoriz = {
		0, -5, 320, -5,  320, 5, 0, 5
		}
	
	bottomLine = display.newLine( view, 0, 480, 320, 480 )
	local line3 = display.newLine( view, 0, 480, 320, 480 )
	
    line1.type, line2.type, bottomLine.type = TYPE_WALL, TYPE_WALL, TYPE_WALL
    
	physics.addBody ( line1, "static", {density=1, friction=0.1, bounce=0, shape = rectVert })
	physics.addBody ( line2, "static", {density=1, friction=0.1, bounce=0, shape = rectVert })
	physics.addBody ( bottomLine, "static", {density=1, friction=0.1, bounce=0, shape = rectHoriz })
	physics.addBody ( line3, "static", {density=1, friction=0.1, bounce=0, shape = rectHoriz })
	
    pointsLabel = display.newText ( "Points: 0", 160, 30, native.systemFontBold, 12 )
    pointsLabel.x, pointsLabel.y = 160, 50
    view:insert ( pointsLabel )
    
    fuelBar = display.newRect( view, 10, 460, 300, 5 )
    fuelBar:setFillColor ( 100, 255, 100 )
    
    lifesIcons = {}
    
    for i = 1, startLifes do
        local lifeIcon = display.newImageRect ( view, "assets/basket.png", 40, 50 )
        lifeIcon.x, lifeIcon.y = 180  + 30 * i, 55
        lifeIcon.xScale, lifeIcon.yScale = 0.75, 0.75
        lifeIcon.alpha = 0.8
        lifeIcon.z = 100
        lifesIcons [ i ] = lifeIcon
    end
    
    local exit = widget.newButton ({
		label = "Exit",
        onRelease = function ( ev )
            storyboard.gotoScene ( "menu", {effect="crossFade" })
        end,
        height = 36,
        width = 60,
    })
    exit.x, exit.y = 270, 25
    view:insert ( exit )
    
    
end

function scene:enterScene ( event )
	local view = scene.view
    -- add a basket
    -- it's a movieclip
    basket = movieclip.newAnim ({ "assets/basket.png", "assets/basket_fire.png" })
    basket.x, basket.y, basket.z = 160, 400, 10
    view:insert ( basket )
    
    basket.type = TYPE_BASKET
    basket.fuel = 100
    physics.addBody ( basket, "dynamic", { density=1, friction=0.1, bounce=0 })
    
    
    local myJoint = physics.newJoint( "piston", basket, bottomLine, 0, 0, 0, 1 )
    
    
	physics.start( )
    
    Runtime:addEventListener ( "touch", touchListener )
    Runtime:addEventListener ( "enterFrame", eachFrame )
	points = -1
    increasePoints ()
    spawningTimer = timer.performWithDelay( 5000, spawnFlyingObject, 0 )
    spawnFlyingObject ()
    
end

function scene:exitScene ( event )
    basket:removeSelf ()
    basket = nil
    Runtime:removeEventListener ( "touch", touchListener )
    Runtime:removeEventListener ( "enterFrame", eachFrame )
    timer.cancel ( spawningTimer )
    spawningTimer = nil
end

scene:addEventListener ( "createScene" )
scene:addEventListener ( "enterScene" )
scene:addEventListener ( "exitScene" )

return scene