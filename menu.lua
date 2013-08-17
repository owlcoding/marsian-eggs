
local storyboard = require ( "storyboard" )
local scene = storyboard.newScene ( )

local widget = require( "widget" )

-- Set a default theme
widget.setTheme( "widget_theme_ios" )

local gameModes = {
    { title = "Mercury", gravity = 38 },
    { title = "Venus", gravity = 91 },
    { title = "Earth", gravity = 100 },
    { title = "Mars", gravity = 38 },
    { title = "Jupiter", gravity = 254 },
    { title = "Saturn", gravity = 108 },
    { title = "Uranus", gravity = 91 },
    { title = "Neptune", gravity = 119 },
    { title = "Pluto", gravity = 8 },
    { title = "Black Hole ?!?", gravity = 1 },
}

function scene:createScene ( event )
	
	local view = scene.view
	local menu = display.newGroup ( )
    
    for _, mode in pairs ( gameModes ) do
        
        if ( mode.title == "Black Hole ?!?" ) then
            isBlackHole = true
        end
        local gravity = mode.gravity * 9.81 / 100
        local newGame = widget.newButton ({
    		label = "Play on " .. mode.title,
            onRelease = function ( ev )
                if ( mode.title == "Black Hole ?!?" ) then
                    local g = display.newGroup ()
                    view:insert ( g )
                    local cover = display.newRect ( -100, -100, 600, 600 )
                    cover:setFillColor ( 0, 0, 0 )
                    g:insert ( cover )
                    cover.alpha = 0
                    cover:addEventListener ( "touch", function ()
                        return true
                    end)
                    transition.to ( cover, { time = 300, alpha = 1, onComplete = function ()
                        local txt1 = display.newText ( "Black Holes are black", 10, 10, native.systemFontBold, 16 )
                        local txt2 = display.newText ( "and you won't find eggs on them", 10, 100, native.systemFontBold, 16 )
                        print ( cover, txt )
                        g:insert ( txt1 )
                        g:insert ( txt2 )
                        timer.performWithDelay ( 4000, function ()
                            g:removeSelf()
                            g = nil
                        end)
                    end})
                else
                    storyboard.gotoScene ( "game", {effect="crossFade", params= { gravity = gravity, planetName = mode.title }})
                end
            end,
            height = 44,
            width = 280,
        })
        newGame.x, newGame.y = 0, 46 * _
        menu:insert ( newGame )
    end
    
	menu.x = 160
	menu.y = -10
	view:insert ( menu )
	
end

function scene:enterScene ( event )
    storyboard.purgeAll ()
end

scene:addEventListener ( "createScene", scene )
scene:addEventListener ( "enterScene", scene )
return scene