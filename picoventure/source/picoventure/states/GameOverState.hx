package picoventure.states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import flixel.FlxState;

class GameOverState extends FlxState
{
	//Initialize Variables Here

	//This is the Start function
	override function create()
	{
		super.create();

		final info = new FlxText();
		info.alignment = "center";
		info.text = "This is the GAME OVER state.\n"
			+ "I'm sure you did your best.\n"
			+ "Press Z to play again.\n\n"
			+ "Game by\nlil' georgie\n\n"
			+ "Coded by\nyour mom\n\n"
			+ "Music by\nbrandy's nose-flute";
		Global.screenCenter(info);
		add(info);
	}

	//This is where your game updates each frame
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		//Code for your GameOverState starts here
		if (Controls.justPressed.A)
			//This loops back to your PlayState.hx
			Global.switchState(new PlayState());
	}
}