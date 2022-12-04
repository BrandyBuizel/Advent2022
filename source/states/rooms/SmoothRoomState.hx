package states.rooms;

class SmoothRoomState extends RoomState
{
    override function create()
    {
        //anti-aliasing????
        flixel.FlxSprite.defaultAntialiasing = false;
        camera.pixelPerfectRender = true;
        super.create();
    }
}