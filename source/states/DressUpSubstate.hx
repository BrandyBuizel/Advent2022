package states;

import ui.Font.XmasFont;
import data.Calendar;
import data.NGio;
import data.Save;
import data.PlayerSettings;
import data.Skins;
import ui.Button;
import ui.Controls;
import ui.Prompt;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;

import openfl.utils.Assets;

import haxe.Json;

class DressUpSubstate extends flixel.FlxSubState
{
    inline static var BAR_MARGIN = 48;
    inline static var SIDE_GAP = 96;
    inline static var SPACING = 72;
    
    var sprites = new FlxTypedSpriteGroup<SkinDisplay>();
    var current = -1;
    var nameText = new FlxBitmapText();
    var descText = new FlxBitmapText();
    var arrowLeft:Button;
    var arrowRight:Button;
    var ok:OkButton;
    // prevents instant selection
    var wasAReleased = false;
    
    /** Currently, only used if a new skin was seen. */
    var flushOnExit = false;
    
    /** Used to diable input */
    var showingPrompt = false;
    
    var currentSprite(get, never):SkinDisplay;
    inline function get_currentSprite() return sprites.members[current];
    var currentSkin(get, never):SkinData;
    inline function get_currentSkin() return sprites.members[current].data;
    
    override function create()
    {
        super.create();

        camera = new FlxCamera().copyFrom(camera);
        camera.bgColor = 0x0;
        FlxG.cameras.add(camera, false);
        
        var bg = new FlxSprite();
        add(bg);
        add(sprites);
        
        var instructions = new FlxBitmapText();
        instructions.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        instructions.text = "Select an avatar!\nThis is how other players will see you";
        instructions.screenCenter(X);
        instructions.y = 32;
        instructions.scrollFactor.set(0, 0);
        instructions.alignment = CENTER;
        instructions.scale.set(4, 4);
        instructions.updateHitbox();
        add(instructions);
        
        createSkinsList();
        
        var top:Float = FlxG.height;
        var bottom:Float = 0;
        for (sprite in sprites)
        {
            top = Math.min(top, sprite.y);
            bottom = Math.max(bottom, sprite.y + sprite.height);
        }
        
        top -= BAR_MARGIN;
        
        nameText.text = currentSkin.proper;
        nameText.scale.set(4, 4);
        nameText.screenCenter(X);
        nameText.y = top - nameText.height;
        nameText.scrollFactor.set(0, 0);
        top -= nameText.height + BAR_MARGIN;
        add(nameText);
        
        descText.text = currentSkin.description;
        descText.scale.set(2, 2);
        descText.alignment = CENTER;
        descText.fieldWidth = Std.int(FlxG.width * .75);
        descText.width = descText.fieldWidth;
        descText.height = 1000;
        descText.wordWrap = true;
        descText.screenCenter(X);
        descText.y = bottom + BAR_MARGIN;
        descText.scrollFactor.set(0, 0);
        bottom += descText.height + BAR_MARGIN * 2;
        add(descText);
        
        if (!FlxG.onMobile)
        {
            var keysText = new FlxBitmapText();
            keysText.text = "Arrow Keys to Select, Space to confrim";
            keysText.x = 10;
            keysText.y = FlxG.height - keysText.height;
            keysText.scrollFactor.set(0, 0);
            keysText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
            add(keysText);
        }
        
        bg.y = top;
        bg.makeGraphic(FlxG.width, Std.int(bottom - top), 0xFF555555);
        bg.scrollFactor.set(0, 0);
        
        add(arrowLeft  = new Button(0, 0, toPrev, "assets/images/ui/leftArrow.png"));
        arrowLeft.x  = (FlxG.width - arrowLeft.width  - SIDE_GAP - SPACING) / 3;
        arrowLeft.y  = bg.y + (bg.height - arrowLeft.height ) / 2;
        arrowLeft.scrollFactor.set(0, 0);
        add(arrowRight = new Button(0, 0, toNext, "assets/images/ui/rightArrow.png"));
        arrowRight.x = (FlxG.width - arrowRight.width + SIDE_GAP + SPACING) / 1.5;
        arrowRight.y = bg.y + (bg.height - arrowRight.height) / 2;
        arrowRight.scrollFactor.set(0, 0);
        add(ok = new OkButton(0, 0, select));
        ok.screenCenter(X);
        ok.y = bottom + BAR_MARGIN;
        ok.scrollFactor.set(0, 0);
        
        hiliteCurrent();
    }
    
    public function createSkinsList()
    {
        for (i in 0...Skins.getLength())
        {
            var data = Skins.getDataSorted(i);
            var sprite = new SkinDisplay(data);
            sprites.add(sprite);
            sprite.scrollFactor.set(0, 0);
            sprite.unseen.camera = camera;
            
            sprite.x = SPACING * i;
            if (data.offset != null)
                sprite.offset.set(data.offset.x, data.offset.y);
            
            if (data.index == PlayerSettings.user.skin)
            {
                current = i;
                sprite.x += SIDE_GAP - 12;
                camera.follow(sprite);
            }
            else if (i > current && current > -1)
                sprite.x += SIDE_GAP * 2;
            
            sprite.y = (FlxG.height - sprites.members[0].height) / 2;
            
            if (!data.unlocked)
                sprite.color = FlxColor.BLACK;
        }
    }
    
    public function resetSkinsList()
    {
        current = -1;
        sprites.x = 0;
        
        while(sprites.length > 0)
            sprites.remove(sprites.members[0], true);
        
        createSkinsList();
        hiliteCurrent();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (showingPrompt)
            return;
        
        if (!wasAReleased && Controls.released.A)
            wasAReleased = true;
        
        if (Controls.justPressed.RIGHT)
            toNext();
        if (Controls.justPressed.LEFT)
            toPrev();
        if (Controls.justPressed.A && wasAReleased)
            select();
        if (Controls.justPressed.B)
            close();
    }
    
    function toNext():Void
    {
        if(current >= sprites.length - 1)
            return;
        
        unhiliteCurrent();
        currentSprite.x -= SIDE_GAP;
        current++;
        currentSprite.x -= SIDE_GAP;
        hiliteCurrent();
    }
    
    function toPrev():Void
    {
        if(current <= 0)
            return;
        
        unhiliteCurrent();
        currentSprite.x += SIDE_GAP;
        current--;
        currentSprite.x += SIDE_GAP;
        hiliteCurrent();
    }
    
    function unhiliteCurrent()
    {
        currentSprite.unseen.visible
            = currentSkin.unlocked && !Save.hasSeenSkin(currentSkin.index);
    }
    
    function hiliteCurrent()
    {
        sprites.x = (current+1) * -SPACING - 40 + (FlxG.width - currentSprite.width) / 2;
        
        if (currentSkin.unlocked)
        {
            nameText.text = currentSkin.proper;
            descText.text = currentSkin.description;
            ok.active = true;
            ok.alpha = 1;
            if (Save.hasSeenSkin(currentSkin.index) == false && Calendar.isDebugDay == false)
            {
                Save.skinSeen(currentSkin.index, false);
                flushOnExit = true;
            }
        }
        else
        {
            nameText.text = "???";
            descText.text = "Work in progress";
            if (currentSkin.unlocksBy != null)
                descText.text = currentSkin.unlocksBy.getUnlockInfo();
            
            ok.active = false;
            ok.alpha = 0.5;
        }
        ok.visible = true;
        nameText.updateHitbox();
        nameText.screenCenter(X);
        descText.updateHitbox();
        descText.screenCenter(X);
    }
    
    function select():Void
    {
        if (currentSkin.unlocked)
        {
            Save.setSkin(currentSkin.index);
            close();
        }
    }

    override function close()
    {
        Skins.showNotif = false;
        FlxG.cameras.remove(camera);
        if (flushOnExit)
            Save.flush();
        
        super.close();
    }
}

class SkinDisplay extends FlxSprite
{
    public final data:SkinData;
    public final unseen:FlxSprite;
    
    public function new (data:SkinData, x = 0.0, y = 0.0)
    {
        this.data = data;
        super(x, y);
        scale.set(2, 2);
        updateHitbox();
        
        data.loadTo(this);
        unseen = new FlxSprite("assets/images/ui/new.png");
        unseen.visible = data.unlocked && !Save.hasSeenSkin(data.index);
        unseen.scale.set(2, 2);
        unseen.updateHitbox();
        unseen.scrollFactor.set(0, 0);
    }
    
    override function draw()
    {
        super.draw();
        if (unseen.visible)
        {
            unseen.x = x + offset.x + 10 + (width - unseen.width) / 2;
            unseen.y = y;
            unseen.draw();
            FlxG.watch.addQuick("u.x", unseen.x);
            FlxG.watch.addQuick("skin.x", x);
            FlxG.watch.addQuick("offset.x", offset.x);
            FlxG.watch.addQuick("w", width);
            FlxG.watch.addQuick("u.w", unseen.width);
        }
    }
}