package ui;

import openfl.text.TextFormatAlign;
import data.Content;
import ui.Font;

import flixel.FlxG;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;

class CreditsScroll extends FlxSpriteGroup
{
    static final charactersBy =
        [ "TomFulp"
        , "DanPaladin"
        , "StrawberryClock"
        , "Jaquin"
        , "Jonarock"
        , "DomRomArt"
        , "BrandyBuizel"
        , "PuffBallsUnited"
        , "BlueBaby"
        , "JoelG"
        , "Krinkels"
        , "FraserMcNiven"
        , "SrPelo"
        , "STANNco"
        , "chocoholicmonkey"
        , "psychicpebbles"
        , "phantomarcade"
        , "TomFulp (again)"
        ];
    
    static final specialThanks = 
        [ "Tom Fulp (once more)"
        , "Newgrounds"
        , "HaxeFlixel"
        , "PhsychoGoldfish"
        , "NinjaMuffin99"
        , "ThotThoughts"
        , "NG Discord Server"
        , "Newgrounds Supporters"
        ];
    
    var field:FlxBitmapText;
    var tween:FlxTween;
    
    var nextLineY:Float = 0;
    
    var totalText = "";
    
    public function new (duration:Float)
    {
        super();
        
        scrollFactor.set(0, 0);
        
        addHeader("Merry Tankmas!!!");
        addSubHeader("Cast");
        for (data in Content.creditsOrdered)
        {
            addInvertedLine(data.proper);
            for (role in data.roles)
                addLine(role);
            addSpace();
        }
        
        addSubHeader("Characters based on");
        
        for (user in charactersBy)
            addLine(user);
        
        addSubHeader("Special Thanks");
        
        for (user in specialThanks)
            addLine(user);
        
        addHeader("Thanks for playing!");
        
        trace(totalText);
        
        y = FlxG.height;
        if (duration > 0)
            tween = FlxTween.tween(this, { y:-height }, duration);
    }
    
    override function set_y(Value:Float):Float
    {
        return super.set_y(Value);
    }
    
    
    function addSpace()
    {
        nextLineY += 26;
        totalText += "\n";
    }
    
    function addHeader(text:String, align:TextFormatAlign = CENTER)
    {
        if (nextLineY > 0)
            addSpace();
        
        var line = addLine(text, align, 4.0);
        addSpace();
        
        return line;
    }
    
    function addSubHeader(text:String, align:TextFormatAlign = CENTER)
    {
        addSpace();
        var line = addLine(text, align, 2.0);
        addSpace();
        return line;
    }
    
    function addInvertedLine(text:String, align:TextFormatAlign = CENTER, scale = 1.0)
    {
        return addLine(text, align, scale, true);
    }
    
    function addLine(text:String, align:TextFormatAlign = CENTER, scale = 1.0, invert = false)
    {
        final line = new FlxBitmapText(new XmasFont());
        line.text = text;
        line.scale.set(scale, scale);
        line.updateHitbox();
        line.screenCenter(X);
        line.scrollFactor.set(0, 0);
        if (invert)
        {
            line.color = 0xFF000000;
            // line.setBorderStyle(OUTLINE, 0xFFffffff, 2);
        }
        else
            line.setBorderStyle(OUTLINE, 0xFF000000, 2);
        
        switch(align)
        {
            case LEFT:
                line.x -= 50;
            case RIGHT:
                line.x += 50;
                totalText += "\t\t";
            case _:
                totalText += "\t";
        }
        totalText += '$text\n';
        line.y = nextLineY;
        add(line);
        trace('$text: $y');
        
        nextLineY += line.lineHeight * line.scale.y;
        return line;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}