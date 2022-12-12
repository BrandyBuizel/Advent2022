package states.rooms;

import data.Save;
import ui.Phone;

import data.Skins;
import props.Notif;
import states.OgmoState;

import flixel.FlxG;
import flixel.math.FlxMath;

class OutsideState extends SmoothRoomState
{
    var changingRoom:OgmoDecal;
    var easterEgg:OgmoDecal;
    var changingRoomNotif:Notif;
    var tree:OgmoDecal;
    
    override function create()
    {
        super.create();
        
        add(new vfx.Snow());
        
        background.getByName("background").scrollFactor.set(0, 0.35);
        background.getByName("midground").scrollFactor.set( 0.7, 0.5);
        tree = foreground.getIndexNamedObject("tree", 33);
        if (tree != null)
            tree.setBottomHeight(tree.frameHeight / 4);
        
        // final treeBase = background.getByName("tree_base");
        // if (treeBase != null)
        // {
        //     background.remove(treeBase);
        //     foreground.add(treeBase);
        //     treeBase.setBottomHeight(90);
        // }
        
        for (candle in foreground.getAllWithName("clayfire"))
        {
            foreground.remove(candle);
            topGround.add(candle);
        }
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

        //Changing Room snowman and scary snowman
        var easter_egg_snowman_brandy = FlxG.random.bool(1); // 1% chance to return 'true'
        changingRoom = foreground.getByName("snowmanCC");
        easterEgg = foreground.getByName("snowmanCC_brandy");
        
        if(easter_egg_snowman_brandy)
        {
            easterEgg.visible = true;
            topGround.add(easterEgg);
            easterEgg.setBottomHeight(16);
        }
        else
        {
            easterEgg.visible = false;
        }

        changingRoom.setBottomHeight(16);
        addHoverTextTo(changingRoom, "CHANGE OUTFIT", onOpenDresser);

        //Clay notif
        changingRoomNotif = new Notif();
        changingRoomNotif.x = changingRoom.x + (changingRoom.width - changingRoomNotif.width) / 2;
        changingRoomNotif.y = changingRoom.y + changingRoom.height - changingRoom.frameHeight - 12;
        changingRoomNotif.animate();
        changingRoomNotif.visible = Skins.checkHasUnseen();
        topGround.add(changingRoomNotif);

        //Note by blue door saying it's closed
        var blue_door = foreground.getByName("blue_door");
        addHoverTextTo(blue_door, "      BLUE DOOR\nCOFFEE + WAFFLES\n\nCURRENTLY CLOSED"); //()->{ note.visible = !note.visible; });
        
        //foreground.remove(note);
        //topGround.add(note);
        //note.visible = false;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        updateCam(elapsed);
    }
    
    inline static var TREE_FADE_TIME = 3.0;
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

    function onOpenDresser()
    {
        changingRoomNotif.visible = false;
        var dressUp = new DressUpSubstate();
        dressUp.closeCallback = function()
        {
           player.settings.applyTo(player);
        }
        openSubState(dressUp);
    }
}