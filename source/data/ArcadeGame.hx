package data;

import data.Content;
import data.Manifest;
import states.rooms.RoomState;
import states.OverlaySubstate;
import ui.Controls;
import ui.Prompt;

import flixel.FlxG;
import flixel.FlxState;
import flixel.system.FlxSound;

enum abstract ArcadeName(String) to String
{
    var Advent2018 = "2018";
    var Advent2019 = "2019";
    var Advent2020 = "2020";
    var Advent2021 = "2021";
    var YuleDuel = "yuleduel";
    var Chimney = "chimney";
    var PicoVenture = "picoventure";
}

enum abstract ArcadeType(String) to String
{
    var STATE    = "state";
    var OVERLAY  = "overlay";
    var EXTERNAL = "external";
}

typedef ArcadeCamera =
{
    var width:Int;
    var height:Int;
    var zoom:Int;
}

typedef ArcadeCreation
= Creation &
{
    var ngId:Int;
    var scoreboard:String;
    var scoreboardId:Int;
    var medalPath:String;
    var mobile:Bool;
    var medal:Bool;
    var type:ArcadeType;
    var notif:Bool;
    var url:Null<URL>;
    var camera:ArcadeCamera;
    var cabinet:Bool;
    var crtShader:Null<Bool>;
}

@:forward
abstract ArcadeGame(ArcadeCreation) from ArcadeCreation
{
    static public var activeGame(default, null):ArcadeName = null;
    static public var skipToGameEnabled(default, null) = false;
    
    static final states = new Map<ArcadeName, ()->FlxState>();
    static final destructors = new Map<ArcadeName, ()->Void>();
    static var skipToID:ArcadeName = null;
    
    static function get(id:ArcadeName):ArcadeGame
    {
        return Content.arcades[id];
    }
    
    static public function init()
    {
        #if !exclude_chimney
        states[Chimney] = chimney.PlayState.new.bind(0);
        #end
        #if !exclude_yule_duel
        states[YuleDuel] = yuleduel.states.TitleState.new.bind(0);
        destructors[YuleDuel] = yuleduel.globals.GameGlobals.uninit;
        #end
        #if !exclude_picoventure
        states[PicoVenture] = picoventure.states.PlayState.new.bind(0);
        destructors[PicoVenture] = picoventure.states.PlayState.uninit;
        #end
        
        #if (skip_to_chimney && skip_to_yule_duel && skip_to_picoventure)
            #error "Cannot any 2 of following flags: `skip_to_chimney_duel`, `skip_to_yule_duel` and `skip_to_picoventure`";
        #end
        #if (skip_to_chimney && exclude_chimney)
            #error "cannot skip to Chimney game when excluded";
        #end
        #if (skip_to_picoventure && exclude_picoventure)
            #error "cannot skip to Chimney game when excluded";
        #end
        #if (skip_to_yule_duel && exclude_yule_duel)
            #error "cannot skip to YuleDuel when excluded";
        #end
        
        skipToID = null;
        #if skip_to_chimney
        skipToID = Chimney;
        #end
        #if skip_to_yule_duel
        skipToID = YuleDuel;
        #end
        #if skip_to_picoventure
        skipToID = PicoVenture;
        #end
        
        if (skipToID != null)
        {
            var game = get(skipToID);
            switch(game.type)
            {
                case STATE:
                    if (game.hasState() == false)
                        throw 'Attempting to skip to invalid arcade game: ${skipToID}';
                    
                    skipToGameEnabled = true;
                    
                case EXTERNAL:
                    
                    game.play();
                    skipToID = null;
                    
                case OVERLAY:
                    
                    if (game.hasState() == false)
                        throw 'Attempting to skip to invalid arcade game: ${skipToID}';
                    
                    function onRoomJoin()
                    {
                        if (FlxG.state is RoomState)
                        {
                            FlxG.signals.postStateSwitch.remove(onRoomJoin);
                            game.play();
                        }
                    }
                    
                    FlxG.signals.postStateSwitch.add(onRoomJoin);
                    skipToID = null;
            }
        }
    }
    
    static public function switchToStartingGame(room:RoomName)
    {
        skipToGameEnabled = false;
        activeGame = skipToID;
        skipToID = null;
        
        get(activeGame).switchStateUnsafe(room);
    }
    
    static public function playById(id:ArcadeName)
    {
        var game = get(id);
        if (game == null)
            throw "Unhandled arcade id:" + id;
        
        game.play();
    }
    
    static public function exitActiveGameState(toRoom:RoomName)
    {
        Game.goToRoom(toRoom + "." + activeGame);
        
        if (destructors.exists(activeGame))
            destructors[activeGame]();
        
        activeGame = null;
        
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        FlxG.sound.music = null;
        
        if (Game.chosenSong == null)
            Content.playTodaysSong();
        else
            Manifest.playMusic(Game.chosenSong);
    }
    
    public var id(get, never):ArcadeName;
    inline function get_id() return cast this.id;
    
    public function play()
    {
        if (activeGame != null)
            throw 'Already playing $activeGame, cannot play $id';
        
        if(this.notif)
            Save.notifs.setArcadePlayed(id);
        
        if (this.mobile == false && FlxG.onMobile)
            Prompt.showOKInterrupt("This game is not available on mobile\n...yet.");
        else
        {
            switch(this.type)
            {
                case STATE: switchState();
                case OVERLAY: openOverlay();
                case EXTERNAL: openExternal();
            }
        }
    }
    
    inline function hasState()
    {
        return states.exists(id);
    }
    
    inline function assertState()
    {
        if (hasState() == false)
            throw 'Unhandled arcade id: $id';
    }
    
   inline public function createOverlay()
    {
        assertState();
        return createOverlayUnsafe();
    }
    
    function createOverlayUnsafe()
    {
        return new OverlaySubstate(get(id), states[id]());
    }
    
    inline public function openOverlay()
    {
        assertState();
        return openOverlayUnsafe();
    }
    
    function openOverlayUnsafe()
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        FlxG.sound.music = null;
        
        var overlay = createOverlayUnsafe();
        overlay.closeCallback = ()->
        {
            if (destructors.exists(activeGame))
                destructors[activeGame]();
            
            activeGame = null;
            if (FlxG.sound.music != null)
                FlxG.sound.music.stop();
            
            Manifest.playMusic(Game.chosenSong);
        }
        
        FlxG.state.openSubState(overlay);
        activeGame = id;
        
        return overlay;
    }
    
    inline public function openExternal()
    {
        if (this.url != null)
            this.url.open();
    }
    
    inline public function openExternalUnsafe()
    {
        this.url.open();
    }
    
    /** Switches the state to an arcade game state */
    inline public function switchState():Void
    {
        assertState();
        switchStateUnsafe();
    }
    
    /** Switches the state to an arcade game state */
    function switchStateUnsafe(?room:RoomName)
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        FlxG.sound.music = null;
        
        activeGame = id;
        
        if (room == null)
            room = Game.room.name;
        
        Net.safeLeaveCurrentRoom();
        FlxG.plugins.list.push(new ArcadeStatePlugin(room));
        FlxG.switchState(new LoadingState(states[activeGame](), activeGame));
    }
}

private class ArcadeStatePlugin extends flixel.FlxBasic
{
    var prevRoom:RoomName;
    public function new(prevRoom:RoomName)
    {
        this.prevRoom = prevRoom;
        super();
    }
    
    override function update(elapsed)
    {
        super.update(elapsed);
        
        if (Controls.pressed.EXIT && !(FlxG.state is LoadingState))
            exitGame();
    }
    
    inline function exitGame()
    {
        FlxG.plugins.list.remove(this);
        ArcadeGame.exitActiveGameState(prevRoom);
    }
}