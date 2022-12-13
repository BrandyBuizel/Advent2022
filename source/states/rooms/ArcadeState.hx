package states.rooms;

import data.Game;
import data.Manifest;
import data.Save;
import data.Calendar;
import data.Content;
import data.Net;

import states.OgmoState;

import props.Cabinet;
import ui.Prompt;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;

class ArcadeState extends RoomState
{
    override function create()
    {
        entityTypes["Cabinet"] = cast initCabinet;
        
        super.create();
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        for (light in foreground.getAllWithName("light"))
        {
            topGround.add(light);
            foreground.remove(light);
        }
    }
    
    function initCabinet(data:OgmoEntityData<CabinetValues>)
    {
        var cabinet = Cabinet.fromEntity(data);
        if (cabinet.enabled)
            addHoverTextTo(cabinet, cabinet.data.name, Game.playCabinet.bind(cabinet.data));
        
        return cabinet;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}