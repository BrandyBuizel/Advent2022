package data;

import flixel.FlxG;
import ui.Prompt;

abstract URL(String) from String to String
{
    public function open(?customMsg:String, ?onYes:()->Void)
    {
        var prompt = new Prompt();
        FlxG.state.add(prompt);
        
        if (customMsg == null)
            customMsg = "";
        else
            customMsg += "\n\n";
        customMsg += 'Open external page?\n${prettyUrl(this)}';
        
        prompt.setupYesNo
            ( customMsg
            , ()->
            {
                FlxG.openURL(this);
                if (onYes != null) onYes();
            }
            , null
            , FlxG.state.remove.bind(prompt)
            );
    }
    
    
    static public function prettyUrl(url:String)
    {
        if (url.indexOf("://") != -1)
            url = url.split("://").pop();
        
        return url.split("default.aspx").join("");
    }
}