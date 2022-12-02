package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

class Phone extends FlxTypedSpriteGroup<FlxSprite>
{
    public function new ()
    {
        var bg = new FlxSprite("assets/images/ui/phone.png");
        add(bg);
        
        super(FlxG.width - bg.width, FlxG.height - bg.height);
        scrollFactor.set(0,0);
    }
    
    override function destroy()
    {
        // can't destroy
        // super.destroy();
    }
}