package states.rooms;

import props.Present;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import data.Manifest;
import data.Game;
import states.rooms.RoomState;
import data.Calendar;
import data.Content;
import data.NGio;
import data.Save;
import ui.CreditsScroll;
import ui.Phone;
import ui.Prompt;

import data.Skins;
import props.Notif;
import states.OgmoState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;

class OutsideState extends SmoothRoomState
{
    static public function hasNotifs()
    {
        return Skins.showNotif;
    }
    
    var changingRoom:OgmoDecal;
    var easterEgg:OgmoDecal;
    var changingRoomNotif:Notif;
    var theatreNotif:Notif;
    var tree:OgmoDecal;
    var midground:OgmoDecal;
    
    override function create()
    {
        super.create();
        add(new vfx.Snow());
        
        #if debug
        new CreditsScroll(0);
        #end
        
        background.getByName("background").scrollFactor.set(0, 0.0);
        midground = background.getIndexNamedObject("midground", 33);
        midground.scrollFactor.set( 0.7, 0.5);
        
        tree = foreground.getIndexNamedObject("tree", 33);
        tree.animation.curAnim.frameRate = 2;
        
        var theatreTeleport = teleportsById[RoomName.TheaterScreen];
        if (theatreTeleport != null)
        {
            final isMoviePremier = NGio.moviePremier != null;
            theatreTeleport.enabled = isMoviePremier;
            if (isMoviePremier)
            {
                theatreNotif = new Notif(0, theatreTeleport.y - 50);
                theatreNotif.x = theatreTeleport.x + (theatreTeleport.width - theatreNotif.width) / 2;
                theatreNotif.animate();
                theatreNotif.visible = !NGio.hasMedalByName("movie");
                topGround.add(theatreNotif);
            }
        }

        // tree = foreground.getIndexNamedObject("tree", 33);
        // if (tree != null)
        //     tree.setBottomHeight(tree.frameHeight / 4);
        
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
        addHoverTextTo(blue_door, "      BLUE DOOR\nCOFFEE + WAFFLES"); //()->{ note.visible = !note.visible; });

        //Sign press to go to cabin
        if(Calendar.day >= 21)
        {
            var sign = foreground.getByName("sign");
            addHoverTextTo(sign, "GO TO CABIN", ()->{ 
                //Do stuff
            });
        }
        
        //foreground.remove(note);
        //topGround.add(note);
        //note.visible = false;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        updateCam(elapsed);
        
        #if debug
        if (FlxG.keys.justPressed.T && Game.state.match(NONE))
        {
            startOutro();
        }
        #end
    }
    
    override function onOpenPresent(present:Present)
    {
        super.onOpenPresent(present);
        
        if (Calendar.day != 32)
            return;
        
        for (present in presents)
        {
            if (present.isOpen == false)
                return;
        }
        
        startOutro();
    }
    
    function startOutro()
    {
        Game.state = OUTRO(START);
        final camera = FlxG.camera;
        player.enabled = false;
        var music = Manifest.playMusic("droid", false, exitOutro.bind(camera.scroll.y));
        camera.follow(null);
        camera.minScrollY = null;
        FlxTween.tween(camera.scroll, { y: -200 }, 34,
        {   startDelay: 3, 
            ease:FlxEase.cubeInOut,
            onComplete: function (_)
            {
                Game.state = OUTRO(PAN);
                
                add(new CreditsScroll(music.length / 1000 - (34 - 3)));
                FlxG.fixedTimestep = true;
            }
        });
        
    }
    
    function exitOutro(oldPan:Float)
    {
        FlxG.fixedTimestep = false;
        final camera = FlxG.camera;
        Game.state = OUTRO(END);
        FlxTween.tween(camera.scroll, { y: oldPan }, 10,
        {   ease:FlxEase.cubeInOut,
            onComplete: function (_)
            {
                camera.follow(player);
                camera.minScrollY = 0;
                Game.state = NONE;
                player.enabled = true;
                Content.playTodaysSong();
                NGio.unlockMedalByName("credits");
            }
        });
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