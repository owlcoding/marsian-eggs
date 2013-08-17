local storyboard = require ( "storyboard" )
local scene = storyboard.newScene ( )

function scene:createScene ( event )
    local points = event.params.eggs
    local text = display.newText ( scene.view, "Game Over!!!", 100, 100, native.systemFontBold, 28 )
    text:setReferencePoint ( display.TopCenterReferencePoint )
    text.x, text.y = 160, 100 
    text:setTextColor ( 255, 0, 0 )
    local textPoints = display.newText ( scene.view, "You got " .. points .. " points.", 100, 200, native.systemFontBold, 20 )
    textPoints:setReferencePoint ( display.TopCenterReferencePoint )
    textPoints.x, textPoints.y = 160, 200 
    
    timer.performWithDelay ( 2000, function ()
        storyboard.gotoScene ( "menu", "crossFade", 1000 )
    end)
end

scene:addEventListener ( "createScene" )

return scene
