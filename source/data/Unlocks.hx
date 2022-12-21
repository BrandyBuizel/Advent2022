package data;

import data.ApiData;
import data.NGio;
import io.newgrounds.NG;
import io.newgrounds.utils.ExternalAppList;

import flixel.FlxG;

abstract Unlocks(String) from String
{
    static var inited = false;
    static var app2021:ExternalApp;
    static var app2020:ExternalApp;
    
    static public function init(callback:()->Void)
    {
        var numToLoad = 2;
        inline function onLoad()
        {
            if (--numToLoad == 0)
            {
                inited = true;
                callback();
            }
        }
        
        app2021 = NG.core.externalApps.add(ApiData.API_ID_2021);
        app2021.medals.loadList((outcome)->switch(outcome)
        {
            case SUCCESS:
                onLoad();
            case FAIL(error):
                FlxG.log.warn("Error loading app 2021");
                app2021 = null;
                onLoad();
        });
        app2020 = NG.core.externalApps.add(ApiData.API_ID_2020);
        app2020.medals.loadList((outcome)->switch(outcome)
        {
            case SUCCESS:
                onLoad();
            case FAIL(error):
                FlxG.log.warn("Error loading app 2020");
                app2020 = null;
                onLoad();
        });
    }
    
    public function check()
    {
        if (inited == false)
            throw "Call Unlocks.init() first.";
        
        if (hasMany())
        {
            // check many
            final conditions = getAll();
            while (conditions.length > 0)
            {
                if (conditions.shift().check())
                    return true;
            }
            return false;
        }
        
        final loggedIn = NGio.isLoggedIn;
        
        // check lone
        return switch(split())
        {
            case ["login"    ]: loggedIn;
            case ["free"     ]: true;
            case ["supporter"]: loggedIn && NG.core.user.supporter;
            case [_]: throw "Unhandled unlockBy:" + this;
            case ["day"  , day  ]: Save.countDaysSeen() >= Std.parseInt(day);
            case ["medal", medal] if (medal.length < 3): NGio.hasDayMedal(Std.parseInt(medal));
            case ["medal", medal]: NGio.hasMedal(Std.parseInt(medal));
            case ["medal2021", medal]: app2021 != null && app2021.medals[Std.parseInt(medal)].unlocked;
            case ["medal2020", medal]: app2020 != null && app2020.medals[Std.parseInt(medal)].unlocked;
            default: throw "Unhandled unlockBy:" + this;
        }
    }
    
    inline function hasMany()
    {
        return this.indexOf(",") != -1;
    }
    
    inline function getAll():Array<Unlocks>
    {
        return cast this.split(",");
    }
    
    inline function split() return this.split(":");
    
    inline static var TXT_KEEP_PLAYING = "Keep playing every day to unlock";
    inline static var TXT_LOGIN = "Log in to Newgrounds to unlock this";
    inline static var TXT_SUPPORTER = "Become a newgrounds supporter to unlock this";
    
    public function getUnlockInfo()
    {
        return switch (split())
        {
            case ["login"     ]: TXT_LOGIN;
            case ["medal", day]: NGio.isLoggedIn ? TXT_KEEP_PLAYING : TXT_LOGIN;
            case ["supporter" ]: TXT_SUPPORTER;
            default: TXT_KEEP_PLAYING;
        }
    }
}