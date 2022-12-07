package states.rooms;

import ui.Phone;

import data.Game;
import data.Manifest;
import data.Skins;
import props.Notif;
import states.OgmoState;

import vfx.ShadowShader;
import vfx.ShadowSprite;

import flixel.math.FlxMath;

import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import openfl.filters.ShaderFilter;

class CandlesState extends RoomState
{
    var shade:ShadowSprite;
    var floor:OgmoDecal;

    var clayfire:OgmoDecal;
    //var changingRoomNotif:Notif;
    
    override function create()
    {
        super.create();
        
        add(new vfx.Snow());
        
        clayfire.visible = false;
        
        //background.getByName("background").scrollFactor.set(0, 0.35);
    }
    
    // override function initUi()
    // {
    //     super.initUi();
    //     var phone = new Phone();
    //     ui.add(phone);
    // }
    
    override function initEntities()
    {
        super.initEntities();

        if (Game.allowShaders)
        {
            var floor = getDaySprite(background, "intro_candles");
            floor.setBottomHeight(floor.frameHeight);
            shade = new ShadowSprite(floor.x, floor.y);
            shade.makeGraphic(floor.frameWidth, floor.frameHeight, 0xD8000022);
                        
            shade.shadow.setLightRadius(1, 60);
            for (i=>candle in background.getAllWithName("clayfire_ogmo").members)
                shade.shadow.setLightPos(i + 2, candle.x + candle.width / 2, candle.y);
            topGround.add(shade);
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        updateCam(elapsed);

        trace("I'm in candles room...");

        if (Game.allowShaders)
        {
            shade.shadow.setLightPos(1, player.x + player.width / 2, player.y - 8);
        }
    }
    
    inline static var MAX_CAM_OFFSET = 200;
    inline static var CAM_SNAP_OFFSET = 30;
    inline static var CAM_SNAP_TIME = 3.0;
    inline static var CAM_LERP_OFFSET = MAX_CAM_OFFSET - CAM_SNAP_OFFSET;
    var camLerp = 0.0;
    var camSnap = 0.0;
    function updateCam(elapsed:Float)
    {
        final top = 450;
        final height = 150;
        final snapY = 540;
        // snap camera when above threshold
        if (player.y < snapY && camSnap < CAM_SNAP_OFFSET)
            camSnap += elapsed / CAM_SNAP_TIME * CAM_SNAP_OFFSET;
        else if (camOffset > 0)
            camSnap -= elapsed / CAM_SNAP_TIME * CAM_SNAP_OFFSET;
        // lerp camera in threshold
        camLerp = (height - (player.y - top)) / height * CAM_LERP_OFFSET;
        
        camOffset = camSnap + FlxMath.bound(camLerp, 0, CAM_LERP_OFFSET);
    }
}