package data;

import data.Content;
import data.Calendar;
import data.Save;

import states.OverlaySubstate;
import states.rooms.RoomState;
import states.rooms.*;
import ui.Controls;

import flixel.FlxG;
import flixel.FlxState;

class Game
{
    static public var room(get, never):RoomState;
    static function get_room() return Std.downcast(FlxG.state, RoomState);
    static public var arcadeName(default, null):ArcadeName = null;
    
    static public var state:EventState = NONE;
    static public var chosenSong:String = null;
    
    static var roomTypes:Map<RoomName, RoomConstructor>;
    static var arcadeTypes:Map<ArcadeName, ()->FlxState>;
    static public var allowShaders(default, null):Bool = true;
    static public var disableShaders(get, never):Bool;
    inline static function get_disableShaders() return !allowShaders;
    
    public static var initialRoom(default, null) = 
        #if debug
        RoomName.Outside;
        #else
        RoomName.Outside;
        #end
    
    static function init():Void
    {
        #if js
        allowShaders = switch(FlxG.stage.window.context.type)
        {
            case OPENGL, OPENGLES, WEBGL: true;
            default: false;
        }
        #end
        
        roomTypes = [];
        addRoom(Intro, IntroState.new, false);
        addRoom(Outside, OutsideState.new);
        addRoom(Candles, CandlesState.new);
        addRoom(Cafe, CafeState.new);
        
        arcadeTypes = [];
        #if INCLUDE_CHIMNEY_GAME
        arcadeTypes[Chimney] = chimney.MenuState.new.bind(0);
        #end
        #if INCLUDE_YULE_GAME
        arcadeTypes[YuleDuel] = holidayccg.states.PlayState.new.bind(0);
        #end        
        
        #if SKIP_INTRO
        var showIntro = false;
        #elseif FORCE_INTRO
        var showIntro = true;
        #else
        var showIntro = !Save.introComplete();
        #end
        
        if(showIntro)
        {
            state = INTRO(START);
            initialRoom = RoomName.Intro;
        }

        // Moved to Save.hx
        // FlxG.sound.volume = 0.5;
        
        // if (Calendar.day == 13 && !Save.hasOpenedPresentByDay(13))
        //     state = LuciaDay(Started);
        // else if (Save.noPresentsOpened())
        //     state = Intro(Started);
    }
    
    inline static function addRoom(name, constructor, isNetworked = true)
    {
        roomTypes[name] = constructor;
        RoomState.roomOrder.push(name);
        Net.netRooms.push(name);
    }
    
    static public function goToRoom(target:String):Void
    {
        var name:RoomName = cast target;
        if (target.indexOf(".") != -1)
        {
            final split = target.split(".");
            split.pop();
            name = cast split.join(".");
        }
        
        final constructor = roomTypes.exists(name) ? roomTypes[name] : RoomState.new;
        Net.safeLeaveCurrentRoom();
        FlxG.switchState(constructor(target));
    }
    
    @:allow(states.BootState)
    inline static function goToInitialRoom()
    {
        init();
        Controls.init();
        
        switch (Game.state)
        {
            case INTRO(START):
            default: Content.playTodaysSong();
        }
        
        Game.goToRoom(initialRoom);
    }
    
    static public function createArcadeOverlay(id:ArcadeName)
    {
        if (arcadeTypes.exists(id))
            return new OverlaySubstate(Content.arcades[id], arcadeTypes[id]());
        
        throw "Unhandled arcade id:" + id;
    }
    
    /** Switches the state to an arcade game state */
    static public function goToArcade(name:ArcadeName):Void
    {
        if (!arcadeTypes.exists(name))
            throw "No constructor found for arcade:" + name;
        
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        FlxG.sound.music = null;
        
        arcadeName = name;
        FlxG.switchState(arcadeTypes[name]());
    }
    
    static public function exitArcade():Void
    {
        goToRoom(Arcade + "." + arcadeName);
        
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        FlxG.sound.music = null;
        Manifest.playMusic(chosenSong);
    }
}

