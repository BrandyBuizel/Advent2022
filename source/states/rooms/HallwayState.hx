package states.rooms;

import states.OgmoState;
import flixel.FlxG;
import flixel.FlxSprite;

import data.Content;
import data.Game;
import vfx.PixelPerfectShader;

import openfl.filters.ShaderFilter;

class HallwayState extends RoomState
{
    inline static var SCALE_START = 2.0;
    inline static var SCALE_END = 1.0;
    inline static var X_START = 3/8;
    inline static var X_END = 7/8;
    
    var shader:PixelPerfectShader;
    var pixelTankman:FlxSprite;
    var floor:OgmoDecal;
    var pixelFloor:FlxSprite;
    
    override function create()
    {
        super.create();
        
        if (!Game.state.match(INTRO(START)))
            return;
        
        floor = background.getByName("intro");
        floor.setBottomHeight(floor.frameHeight);
        floor.antialiasing = true;
        pixelFloor = new FlxSprite("assets/images/props/intro/intro_pixel.png");
        pixelFloor.setGraphicSize(floor.frameWidth);
        pixelFloor.updateHitbox();
        pixelFloor.x = floor.x;
        pixelFloor.y = floor.y;
        background.add(pixelFloor);
        
        player.antialiasing = true;
        pixelTankman = new FlxSprite("assets/images/player/tankman_pixel.png");
        pixelTankman.setGraphicSize(Std.int(player.frameWidth));
        pixelTankman.updateHitbox();
        pixelTankman.offset.x = (player.frameWidth - player.width) / 2;
        pixelTankman.offset.y = 0;
        pixelTankman.antialiasing = false;
        add(pixelTankman);
        
        if (Game.allowShaders && Game.state.match(INTRO(START)))
        {
            shader = new PixelPerfectShader(SCALE_START);
            camera.setFilters([new ShaderFilter(shader)]);
            FlxG.watch.addFunction("scale", shader.getScale);
        }
    }
    
    override function initEntities()
    {
        super.initEntities();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        var amount:Float = 1.0;
        
        if (Game.state.match(INTRO(START)))
        {
            var scale = pixelTankman.scale.x;
            pixelTankman.x = Std.int(player.x / scale) * scale;
            pixelTankman.y = Std.int((player.y - player.offset.y) / scale) * scale;
            pixelTankman.flipX = player.flipX;
            
            final startX = X_START * floor.width;
            final endX = X_END * floor.width;
            if (player.x < startX)
                amount = 0.0;
            else if (player.x > endX)
            {
                // fully rezzed
                Game.state = NONE;
                Content.playTodaysSong();
                
                camera.setFilters(null);
                amount = 1.0;
            }
            else
            {
                amount = (player.x - startX) / (endX - startX);
            }
            
            if (Game.allowShaders)
                shader.setScale(SCALE_START + amount * (SCALE_END - SCALE_START));
            
            pixelTankman.alpha = 1 - amount;
            player.alpha = amount * 4;
            
            pixelFloor.alpha = 1 - amount;
            // floor.alpha = amount;
        }
    }
}