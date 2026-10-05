package states.rooms;

import data.NGio;
import data.Content;
import data.Manifest;
import ui.MusicPopup;

import flixel.FlxG;
import flixel.system.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

import states.OgmoState;

class BathroomState extends SmoothRoomState
{
    // time it takes to fade the camera out, any longer will have a abrupt stop.
    static inline var FADE_TIME = 0.25;
    
    var music:FlxSound;
    var disc:OgmoDecal;
    var disc_env:OgmoDecal;
    
    override function create()
    {
        super.create();
        
        Manifest.loadSong("tiny", true, null, function (grinch)
        {
            if (FlxG.sound.music != null)
            {
                music = grinch;
                FlxG.sound.music.fadeOut(FADE_TIME, 0.2);
                music.play();
                music.volume = 1.0;
            }
        });

        // BONUS TRACKS pickup disc code
        disc = foreground.getByName("disc");
        disc_env = background.getByName("disc_env");

        if (NGio.hasMedalByName("disc"))
        {
            foreground.remove(disc);
            background.remove(disc_env);
        }
        else
        {
            addHoverTextTo(disc, "BONUS TRACKS", ()->{ 
                NGio.unlockMedalByName("disc");
                foreground.remove(disc);
                background.remove(disc_env);
            });
        }
        
    }
    
    override function activateTeleport(target:String)
    {
        super.activateTeleport(target);
        
        if (FlxG.sound.music != null)
            FlxG.sound.music.fadeIn(FADE_TIME, FlxG.sound.music.volume, 1.0);
        if (music != null)
            music.fadeOut(FADE_TIME);
    }
    
    override function onExit()
    {
        super.onExit();
        
        if (music != null)
            music.stop();
        music = null;
        
        MusicPopup.showCurrentSongInfo();
    }
}