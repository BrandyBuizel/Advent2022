package ui;

import flixel.text.FlxText;

@:forward
abstract AAText(FlxText) to FlxText
{
    public function new (x = 0.0, y = 0.0, text = "", size = 16, ?font:String)
    {
        this = new FlxText(x, y, text, size);
        if (font != null)
            this.font = font;
    }
}

@:forward
abstract RoundedText(AAText) to AAText to FlxText
{
    static inline var font = "fonts/SFNSRounded.ttf";
    
    public function new (x = 0.0, y = 0.0, text = "", size = 16)
    {
        this = new AAText(x, y, text, size, font);
    }
}