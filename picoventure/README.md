This is the template minigame for advent 2022.

For the most part, just grab this,
and code your game as usual and I'll know how to include it.

## Setup

Use flixel 5.0.0 via github:
```
haxelib git flixel https://github.com/HaxeFlixel/flixel.git
haxelib git flixel-addons https://github.com/HaxeFlixel/flixel-addons.git
```
Use the latest haxelib releases of everything else.
```
haxelib install lime
haxelib install openfl
haxelib install newgrounds
```


## Making your Own
Copy this template and rename every namespace `templatemg` to whatever unique namespace you've
given your game(Hint: Use Ctrl+Shift+F). This will prevent naming conflicts with the main Advent game, as well as other
minigames.

## Controls
Advent is set up with an advanced control system that takes Gamepads and keyboard buttons and
combines them into one easy to use system. Instead of `FlxG.keys.justPressed.Z` or
`FlxG.gamepads.firstActive.justPressed.A`, you can just use `Controls.justPressed.A`.

Check out the full list of controls, [here](https://github.com/BrandyBuizel/Advent2022/blob/main/source/ui/Controls.hx#L53-L77).
We also plan to add on-screen buttons for mobile.

*But George i need more controller buttons!!*
Anything extra you can add the normal way!

## Caveats
To allow your game to work in both stand-alone as well as in Advent, use `Global` methods
- Use `Global.width/height` instead of `FlxG.width/height`.
- Use `Global.screenCenter(obj, XY)` instead of `obj.screenCenter(XY)`, since the latter uses `FlxG.width`.
- Use `Global.state` instead of `FlxG.state`.
- Use `Global.switchState` and `Global.resetState` instead of `FlxG.switchState` and `FlxG.resetState`.
- Use `Global.asset("assets/images/myFile.png")` whenever passing a path into an asset loader.
- Use `Global.cancelTweensOf` instead of `FlxTween.cancelTweensOf`.

Note: The `Global` and `Controls` class are auto imported everywhere, via `import.hx`.

When played via advent, all your asset paths will be renamed to "assets/templatemg/images/myFile.png",
and in stand-alone mode they will be "assets/images/myFile.png", hence why Global.assets in neccesary.
`AssetPaths.hx` is also not an option.

Any code you want to only run when in stand-alone mode should be wrapped in `#if STAND_ALONE` checks,
similarly and advent-only code should be wrapped in `#if ADVENT`.

Check out more information on Conditional Compilation, [here](https://haxe.org/manual/lf-condition-compilation.html).

##
