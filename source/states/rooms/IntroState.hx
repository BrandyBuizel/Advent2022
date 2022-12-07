package states.rooms;

import flixel.FlxG;
import flixel.FlxSprite;

import data.Content;
import data.Game;
import data.Save;
import states.OgmoState;
import vfx.PixelPerfectShader;

import openfl.filters.ShaderFilter;

class IntroState extends RoomState
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
        
        camera.targetOffset.y = -200;
        player.antialiasing = true;
        
        floor = background.getByName("intro");
        floor.antialiasing = true;
        pixelFloor = background.getByName("intro_pixel");
        
        if(Game.state.match(INTRO(START)) == false)
            return;
        
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
                Save.onIntroComplete();
                
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
            
            //fixed bish
            pixelFloor.alpha = 1 - amount;
            trace(pixelFloor.alpha);
            floor.alpha = amount * 2;
        }
    }
}