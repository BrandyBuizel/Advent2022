package states.rooms;

import ui.Phone;

import data.Skins;
import props.Notif;
import states.OgmoState;

import flixel.math.FlxMath;

class CandleState extends SmoothRoomState
{
    var clayfire:OgmoDecal;
    //var changingRoomNotif:Notif;
    
    override function create()
    {
        super.create();
        
        add(new vfx.Snow());
        
        //background.getByName("background").scrollFactor.set(0, 0.35);
    }
    
    // override function initUi()
    // {
    //     super.initUi();
    //     var phone = new Phone();
    //     ui.add(phone);
    // }
    
    override function initEntities()
    {
        super.initEntities();

        //Note by blue door saying it's closed
        //var blue_door = foreground.getByName("blue_door");
        //addHoverTextTo(blue_door, "      BLUE DOOR\nCOFFEE + WAFFLES\n\nCURRENTLY CLOSED"); //()->{ note.visible = !note.visible; });
        
        //foreground.remove(note);
        //topGround.add(note);
        //note.visible = false;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        updateCam(elapsed);
    }
    
    inline static var MAX_CAM_OFFSET = 200;
    inline static var CAM_SNAP_OFFSET = 30;
    inline static var CAM_SNAP_TIME = 3.0;
    inline static var CAM_LERP_OFFSET = MAX_CAM_OFFSET - CAM_SNAP_OFFSET;
    var camLerp = 0.0;
    var camSnap = 0.0;
    function updateCam(elapsed:Float)
    {
        final top = 450;
        final height = 150;
        final snapY = 540;
        // snap camera when above threshold
        if (player.y < snapY && camSnap < CAM_SNAP_OFFSET)
            camSnap += elapsed / CAM_SNAP_TIME * CAM_SNAP_OFFSET;
        else if (camOffset > 0)
            camSnap -= elapsed / CAM_SNAP_TIME * CAM_SNAP_OFFSET;
        // lerp camera in threshold
        camLerp = (height - (player.y - top)) / height * CAM_LERP_OFFSET;
        
        camOffset = camSnap + FlxMath.bound(camLerp, 0, CAM_LERP_OFFSET);
    }
}