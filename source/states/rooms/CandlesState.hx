package states.rooms;

import data.Calendar;
import ui.Phone;
import data.NGio;
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
import flixel.util.FlxSpriteUtil;

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
        
        //clayfire.alpha = 0;
        
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
            //set shade to a solid rectangle
            //shade.makeGraphic(floor.frameWidth, floor.frameHeight, 0xD8000022);
            shade.loadGraphic("assets/images/props/candles/intro_candles_mask_ogmo.png", true, 1536);
            shade.x = 384/-8;
            shade.y = 150/-4;
            //shade.scale.x = 0.8;
            //shade.scale.y = 0.8;
            shade.shadow.setLightRadius(1, 120);

            //DITHER LIMITED TO 5 LIGHTS
            /*
            for (i=>candle in background.getAllWithName("clayfire").members)
                shade.shadow.setLightPos(i + 2, candle.x, candle.y);
            for (i=>candle in foreground.getAllWithName("clayfire").members)
                shade.shadow.setLightPos(i + 2, candle.x, candle.y);
            */

            /*
            for (i=>candle in background.getAllWithName("clayfire").members)
            {
                if(candle.x < player.x)
                {
                    shade.shadow.setLightPos(i + 2, candle.x, candle.y);
                }
            }
            */
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
            shade.shadow.setLightPos(1, player.x + 50, player.y + 30);

            //Animated tween to flicker
            //shade.shadow.setLightRadius(1, 120);
        }

        if(Calendar.day >= 7){
            if(player.x < 400)
            {
                trace("day 7");
                NGio.unlockMedalByName("candles");
            }
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