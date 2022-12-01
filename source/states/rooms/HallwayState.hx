package states.rooms;

import states.OgmoState;
import flixel.FlxG;
import flixel.FlxSprite;

import data.Game;
import vfx.PixelPerfectShader;

import openfl.filters.ShaderFilter;

class HallwayState extends RoomState
{
    var shader:PixelPerfectShader;
    var pixelTankman:FlxSprite;
    var floor:OgmoDecal;
    var pixelFloor:FlxSprite;
    
    override function create()
    {
        super.create();
        
        floor = background.getByName("hallway");
        floor.antialiasing = true;
        floor.setBottomHeight(floor.frameHeight);
        player.antialiasing = true;
        pixelFloor = new FlxSprite("assets/images/props/hallway/hallway_pixel.png");
        pixelFloor.scale.set(2, 2);
        pixelFloor.updateHitbox();
        pixelFloor.x = floor.x;
        pixelFloor.y = floor.y - 1;
        add(pixelFloor);
        
        pixelTankman = new FlxSprite("assets/images/player/tankman_pixel.png");
        pixelTankman.scale.set(4, 4);
        // pixelTankman.updateHitbox();
        pixelTankman.offset.y = -48;
        pixelTankman.antialiasing = false;
        add(pixelTankman);
        
        if (Game.allowShaders)
        {
            shader = new PixelPerfectShader(4);
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
        
        var scale = pixelTankman.scale.x;
        pixelTankman.x = Std.int(player.x / scale) * scale - 2;
        pixelTankman.y = Std.int((player.y - player.offset.y) / scale) * scale - 1;
        pixelTankman.flipX = player.flipX;
        
        var amount:Float;
        
        if (player.x < FlxG.width / 4)
            amount = 0.0;
        else if (player.x > FlxG.width * 3 / 4)
            amount = 1.0;
        else
            amount = (player.x / FlxG.width * 2) - .5;
        
        if (Game.allowShaders)
            shader.setScale(4.0 - (amount * 3));
        
        pixelTankman.alpha = 1 - amount;
        player.alpha = amount * 4;
        
        pixelFloor.alpha = 1 - amount;
        // floor.alpha = amount;
    }
}