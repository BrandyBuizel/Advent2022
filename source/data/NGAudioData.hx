package data;

import openfl.geom.Matrix;
import data.Content;

import flixel.FlxG;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Loader;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.net.URLRequest;

typedef NGIcon =
{
    final small:String;
    final medium:String;
    final large:String;
}

enum abstract NGIconSize(String)
{
    var SMALL = "small";
    var MEDIUM = "medium";
    var LARGE = "large";
}

private typedef NGAuthorRaw =
{
    final id:Int;
    final name:String;
    final url:String;
    final icons:NGIcon;
    final owner:Int;
    final manager:Int;
    final is_scout:Bool;
}

@:forward
abstract NGAuthor(NGAuthorRaw) from NGAuthorRaw
{
    public var owner(get, never):Bool;
    inline function get_owner():Bool return this.owner == 1;
    public var manager(get, never):Bool;
    inline function get_manager():Bool return this.manager == 1;
}

private typedef NGAudioDataRaw =
{
    final id:Int;
    final title:String;
    final url:String;
    final download_url:String;
    final stream_url:String;
    final filesize:Int;
    final icons:NGIcon;
    final authors:NGAuthor;
    final has_scouts:Bool;
    final unpublished:Bool;
    final allow_downloads:Bool;
    final has_valid_portal_member:Bool;
    final allow_external_api:Bool;
};

@:forward
abstract NGAudioData(NGAudioDataRaw) from NGAudioDataRaw
{
    static inline var FEED_URL = "https://www.newgrounds.com/audio/feed/";
    static var list:Array<NGAudioData>;
    
    static var loaded:Bool = false;
    static public var callback:()->Void;
    
    static public function loadAll()
    {
        var numLoading = 0;
        for (song in Content.songs)
            numLoading++;
        
        inline function onDiskLoad()
        {
            numLoading--;
            if (numLoading == 0 && callback != null)
                callback();
        }
        
        function onFeedLoad(song:SongCreation, data:Null<NGAudioData>)
        {
            if (data.allow_external_api == false)
            {
                FlxG.log.warn('song: ${song.id} disallows external api. ngId: ${song.ngId}');
                onDiskLoad();
                return;
            }
            
            data.loadIcon(function(icon)
            {
                addFakeAsset('assets/images/ui/carousel/disks/${song.id}', scaleDrawTo(icon, 60, 60));
                
                onDiskLoad();
            });
        }
        
        for (song in Content.songs)
        {
            if (song.ngId == null)
            {
                numLoading--;
                continue;
            }
            
            if (Manifest.exists('assets/images/ui/carousel/disks/${song.id}', IMAGE))
            {
                numLoading--;
                continue;
            }
            
            #if NG_LOAD_DISK_ART
            NGAudioData.load(song.ngId, onFeedLoad.bind(song, _));
            #else
            numLoading--;
            #end
        }
        
        if (numLoading == 0 && callback != null)
            callback();
    }
    
    static function scaleDrawTo(source:BitmapData, width:Int, height:Int)
    {
        var dest = new BitmapData(width, height, true, 0xFF000000);
        final mat = new Matrix();
        mat.scale(source.width / width, source.height / height);
        dest.draw(source, mat, true);
        return dest;
    }
    
    static function addFakeAsset(fakePath:String, bitmapData:BitmapData)
    {
        var graphic = FlxG.bitmap.add(bitmapData, true, fakePath);
        @:privateAccess
        graphic.assetsKey = fakePath;
        graphic.destroyOnNoUse = false;
        graphic.persist = true;
    }
    
    static public function load(ngId:Int, callback:(Null<NGAudioData>)->Void)
    {
        loadWithRetries(FEED_URL + ngId, function(data) 
        {
            if (data == null)
                callback(null);
            else
                callback(cast haxe.Json.parse(data));
        });
    }
    
    static function loadWithRetries(url:String, callback:(Null<String>)->Void, numRetries = 5)
    {
        final http = new haxe.Http(url);
        http.onError = function (msg)
        {
            if (numRetries > 0)
                loadWithRetries(url, callback, numRetries - 1);
            else
                callback(null);
        }
        
        http.onData = callback;
        http.request();
    }
    
    public function loadIcon(size:NGIconSize = MEDIUM, callback:(BitmapData)->Void)
    {
        var loader = BitmapData.loadFromFile(getIconPath(size));
        loader.onError(function (e)
        {
            final sizePx = getIconSize(size);
            callback(new BitmapData(sizePx, sizePx));
        });
        loader.onComplete(callback);
    }
    
    inline public function getIconPath(size:NGIconSize = MEDIUM)
    {
        return switch(size)
        {
            case SMALL: return this.icons.small;
            case MEDIUM: return this.icons.medium;
            case LARGE: return this.icons.large;
        }
    }
    
    inline function getIconSize(size:NGIconSize = MEDIUM)
    {
        return switch(size)
        {
            case SMALL: return 35;
            case MEDIUM: return 60;
            case LARGE: return 90;
        }
    }
}