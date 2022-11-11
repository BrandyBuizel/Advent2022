package utils;

import states.OverlaySubstate;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.FlxState;
import flixel.util.FlxAxes;

class OverlayGlobal
{
    public static var width(get, never):Int;
    inline static function get_width() return container.camera.width;
    public static var height(get, never):Int;
    inline static function get_height() return container.camera.height;
    public static var camera(get, never):FlxCamera;
    inline static function get_camera() return container.camera;
    public static var state(get, never):FlxState;
    inline static function get_state() return container.state;
    
    @:allow(states.OverlaySubstate)
    static var container:OverlaySubstate;
    
    static public function switchState(state:FlxState)
    {
        container.switchState(state);
    }
    
    static public function resetState()
    {
        switchState(Type.createInstance(Type.getClass(container.state), []));
    }
    
    static public function cancelTweensOf(object, ?fieldPaths)
    {
        container.cancelTweensOf(object, fieldPaths);
    }
    
    static public function asset(path:String):String
    {
        final id = container.data.id;
        path = id + ":" + path.split("assets/").join('assets/arcades/$id/');
        trace(path);
        return path;
    }
    
    inline static public function screenCenterX(obj:FlxObject)
    {
        obj.x = (width - obj.width) / 2;
    }
        
    inline static public function screenCenterY(obj:FlxObject)
    {
        obj.y = (height - obj.height) / 2;
    }
    
    inline static public function screenCenter(obj:FlxObject, axes = FlxAxes.XY)
    {
        switch (axes)
        {
            case NONE:
            case XY:
                screenCenterX(obj);
                screenCenterY(obj);
            case X:
                screenCenterX(obj);
            case Y:
                screenCenterY(obj);
        }
    }
}