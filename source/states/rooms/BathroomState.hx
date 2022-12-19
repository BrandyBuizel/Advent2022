package states.rooms;

import data.Manifest;
import ui.MusicPopup;

import flixel.FlxG;
import flixel.system.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class BathroomState extends SmoothRoomState
{
    // time it takes to fade the camera out, any longer will have a abrupt stop.
    static inline var FADE_TIME = 0.25;
    
    var music:FlxSound;
    
    override function create()
    {
        super.create();
        
        Manifest.loadSong("tiny", true, null, function (grinch)
        {
            music = grinch;
            FlxG.sound.music.fadeOut(FADE_TIME, 0.2);
            music.play();
            music.volume = 1.0;
        });
        
    }
    
    override function activateTeleport(target:String)
    {
        super.activateTeleport(target);
        
        FlxG.sound.music.fadeIn(FADE_TIME, FlxG.sound.music.volume, 1.0);
        music.fadeOut(FADE_TIME);
    }
    
    override function onExit()
    {
        super.onExit();
        
        music.stop();
        music = null;
        
        MusicPopup.showCurrentSongInfo();
    }
}