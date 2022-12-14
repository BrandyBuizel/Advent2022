package data;

import data.ArcadeGame;
import data.Content;
import states.rooms.RoomState;

import io.newgrounds.Call;
import io.newgrounds.NG;
import io.newgrounds.objects.Error;
import io.newgrounds.objects.events.Outcome;
import io.newgrounds.utils.MedalList;
import io.newgrounds.utils.SaveSlotList;

import utils.Log;
import utils.BitArray;
import utils.MultiCallback;

import flixel.FlxG;
import flixel.util.FlxSave;

import haxe.Int64;
import haxe.Json;
import haxe.PosInfos;

class Save
{
    static var emptyData:SaveData = cast {}
    
    static var save:FlxSave;
    static var data:SaveData;
    
    static public var showName(get, set):Bool;
    static public var notifs(get, never):SeenNotifs;
    inline static function get_notifs()
    {
        return data.seenNotifs;
    }
    
    static public function init(callback:(Outcome<CallError>)->Void)
    {
        #if DISABLE_SAVE
        createInitialData(emptyData);
        callback(SUCCESS);
        #else
        if (NGio.isLoggedIn)
        {
            
            NG.core.saveSlots.loadAllFiles
            (
                (outcome)->outcome.splitHandlers((_)->onCloudSavesLoaded(callback), callback)
            );
        }
        else
        {
            createInitialData(emptyData);
            callback(SUCCESS);
        }
        #end
    }
    
    static function onCloudSavesLoaded(callback:(Outcome<CallError>)->Void)
    {
        #if CLEAR_SAVE
        createInitialData();
        flush();
        #else
        if (NG.core.saveSlots[1].isEmpty())
        {
            createInitialData();
            mergeLocalSave();
            flush();
        }
        else
        {
            data = Json.parse(NG.core.saveSlots[1].contents);
            
            // Every time a new save field is added, check for it here and add it
            
            if (data.seenNotifs == null)
                data.seenNotifs = new SeenNotifs();
        }
        #end
        
        #if clear_notifs
        data.skins = new BitArray();
        data.seenNotifs = new SeenNotifs();
        #end
        
        log("presents: " + data.presents);
        log("seen days: " + data.days);
        log("seen skins: " + data.skins);
        log("seen notifs: " + data.seenNotifs);
        log("skin: " + data.skin);
        log("instrument: " + data.instrument);
        log("instruments seen: " + data.seenInstruments);
        log("saved session: " + data.showName);
        log("saved order: " + (data.cafeOrder == null ? "random" : data.cafeOrder));
        log("introComplete: " + data.introComplete);
        
        function setInitialInstrument()
        {
            var instrument = getInstrument();
            if (instrument != null)
                Instrument.setCurrent();
        }
        
        if (Content.isInitted)
            setInitialInstrument();
        else
            Content.onInit.addOnce(setInitialInstrument);
        
        callback(SUCCESS);
    }
    
    static function createInitialData(?data:SaveData)
    {
        if (data == null)
            data = cast {};
        
        data.presents        = new BitArray();
        data.days            = new BitArray();
        data.skins           = new BitArray();
        data.seenInstruments = new BitArray();
        data.seenNotifs      = new SeenNotifs();
        data.skin            = 0;
        data.instrument      = -1;
        data.showName        = false;
        data.cafeOrder       = null;
        data.introComplete   = false;
        Save.data = data;
    }
    
    static function mergeLocalSave()
    {
        var save = new FlxSave();
        if (save.bind("advent2022", "GeoKureli") && save.isEmpty() == false)
        {
            final localData:SaveData = save.data;
            if (BitArray.isOldFormat(localData.presents))
                localData.presents = BitArray.fromOldFormat(cast localData.presents);
                
            if (BitArray.isOldFormat(localData.days))
                localData.days = BitArray.fromOldFormat(cast localData.days);
            
            if (BitArray.isOldFormat(localData.skins))
                localData.skins = BitArray.fromOldFormat(cast localData.skins);
            
            if (BitArray.isOldFormat(localData.seenInstruments))
                localData.seenInstruments = BitArray.fromOldFormat(cast localData.seenInstruments);
            
            if (localData.instrument < -1 && localData.seenInstruments.countTrue() > 0)
            {
                // fix an old glitch where i deleted instrument save
                var i = 0;
                while (!localData.seenInstruments[i] && i < 32)
                    i++;
                
                localData.instrument = i;
            }
            
            // merge save data
            for (field in Reflect.fields(localData))
                Reflect.setField(data, field, Reflect.field(localData, field));
            
            save.erase();
        }
    }
    
    static public function flush(?callback:(Outcome<CallError>)->Void)
    {
        if (data != emptyData)
            NG.core.saveSlots[1].save(Json.stringify(data), callback);
    }
    
    static public function resetPresents()
    {
        data.presents = new BitArray();
        flush();
    }
    
    static public function presentOpened(id:String)
    {
        var index = Content.getPresentIndex(id);
        
        if (index < 0)
            throw "invalid present id:" + id;
        
        if (data.presents[index] == false)
        {
            data.presents[index] = true;
            flush();
        }
    }
    
    static public function hasOpenedPresent(id:String)
    {
        var index = Content.getPresentIndex(id);
        
        if (index < 0)
            throw "invalid present id:" + id;
        
        return data.presents[index];
    }
    
    inline static public function hasOpenedPresentByDay(day:Int)
    {
        return data.presents[day - 1];
    }
    
    static public function countPresentsOpened(id:String)
    {
        return data.presents.countTrue();
    }
    
    static public function anyPresentsOpened()
    {
        return !noPresentsOpened();
    }
    
    static public function noPresentsOpened()
    {
        return data.presents.getLength() == 0;
    }
    
    static public function daySeen(day:Int)
    {
        day--;//saves start at 0
        if (data.days[day] == false)
        {
            data.days[day] = true;
            flush();
        }
    }
    
    static public function debugForgetDay(day:Int)
    {
        day--;//saves start at 0
        data.days[day] = false;
        data.presents[day] = false;
        flush();
    }
    
    static public function hasSeenDay(day:Int)
    {
        //saves start at 0
        return data.days[day - 1];
    }
    
    static public function countDaysSeen()
    {
        return data.days.countTrue();
    }
    
    static public function skinSeen(index:Int, flushNow = true)
    {
        #if !(UNLOCK_ALL_SKINS)
        if (data.skins[index] == false)
        {
            data.skins[index] = true;
            if (flushNow)
                flush();
        }
        #end
    }
    
    static public function hasSeenSkin(index:Int)
    {
        return data.skins[index];
    }
    
    static public function countSkinsSeen()
    {
        return data.skins.countTrue();
    }
    
    static public function setSkin(id:Int)
    {
        PlayerSettings.user.skin = data.skin = id;
        flush();
    }
    
    static public function getSkin()
    {
        return data.skin;
    }
    
    static public function setInstrument(type:InstrumentType)
    {
        if (type == null || type == getInstrument()) return;
        
        PlayerSettings.user.instrument = type;
        data.instrument = Content.instruments[type].index;
        flush();
        Instrument.setCurrent();
    }
    
    static public function getOrder()
    {
        return data.cafeOrder;
    }
    
    static public function setOrder(order:Order)
    {
        if (data.cafeOrder != order)
        {
            data.cafeOrder = order;
            flush();
        }
    }
    
    static public function getInstrument()
    {
        if (data.instrument < 0 || Content.hasInstrumentData == false) return null;
        return Content.instrumentsByIndex[data.instrument].id;
    }
    
    static public function instrumentSeen(type:InstrumentType)
    {
        if (type == null) return;
        
        data.seenInstruments[Content.instruments[type].index] = true;
        flush();
    }
    
    static public function seenInstrument(type:InstrumentType)
    {
        if (type == null) return true;
        
        return data.seenInstruments[Content.instruments[type].index];
    }
    
    static public function onIntroComplete()
    {
        data.introComplete = true;
        flush();
    }
    
    static public function introComplete()
    {
        return data.introComplete;
    }
    
    inline static function get_showName() return data.showName;
    static function set_showName(value:Bool)
    {
        if (data.showName != value)
        {
            data.showName = value;
            flush();
        }
        return value;
    }
    
    inline static public function toggleShowName()
        return showName = !showName;
    
    inline static function log(msg, ?info:PosInfos) Log.save(msg, info);
}

typedef SaveData2020 =
{
    var presents:BitArray;
    var days:BitArray;
    var skins:BitArray;
    var skin:Int;
    var instrument:Int;
    var seenInstruments:BitArray;
    var seenNotifs:SeenNotifs;
}

typedef SaveData = SaveData2020 &
{
    var showName:Bool;
    var cafeOrder:Order;
    var introComplete:Bool;
}

abstract SeenNotifs(BitArray) from BitArray to BitArray
{
    inline static var YULE_DUEL = 0;
    inline static var CHIMNEY = 1;
    
    public var yuleDuel(get, set):Bool;
    inline function get_yuleDuel() return this[YULE_DUEL];
    inline function set_yuleDuel(value:Bool):Bool return setValue(YULE_DUEL, value);
    
    public var chimney(get, set):Bool;
    inline function get_chimney() return this[CHIMNEY];
    inline function set_chimney(value:Bool):Bool return setValue(CHIMNEY, value);
    
    public function getArcadePlayed(id:ArcadeName)
    {
        return switch(id)
        {
            case YuleDuel: yuleDuel;
            case Chimney: chimney;
            default: true;
        }
    }
    
    public function setArcadePlayed(id:ArcadeName)
    {
        switch(id)
        {
            case YuleDuel: yuleDuel = true;
            case Chimney: chimney = true;
            default:
        }
    }
    
    function setValue(index:Int, value:Bool):Bool
    {
        if (this[index] != value)
        {
            this[YULE_DUEL] = value;
            
            Save.flush();
        }
        return value;
    }
    
    public function new() { this = new BitArray(); }
}
