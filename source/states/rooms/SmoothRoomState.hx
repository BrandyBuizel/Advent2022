package states.rooms;

class SmoothRoomState extends RoomState
{
    override function create()
    {
        flixel.FlxSprite.defaultAntialiasing = true;
        camera.pixelPerfectRender = false;
        super.create();
    }
}