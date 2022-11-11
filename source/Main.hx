package;

import states.rooms.RoomState;

class Main extends openfl.display.Sprite
{
	public function new()
	{
		super();
		addChild(new flixel.FlxGame(960, 540, states.BootState, true));
		
		trace("version:" + openfl.Lib.application.meta.get("version"));
		trace("render context: " + stage.window.context.type);
	}
}
