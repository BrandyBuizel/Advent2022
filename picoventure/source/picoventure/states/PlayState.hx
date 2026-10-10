package picoventure.states;

import ui.AAText;
import flixel.text.FlxBitmapText;
import flixel.system.FlxSound;
import flixel.math.FlxPoint;
import data.ArcadeGame;
import haxe.Json;
import picoventure.data.Data;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxState;

import openfl.Assets;

using flixel.util.FlxSpriteUtil;

inline var SCALE = 540/1320;

/** 
 * PlayState.hx is where Advent will start to access your game,
 * if you would like to add a menu to your game contact George!
**/
class PlayState extends FlxState
{
	inline static var PAGE_TIME = 0.5;
	
	static var va:FlxSound;
	
	static public function uninit()
	{
		va.stop();
		va = null;
	}
	
	var pages:Map<PageId, PageData>;
	var currentPage:PageData;
	var flags = new Map<String, Bool>();
	
	var pageSprite:FlxSprite;
	var infoSprite:FlxSprite;
	var infoText:AAText;
	var buttonA:Button;
	var buttonB:Button;
	
	var pageTimer = 0.0;
	
	override function create()
	{
		super.create();
		
		var data:Data = cast Json.parse(Assets.getText(Global.asset("assets/data/data.json")));
		pages = data.getPageMap();
		
		add(pageSprite = new FlxSprite());
		add(buttonA = new Button(onChoose.bind(true)));
		add(buttonB = new Button(onChoose.bind(false)));
		add(infoSprite = new FlxSprite());
		infoSprite.makeGraphic(200, 20, 0x80808080);
		infoSprite.y = FlxG.height - infoSprite.height;
		add(infoText = new AAText(""));
		
		
		va = new FlxSound().loadEmbedded(Global.asset("assets/sounds/va.mp3"));
		
		showById("0");
	}
	
	function showById(id:PageId)
	{
		show(pages[id]);
	}
	
	function show(page:PageData)
	{
		currentPage = page;
		
		pageSprite.loadGraphic(Global.asset(page.imagePath));
		pageSprite.scale.set(SCALE, SCALE);
		pageSprite.updateHitbox();
		pageSprite.screenCenter();
		infoText.text = page.by;
		infoText.x = infoSprite.x + (infoSprite.width - infoText.width) / 2;
		infoText.y = infoSprite.y + (infoSprite.height - infoText.height) / 2;
		
		buttonA.exists = false;
		buttonB.exists = false;
		
		pageTimer = PAGE_TIME;
		
		if (page.sound.start > 0 || page.id == "0")
		{
			if (va.playing == false || va.time < page.sound.start || va.time > page.sound.end)
				va.play(true, page.sound.start);
		}
		else
			va.pause();
	}
	
	function initBranch(branch:BranchData, scale:Float)
	{
		if (branch == null || !branch.type.match(CHOICE))
			return;
		
		buttonA.drawBox(branch.boxA, scale);
		buttonA.x += pageSprite.x;
		buttonA.y += pageSprite.y;
		
		buttonB.drawBox(branch.boxB, scale);
		buttonB.x += pageSprite.x;
		buttonB.y += pageSprite.y;
	}
	
	/** This is where your game updates each frame */
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		va.update(elapsed);
		
		if (va.playing && va.time > currentPage.sound.end)
		{
			onPageSoundEnd();
			return;
		}
		
		pageTimer -= elapsed;
		if (pageTimer > 0)
			return;
		
		if (buttonA.exists)
		{
			final leftButton = buttonA.x < buttonB.x ? buttonA : buttonB;
			final rightButton = buttonA.x > buttonB.x ? buttonA : buttonB;
			if (Controls.justPressed.LEFT)
			{
				leftButton.selected = true;
				rightButton.selected = false;
			}
			
			if (Controls.justPressed.RIGHT)
			{
				leftButton.selected = false;
				rightButton.selected = true;
			}
			
			final topButton = buttonA.y < buttonB.y ? buttonA : buttonB;
			final bottomButton = buttonA.y > buttonB.y ? buttonA : buttonB;
			if (Controls.justPressed.UP)
			{
				topButton.selected = true;
				bottomButton.selected = false;
			}
			
			if (Controls.justPressed.DOWN)
			{
				topButton.selected = false;
				bottomButton.selected = true;
			}
		}
		
		if (Controls.justPressed.A || FlxG.mouse.justPressed)
			onPressSkip();
	}
	
	function onPageSoundEnd()
	{
		final isChoice = currentPage.branch != null && currentPage.branch.type.match(CHOICE);
		final isGameOver = currentPage.resetToId != null;
		final pause = isChoice || isGameOver;
		
		if (pause)
		{
			va.pause();
			if (isChoice)
			{
				var scale = 1.0;
				#if !debug // fixes weird glitch
				if (currentPage.id == "2")
					scale = 1.35;
				#end
				initBranch(currentPage.branch, scale);
			}
		}
		else
			showNextPage();
	}
	
	function onPressSkip()
	{
		if (currentPage.resetToId != null)
		{
			showById(currentPage.resetToId);
			return;
		}
		
		final branch = currentPage.branch;
		if (branch != null && branch.type.match(CHOICE))
		{
			if (buttonA.exists == false)
			{
				va.pause();
				onPageSoundEnd();
			}
			
			if (buttonA.selected && buttonB.selected)
				throw "both buttons chosen, somehow";
			
			if (buttonA.selected)
				buttonA.onClick();
			else if(buttonB.selected)
				buttonB.onClick();
			
			return;
		}
		
		showNextPage();
	}
	
	function showNextPage()
	{
		if (currentPage.branch != null && currentPage.branch.type.match(FLAG(_)))
		{
			switch(currentPage.branch.type)
			{
				case FLAG(id):
					onChoose(flags[id]);
					return;
				default:
			}
		}
		
		final nextPageId = currentPage.nextId;
		if (pages.exists(nextPageId))
			showById(nextPageId);
		#if ADVENT
		else
			Global.exit();
		#end
	}
	
	function onChoose(a:Bool)
	{
		if (currentPage.branch == null)
			throw "unexpected choice when there's no branch";
		
		final branch = currentPage.branch;
		
		if (branch.flag != null)
			flags[branch.flag] = a;
		
		final next = a ? branch.nextA : branch.nextB;
		if (next != null)
			showById(next);
		else
			showById(currentPage.nextId + (a ? "" : "b"));
	}
}

class Button extends FlxSprite
{
	static var mouse = FlxPoint.get();
	public var onClick:()->Void;
	public var selected = false;
	
	public function new(onClick:()->Void)
	{
		this.onClick = onClick;
		super();
	}
	
	public function drawBox(box:BoxData, scale:Float)
	{
		exists = true;
		selected = false;
		
		trace(box, SCALE);
		final w = Std.int((box.w + 20) * SCALE * scale);
		final h = Std.int((box.h + 20) * SCALE * scale);
		makeGraphic(w, h, 0x0);
		this.drawRect(0, 0, w, 5, 0xFFffffff);
		this.drawRect(0, 0, 5, h, 0xFFffffff);
		this.drawRect(w-5, 0, 5, h, 0xFFffffff);
		this.drawRect(0, h-5, w, 5, 0xFFffffff);
		x = (box.x - 10) * SCALE * scale;
		y = (box.y - 10) * SCALE * scale;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (FlxG.mouse.justMoved)
			selected = false;
		
		mouse = FlxG.mouse.getWorldPosition(mouse);
		final overlapping = overlapsPoint(mouse);
		color = (selected || overlapping) ? 0xFFff0000 : 0xFF800000;
		scale.x = scale.y = (selected || overlapping) ? 1.1 : 1.0;
		
		if (FlxG.mouse.justPressed && overlapping)
			onClick();
	}
}