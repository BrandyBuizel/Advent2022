package data;

import data.ArcadeGame;
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
    
    static public var state:EventState = NONE;
    static public var chosenSong:String = null;
    
    static var roomTypes:Map<RoomName, RoomConstructor>;
    static var notifHandlers:Map<RoomName, ()->Bool>;
    static public var allowShaders(default, null):Bool = true;
    static public var disableShaders(get, never):Bool;
    inline static function get_disableShaders() return !allowShaders;
    
    public static var initialRoom(default, null) = 
        #if debug
        RoomName.Cafe + ".yuleduel";
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
        notifHandlers = [];
        addRoom(Intro, IntroState.new, false);
        addRoom(Outside, OutsideState.new);//, OutsideState.hasNotifs); // don't need to show skin notifs in cafe
        addRoom(Candles, CandlesState.new);
        addRoom(Cafe, CafeState.new, CafeState.hasNotifs);
        
        ArcadeGame.init();
        
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
    
    inline static function addRoom(name, constructor, isNetworked = true, ?notifHandler:()->Bool)
    {
        roomTypes[name] = constructor;
        RoomState.roomOrder.push(name);
        Net.netRooms.push(name);
        
        if (notifHandler != null)
            notifHandlers[name] = notifHandler;
    }
    
    inline static public function roomHasNotifs(room:RoomName)
    {
        if (notifHandlers.exists(room))
            return notifHandlers[room]();
        
        return false;
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
        
        if (ArcadeGame.skipToGameEnabled)
        {
            ArcadeGame.switchToStartingGame(Cafe);
            return;
        }
        
        switch (Game.state)
        {
            case INTRO(START):
            default: Content.playTodaysSong();
        }
        
        Game.goToRoom(initialRoom);
    }
    
    inline static public function playCabinet(id:ArcadeName)
    {
        ArcadeGame.playById(id);
    }
    
    inline static public function exitArcadeGameState(toRoom:RoomName):Void
    {
        ArcadeGame.exitActiveGameState(toRoom);
    }
}

