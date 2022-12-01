package states.rooms;

class OutsideState extends SmoothRoomState
{
    override function create()
    {
        super.create();
        
        add(new vfx.Snow());
    }
    
    override function initEntities()
    {
        super.initEntities();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}