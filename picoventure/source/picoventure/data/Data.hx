package picoventure.data;

using StringTools;

typedef DataRaw =
{
    var pages:Array<PageData>;
    var branches:Dynamic;
}

typedef PageId = String;

abstract Data(DataRaw) from DataRaw
{
    public function getPageMap()
    {
        var map = new Map<PageId, PageData>();
        for (i=>page in this.pages)
        {
            final branch:BranchData = cast Reflect.field(this.branches, page.id);
            if (branch != null)
                page.branch = convertBranchData(cast branch);
            
            if (page.nextId == null)
                page.nextId = getNextPageId(page.id);
            
            if (page.sound == null)
                throw "missing sound id:" + page.id;
            
            if (page.sound.start == null)
                throw "missing sound start time id:" + page.id;
            
            var lastId = Std.string(Std.parseInt(page.id) - 1);
            if (page.id.endsWith("b") && map.exists(lastId + "b"))
                lastId += "b";
            
            if (i > 0 && this.pages[i - 1].sound.end == null)
                this.pages[i - 1].sound.end = page.sound.start;
            
            map[page.id] = page;
        }
        
        
        return map;
    }
    
    public function getNextPageId(id:PageId)
    {
        if (id.endsWith("b"))
            return nextPageHelper(id.substring(0, id.length - 1)) + "b";
        
        return nextPageHelper(id);
    }
    
    inline static function nextPageHelper(id:String)
    {
        return Std.string(Std.parseInt(id) + 1);
    }
    
    static function convertBranchData(data:BranchDataRaw)
    {
        final fullData:BranchData = cast data;
        fullData.type = convertBranchType(data.type);
        return fullData;
    }
    
    static function convertBranchType(type:String):BranchType
    {
        if (type == "choice")
            return CHOICE;
        
        return switch(type.split(":"))
        {
            case ["choice"]: CHOICE;
            case [_]: throw 'Unexpected branch type: $type';
            case ["flag", id]: return FLAG(id);
            case _: throw 'Unexpected branch type: $type';
        }
    }
}

typedef SoundData =
{
    var start:Int;
    var end:Int;
}

typedef PageDataRaw =
{
    var id:PageId;
    var imageId:String;
    var by:String;
    var sound:SoundData;
    var resetToId:Null<PageId>;
    var nextId:PageId;
}

typedef PageDataFull = PageDataRaw &
{
    var branch:Null<BranchData>;
}

@:forward
abstract PageData(PageDataFull) from PageDataFull
{
    public var imagePath(get, never):String;
    public function get_imagePath()
    {
        return 'assets/images/${this.imageId}.png';
    }
}

typedef BoxData = { x:Int, y:Int, w:Int, h:Int };

typedef BranchDataRaw =
{
    var type:String;
    var flag:Null<String>;
    var boxA:Null<BoxData>;
    var boxB:Null<BoxData>;
    var next2:Null<String>;
    var next1:Null<String>;
}

typedef BranchData =
{
    var type:BranchType;
    var flag:Null<String>;
    var boxA:Null<BoxData>;
    var boxB:Null<BoxData>;
    var nextA:Null<String>;
    var nextB:Null<String>;
}

enum BranchType
{
    CHOICE;
    FLAG(id:String);
}
