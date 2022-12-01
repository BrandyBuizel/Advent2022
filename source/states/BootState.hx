package states;

import io.newgrounds.NGLite;
import data.Save;
import data.Calendar;
import data.Content;
import data.Game;
import data.Manifest;
import data.NGio;
import ui.Button;
import ui.Font;
import utils.MultiCallback;

import flixel.FlxG;
import flixel.ui.FlxButton;
import flixel.util.FlxTimer;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.graphics.frames.FlxBitmapFont;

import openfl.Assets;

import io.newgrounds.NG;
import io.newgrounds.objects.events.Outcome;

class BootState extends flixel.FlxState
{
    inline static var MSG_TIME = 1.5;
    var msg:FlxBitmapText;
    var timeout:FlxTimer;
    var refreshTimer:FlxTimer;
    var state = LoggingIn;
    var waitTime = 0.0;
    
    var debugFutureEnabled = false;
    
    override public function create():Void
    {
        super.create();
        Content.init(Assets.getText("assets/data/content.json"));
        FlxG.autoPause = false;
        
        FlxG.camera.bgColor = FlxG.stage.color;
        
        add(msg = new FlxBitmapText(new XmasFont()));
        msg.text = "Checking naughty list...";
        if (NGio.DEBUG_SESSION_ID != null)
            msg.text += "\n Debug Session";
        // if (Calendar.isDebugDay)
        //     msg.text += "\n Debug Day";
        
        msg.alignment = CENTER;
        msg.screenCenter(XY);
        
        var versionText = new FlxText(0, 0, 100);
        versionText.text = 'Version: ' + lime.app.Application.current.meta.get('version');
        versionText.y = FlxG.height - versionText.height;
        add(versionText);
        
        timeout = new FlxTimer().start(20, showErrorAndBegin);
        NGio.attemptAutoLogin(onAutoConnectResult);
    }
    
    function onAutoConnectResult():Void
    {
        timeout.cancel();
        #if NG_BYPASS_LOGIN
        showMsgAndBegin("Login bypassed\nNot eligible for medals or cloud saves");
        #else
        if (NGio.isLoggedIn)
            onLogin();
        else
            NGio.startManualSession(onManualConnectResult, onManualConnectPending);
        #end
    }
    
    function onManualConnectPending(callback:(Bool)->Void)
    {
        msg.text = "Log in to Newgrounds?";
        msg.screenCenter(XY);
        var yes:Button = null;
        var no:Button = null;
        
        function onDecide(isYes:Bool)
        {
            remove(yes);
            remove(no);
            callback(isYes);
        }
        
        add(yes = new YesButton(150, msg.y + msg.height + 5, onDecide.bind(true )));
        add(no  = new NoButton (FlxG.width - 150, msg.y + msg.height + 5, onDecide.bind(false)));
        no.x -= no.width;
    }
    
    function onManualConnectResult(outcome:LoginOutcome):Void
    {
        switch(outcome)
        {
            case SUCCESS: onLogin();
            case FAIL(CANCELLED(_)): showMsgAndBegin("Login cancelled\nNot eligible for medals or cloud saves");
            case FAIL(ERROR(error)): showMsgAndBegin(error.toString());
        }
    }
    
    function onLogin()
    {
        beginGame();
    }
    
    function beginGame():Void
    {
        setState(Initing);
        
        var callbacks = new MultiCallback(
            function ()
            {
                Calendar.onGameInit();
                setState(Waiting);
                #if ALLOW_DAY_SKIP
                if (Calendar.canSkip()
                    && (Calendar.isAdvent || Calendar.isDebugDay)
                    && NGio.isContributor)
                {
                    waitTime = MSG_TIME;
                    msg.text = "(debug)\n Press SPACE to time travel";
                    msg.screenCenter(XY);
                }
                #end
            }
            #if BOOT_LOG , "BootState" #end// add logid
        );
        var callbacksSet = callbacks.add("wait");
        Manifest.init(callbacks.add("manifest"));
        Calendar.init(callbacks.add("calendar"));
        
        final saveCallback = callbacks.add("save");
        Save.init((outcome)->switch (outcome)
        {
            case SUCCESS: saveCallback();
            case FAIL(_):
                setCenteredNokiaMessage
                    ( "There was an error loading cloud saves, please reload.\n"
                    + "Sorry for the inconvenience"
                    );
                setState(Error(true));
        });
        
        var premierCallback = callbacks.add("moviePremier");
        NGio.checkForMoviePremier((_)->premierCallback());
        
        NGio.updateServerVersion(callbacks.add("server version"));
        if (NG.core.loggedIn && NG.core.medals == null)
            NG.core.medals.onLoad.addOnce(callbacks.add("medal list"));
        
        callbacksSet();
    }
    
    inline function showErrorAndBegin(_ = null)
    {
        showMsgAndBegin("Could not connect to Newgrounds\nNot eligible for medals");
    }
    
    function showMsgAndBegin(message:String)
    {
        msg.text = message;
        msg.screenCenter(XY);
        waitTime = MSG_TIME;
        beginGame();
    }
    
    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        waitTime -= elapsed;
        
        #if ALLOW_DAY_SKIP
        if (!debugFutureEnabled && state.match(Initing|Waiting) && FlxG.keys.pressed.SPACE)
        {
            debugFutureEnabled = true;
            msg.text = "DEBUG\nTime travel activated";
            msg.screenCenter(XY);
        }
        
        if (state.match(Error(false)) && FlxG.keys.justPressed.SPACE)
            onComplete();
        #end
        
        if (waitTime < 0)
        {
            switch (state)
            {
                case LoggingIn:
                case Initing:
                case Waiting:
                    #if ALLOW_DAY_SKIP
                    
                    if (Calendar.canSkip() && debugFutureEnabled)
                    {
                        Calendar.showDebugNextDay();
                        if (waitTime < 0.5)
                            waitTime = 0.5;
                    }
                    #end
                    setState(Checking);
                case Checking:
                    
                    if(isBrowserFarbling())
                    {
                        setCenteredNokiaMessage
                            ( "This browser is not supported, Chrome is recommended\n"
                            + "If you're using brave, try disabling shields for this page\n"
                            + "Sorry for the inconvenience"
                            );
                        setState(Error(true));
                        return;
                    }
                    
                    final showWarnings  = #if (debug && !NG_LURKER) true #else false #end;
                    var errors = Content.verifyTodaysContent(showWarnings);
                    
                    if (errors != null)
                    {
                        var warningsOnly = true;
                        var blockingList = new Array<String>();
                        var warningList = new Array<String>();
                        for (error in errors)
                        {
                            switch (error)
                            {
                                case Blocking(msg):
                                    warningsOnly = false;
                                    blockingList.push(msg);
                                case Warning(msg):
                                    warningList.push(msg);
                            }
                        }
                        
                        if (showWarnings || NGio.isContributor)
                        {
                            if (debugFutureEnabled)
                                msg.text = "(debug) You pressed space to see tommorow's content.\n";
                            else
                                msg.text = "";
                            
                            if (blockingList.length > 0)
                            {
                                msg.text += "This day is not ready yet."
                                    + "\n\nErrors:\n" + blockingList.join("\n") + "\n";
                            }
                            else
                                msg.text += "There are no errors but there are non-blocking issues.\n"
                                    + "Non-collab players will not see this message.\n";
                            
                            if (warningList.length > 0)
                                msg.text += "\nWarnings:\n" + warningList.join("\n") + "\n";
                            
                            msg.text += "\nYou are only seeing this message because you are in the credits";
                            
                            // change text when it's loaded
                            if (blockingList.length > 0)
                                startRefreshChecks(()->setCenteredNokiaMessage("IT'S UP, REFRESH THE PAGE! GO GO GO GO!1"));
                            
                            setState(Error(false));
                        }
                        else
                        {
                            setCenteredNokiaMessage("Today's content is almost done, Sorry");
                            setState(Error(true));
                            
                            // change text when it's loaded
                            startRefreshChecks(()->setCenteredNokiaMessage("IT'S UP, REFRESH THE PAGE! GO GO GO GO!1"));
                            
                            return;
                        }
                    }
                    
                    if (state == Checking && !isWebGl())
                    {
                        msg.text = "";
                        state = Error(false);
                    }
                    
                    switch (state)
                    {
                        case Error(false):
                        {
                            msg.font = new NokiaFont();
                            
                            inline function appendSection(text:String)
                            {
                                if (msg.text != "")
                                    msg.text += "\n\n";
                                
                                msg.text += text;
                            }
                            
                            if (!isWebGl())
                            {
                                appendSection
                                    ( "You browser does not support webgl, meaning"
                                    + "\ncertain features and flourishes will not work"
                                    + "\nSorry for the inconvenience"
                                    );
                            }
                            
                            msg.text += "\nPress SPACE to play, anyway";
                            msg.screenCenter(XY);
                            return;
                        }
                        case Checking:
                        {
                            setState(Success);
                            onComplete();
                        }
                        default: throw "Unexpected state:" + state.getName();
                    }
                    
                case Success:
                case Error(_):
            }
        }
    }
    
    inline function startRefreshChecks(callback:()->Void)
    {
        msg.text += "\n\n--- --- --- --- !NEW! --- --- --- ---"
            + "\n Wait here and we'll tell you when it's ready!";
        msg.screenCenter(XY);
        // change text when it's loaded
        function checkServerVersion(timer:FlxTimer)
        {
            if (false == NGio.validVersion)
            {
                callback();
                timer.cancel();
            }
        }
        
        refreshTimer = new FlxTimer().start(5, (t)->NGio.updateServerVersion(checkServerVersion.bind(t)), 0);
    }
    
    inline function setCenteredNokiaMessage(text:String)
    {
        msg.font = new NokiaFont();
        msg.text = text;
        msg.screenCenter(XY);
    }
    
    function isBrowserFarbling()
    {
        #if js
        var bmd = new openfl.display.BitmapData(10, 10, false, 0xFF00FF);
        for(i in 0...bmd.width * bmd.height)
        {
            if (bmd.getPixel(i % 10, Std.int(i / 10)) != 0xFF00FF)
                return true;
        }
        #end
        return false;
    }
    
    function isWebGl()
    {
        return switch(FlxG.stage.window.context.type)
        {
            case OPENGL, OPENGLES, WEBGL: true;
            default: false;
        }
    }
    
    function onComplete()
    {
        if (refreshTimer != null)
            refreshTimer.cancel();
        
        preloadArt();
        
        Game.goToInitialRoom();
    }
    
    function preloadArt()
    {
        for (artwork in Content.artwork)
        {
            if (artwork.preload || (artwork.day == Calendar.day && artwork.comic == null))
                Manifest.loadArt(artwork.id);
        }
    }
    
    function preloadSong(id:String)
    {
        final data = Content.songs[id];
        if (Calendar.day >= data.day)
            Manifest.loadSong(id);
    }
    
    inline function setState(state:State)
    {
        #if BOOT_LOG
        log('state:${this.state}->$state');
        #end
        this.state = state;
    }
    
    inline static function log(msg)
    {
        #if BOOT_LOG trace(msg); #end
    }
}

private enum State
{
    LoggingIn;
    Initing;
    Waiting;
    Checking;
    Success;
    Error(blocking:Bool);
}
