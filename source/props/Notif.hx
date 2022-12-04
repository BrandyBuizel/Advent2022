package props;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;

class Notif extends flixel.FlxSprite
{
    var tween:FlxTween;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(x, y, "assets/images/props/shared/notif.png");
        offset.y = height;
    }
    
    public function animate()
    {
        if (tween != null)
            tween.cancel();
        
        offset.y = height;
        tween = FlxTween.tween(this, { "offset.y": height - 8 }, 0.5, { type:PINGPONG, ease:FlxEase.sineInOut, loopDelay: 0.33 });
    }
    
    override function draw()
    {
        var pos = getPosition();
        var camera = this.camera;
        
        // always on screen
        if (x < camera.scroll.x)
            x = camera.scroll.x;
        else
        if (x > camera.scroll.x + camera.width - width)
            x = camera.scroll.x + camera.width - width;
        
        if (y < camera.scroll.y + height)
            y = camera.scroll.y + height;
        else
        if (y > camera.scroll.y + camera.height)
            y = camera.scroll.y + camera.height;
        
        super.draw();
        
        setPosition(pos.x, pos.y);
        pos.put();
    }
    
    inline function stopAnimate()
    {
        if (tween != null)
        {
            tween.cancel();
            tween = null;
        }
    }
    
    override function kill()
    {
        super.kill();
        stopAnimate();
    }
    
    override function destroy()
    {
        super.destroy();
        stopAnimate();
    }
}