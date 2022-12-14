package props;

import data.ArcadeGame;
import data.Calendar;
import data.Content;
import data.Manifest;
import data.Save;
import states.OgmoState;

import flixel.FlxSprite;

typedef CabinetValues = { id:ArcadeName }

class Cabinet extends flixel.FlxSprite
{
    public final enabled = false;
    public final data:ArcadeGame;
    
    public function new (id:String, x = 0.0, y = 0.0, scale = 1.0)
    {
        super(x, y);
        
        if (Content.arcades.exists(id))
        {
            data = Content.arcades[id];
            enabled = data.day <= Calendar.day;
        }
        
        if (enabled)
        {
            final path = 'assets/images/props/cabinets/${id}.png';
            #if debug
            if (Manifest.exists(path, IMAGE))
                loadGraphic(path);
            else
                loadGraphic('assets/images/props/shared/cabinet_ogmo.png');
            #else
            loadGraphic(path);
            #end
        }
        else
            loadGraphic('assets/images/props/shared/cabinet_broken.png');
        
        this.scale.set(scale, scale);
        updateHitbox();
        
        (this:OgmoDecal).setBottomHeight(100 * scale);
        immovable = true;
    }
    
    static public function fromEntity(data:OgmoEntityData<CabinetValues>)
    {
        var cabinet = new Cabinet(data.values.id, data.x, data.y, data.width / 136);
        if (data.flippedX != null)
            cabinet.flipX = data.flippedX;
        return cabinet;
    }
}