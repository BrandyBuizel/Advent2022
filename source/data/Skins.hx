package data;


import data.Calendar;
import data.Unlocks;
import utils.Log;

import flixel.FlxSprite;

import openfl.utils.Assets;

import io.newgrounds.NG;

import haxe.Json;
using StringTools;

class Skins
{
    static public var numUnlocked(default, null) = 0;
    static public var showNotif:Bool = false;
    
    static var byIndex:Array<SkinData>;
    static var sorted:Array<SkinData>;
    static var skinOrder:Array<String> = [];
    
    static function init()
    {
        if (byIndex != null)
            throw "Skins already initted";
        
        byIndex = Json.parse(Assets.getText("assets/data/skins.json"));
        if (byIndex[0].id == "custom")
        {
            var customSkin = byIndex.shift();
            // When we finally add a custom
            // byIndex.push(customSkin);
        }
        
        sorted = byIndex.copy();
        for (i=>data in byIndex)
        {
            data.index = i;
            data.unlocked = #if UNLOCK_ALL_SKINS true #else false #end;
            
            if (data.year == null)
                data.year = 2021;
            
            if (data.group == null)
                data.group = data.id;
            
            if (skinOrder.indexOf(data.group) == -1)
                skinOrder.push(data.group);
            
            if (data.unlocksBy != null && !Std.is(data.unlocksBy, String))
                throw 'Invalid unlocksBy:${data.unlocksBy} id:${data.id}';
        }
        
        checkUnlocks(!Game.state.match(INTRO(_)));
        
        if (NGio.isLoggedIn)
        {
            if (NG.core.medals.state == Loaded)
                medalsLoaded();
            else
                NG.core.medals.onLoad.add(medalsLoaded);
        }
    }
    
    static function medalsLoaded():Void
    {
        for (medal in NG.core.medals)
        {
            if(!medal.unlocked #if debug || true #end)
                medal.onUnlock.add(checkUnlocks.bind(true));
        }
    }
    
    static public function checkUnlocks(showPopup = true)
    {
        var newUnlocks = 0;
        numUnlocked = 0;
        
        for (data in byIndex)
        {
            if (!data.unlocked && (checkUser(data.users) || data.unlocksBy.check()))
            {
                data.unlocked = true;
                if (!Save.hasSeenSkin(data.index))
                    newUnlocks++;
            }
            
            if (data.unlocked)
                numUnlocked++;
            else if (Save.hasSeenSkin(data.index))
                Log.save('skin ${data.id} is locked but was seen, unlocksBy:${data.unlocksBy}');
            
        }
        
        sorted.sort(function (a, b)
            {
                if (a.unlocked == b.unlocked)
                {
                    // sort unlocked by groups
                    if (a.unlocked && a.group != b.group)
                        return sortGroup(a.group, b.group);
                    
                    // sort locked by year
                    if (!a.unlocked && a.year != b.year)
                        return b.year - a.year;// higher years first
                    
                    // index is tie breaker
                    return a.index - b.index; // lower first
                }
                return (a.unlocked ? 0 : 1) - (b.unlocked ? 0 : 1);
            }
        );
        
        if (newUnlocks > 0)
        {
            showNotif = true;
            if (showPopup)
                ui.SkinPopup.show(newUnlocks);
        }
    }
    
    static function sortGroup(a:String, b:String)
    {
        return skinOrder.indexOf(a) - skinOrder.indexOf(b);
    }
    
    static public function checkHasUnseen()
    {
        var unlockedCount = 0;
        for (data in byIndex)
        {
            if (data.unlocked)
                unlockedCount++;
        }
        return unlockedCount > Save.countSkinsSeen();
    }
    
    static function checkUser(users:Array<String>)
    {
        return users != null && NGio.isLoggedIn && users.contains(NGio.userName.toLowerCase());
    }
    
    static public function isValidSkin(index:Int)
    {
        return index < byIndex.length;
    }
    
    static public function getData(id:Int)
    {
        if (byIndex == null)
            init();
        
        if (id < 0 || byIndex.length <= id)
        {
            #if debug
            throw 'Invalid skin id:$id';
            #else
            trace('Invalid skin id:$id, showing tankman');
            id = 0;
            #end
        }
        
        return byIndex[id];
    }
    
    
    static public function getIdByName(name:String)
    {
        if (byIndex == null)
            init();
        
        for (i in 0...byIndex.length)
        {
            if (byIndex[i].id == name)
                return i;
        }
        
        throw "Missing skin with name:" + name;
    }
    
    static public function getDataSorted(id:Int)
    {
        if (sorted == null)
            init();
        
        if (id < 0 || sorted.length <= id)
            throw "Invalid id:" + id;
        
        return sorted[id];
    }
    
    static public function getLength()
    {
        if (byIndex == null)
            init();
        
        return byIndex.length;
    }
}

typedef SkinDataRaw =
{
    var id:String;
    var proper:String;
    var description:String;
    var unlocksBy:Unlocks;
    var frames:Null<Int>;
    var fps:Null<Int>;
    var offset:Null<{x:Float, y:Float}>;
    var users:Null<Array<String>>;
    var year:Int;
    var group:String;
}

typedef SkinDataPlus = SkinDataRaw &
{
    var index:Int;
    var unlocked:Bool;
}

@:forward
abstract SkinData(SkinDataPlus) from SkinDataPlus to SkinDataPlus
{
    public var path(get, never):String;
    inline function get_path() return 'assets/images/player/${this.id}.png';
    
    public function loadTo(sprite:FlxSprite)
    {
        sprite.loadGraphic(path);
        if (this.frames != null && this.frames > 1)
        {
            sprite.loadGraphic(path, true, Std.int(sprite.frameWidth / this.frames), sprite.frameHeight);
            sprite.animation.add("default", [for (i in 0...this.frames) i], this.fps != null ? this.fps : 8);
            sprite.animation.play("default");
        }
    }
}