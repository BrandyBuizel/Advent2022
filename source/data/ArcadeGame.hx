package data;

import states.OverlaySubstate;
import data.Content;
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
    var url:Null<URL>;
    var camera:ArcadeCamera;
    var cabinet:Bool;
}

@:forward
abstract ArcadeGame(ArcadeCreation) from ArcadeCreation
{
    static final states = new Map<ArcadeName, ()->FlxState>();
    static var activeGame:ArcadeName = null;
    
    static function get(id:ArcadeName):ArcadeGame
    {
        return Content.arcades[id];
    }
    
    static public function init()
    {
        #if !exclude_chimney_game
        states[Chimney] = chimney.MenuState.new.bind(0);
        #end
        #if !exclude_yule_game
        states[YuleDuel] = yuleduel.states.TitleState.new.bind(0);
        #end
        
        #if (skip_to_chimney_game || skip_to_yule_duel)
            #error "Cannot have both flags: `skip_to_chimney_game` and `skip_to_yule_duel`";
        #end
        #if (skip_to_chimney_game && exclude_chimney_game)
            #error "cannot skip to Chimney game when excluded";
        #end
        #if (skip_to_yule_duel && exclude_yule_game)
            #error "cannot skip to YuleDuel when excluded";
        #end
        
        var startingGameName:ArcadeName = null;
        #if skip_to_chimney_game
        startingGameName = Chimney;
        #end
        #if skip_to_yule_duel
        startingGameName = YuleDuel;
        #end
        
        if (startingGameName != null)
        {
            var game = get(startingGameName);
            switch(game.type)
            {
                case STATE: // unused
                case EXTERNAL | OVERLAY:
                    // FlxG.signals.
            }
            if (states.exists(startingGameName))
                throw 'Attempting to play invalid arcade game: ${startingGameName}';
        }
    }
    
    static public function playById(id:ArcadeName)
    {
        var game = get(id);
        if (game == null)
            throw "Unhandled arcade id:" + id;
        
        game.play();
    }
    
    static public function exitActiveGame()
    {
        activeGame = null;
        // Game.goToRoom(Arcade + "." + arcadeName);
        // Game.goToRoom(Outside);
        
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        FlxG.sound.music = null;
        Manifest.playMusic(Game.chosenSong);
    }
    
    public var id(get, never):ArcadeName;
    inline function get_id() return cast this.id;
    
    public function play()
    {
        if (activeGame != null)
            throw 'Already playing $activeGame, cannot play $id';
        
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
    function switchStateUnsafe()
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        FlxG.sound.music = null;
        
        activeGame = id;
        FlxG.switchState(states[id]());
    }
}