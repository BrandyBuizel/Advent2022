package data;

import utils.BitArray;

import io.newgrounds.Call;
import io.newgrounds.NG;
import io.newgrounds.NGLite;
import io.newgrounds.components.ScoreBoardComponent.Period;
import io.newgrounds.objects.Error;
import io.newgrounds.objects.Medal;
import io.newgrounds.objects.Score;
import io.newgrounds.objects.ScoreBoard;
import io.newgrounds.objects.events.Response;
import io.newgrounds.objects.events.Result;
import io.newgrounds.objects.events.Outcome;

import openfl.display.Stage;

import flixel.FlxG;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;

import haxe.PosInfos;
import haxe.macro.Compiler.getDefine as def;

class NGio
{
	inline static var DEBUG_SESSION = #if NG_DEBUG true #else false #end;
	
	inline static public var DAY_MEDAL_0 = 71341;
	
	inline static public var API_ID          :String = #if NG_API_ID     '${def("NG_API_ID"    )}'; #else ApiData.API_ID    ; #end
	inline static public var ENC_KEY         :String = #if NG_ENC_KEY    '${def("NG_ENC_KEY"   )}'; #else ApiData.ENC_KEY   ; #end
	inline static public var DEBUG_SESSION_ID:String = #if NG_SESSION_ID '${def("NG_SESSION_ID")}'; #else ApiData.SESSION_ID; #end
	
	public static var isLoggedIn(default, null):Bool = false;
	public static var userName(default, null):String;
	public static var scoreboardsLoaded(default, null):Bool = false;
	public static var ngDate(default, null):Date;
	public static var isContributor(default, null) = false;
	public static var serverVersion(default, null):String = null;
	public static var clientVersion(default, null):String = null;
	public static var validMajorVersion(default, null) = true;
	public static var validMinorVersion(default, null) = true;
	public static var validVersion(default, null) = true;
	
	public static var moviePremier(default, null):String = null;
	
	public static var scoreboardArray:Array<Score> = [];
	
	public static var ngDataLoaded(default, null):FlxSignal = new FlxSignal();
	public static var ngScoresLoaded(default, null):FlxSignal = new FlxSignal();
	
	static var boardsByName(default, null) = new Map<String, Int>();
	static var loggedEvents = new Array<NgEvent>();
	
	static public function attemptAutoLogin(callback:Void->Void) {
		
		#if NG_BYPASS_LOGIN
		NG.create(API_ID, null, DEBUG_SESSION);
		NG.core.scoreBoards.loadList(onScoreboardsRequested);
		callback();
		return;
		#end
		
		if (isLoggedIn)
		{
			log("already logged in");
			return;
		}
		
		ngDataLoaded.addOnce(callback);
		
		function checkSessionCallback(outcome:LoginOutcome)
		{
			switch(outcome)
			{
				case SUCCESS: // nothing
				case FAIL(error):
					
					log("session failed:" + error);
					ngDataLoaded.remove(callback);
					callback();
			}
		}
		
		var lastSessionId:String = null;
		if (DEBUG_SESSION_ID != null)
		{
			lastSessionId = DEBUG_SESSION_ID;
		}
		else if (FlxG.save.data.ngioSessionId != null)
		{
			lastSessionId = FlxG.save.data.ngioSessionId;
		}
		
		logDebug('connecting to newgrounds, debug:$DEBUG_SESSION session:' + lastSessionId);
		NG.createAndCheckSession(API_ID, DEBUG_SESSION, lastSessionId, checkSessionCallback);
		NG.core.setupEncryption(ENC_KEY);
		NG.core.onLogin.add(onNGLogin);
		#if NG_VERBOSE NG.core.verbose = true; #end
		logEventOnce(view);
		
		// Load scoreboards even if not logging in
		NG.core.scoreBoards.loadList(onScoreboardsRequested);
		
		if (!NG.core.attemptingLogin)
		{
			log("Auto login not attemped");
			ngDataLoaded.remove(callback);
			callback();
		}
	}
	
	static public function updateServerVersion(callback:()->Void)
	{
		clientVersion = lime.app.Application.current.meta.get('version');
		NG.core.calls.app.getCurrentVersion(clientVersion)
			.addOutcomeHandler((outcome)->switch (outcome)
			{
				case SUCCESS(data):
				{
					serverVersion = data.currentVersion;
					var serverArr = serverVersion.split(".").map(Std.parseInt);
					var clientArr = clientVersion.split(".").map(Std.parseInt);
					var server = serverArr.shift();
					var client = clientArr.shift();
					validMajorVersion = server <= client;
					var server = (server << 8) | serverArr.shift();
					var client = (client << 8) | clientArr.shift();
					validMinorVersion = server <= client;
					var server = (server << 8) | serverArr.shift();
					var client = (client << 8) | clientArr.shift();
					validVersion = server <= client;
					callback();
				}
				case FAIL(_):
				{
					serverVersion = null;
					validMajorVersion = false;
					validMinorVersion = false;
					validVersion = false;
					callback();
				}
			})
			.send();
	}
	
	static public function startManualSession(callback:(LoginOutcome)->Void, passportHandler:((Bool)->Void)->Void):Void
	{
		if (NG.core == null)
			throw "call NGio.attemptLogin first";
		
		function onClickDecide(connect:Bool):Void
		{
			if (connect)
				NG.core.openPassportUrl();
			else
				NG.core.cancelLoginRequest();
		}
		
		NG.core.requestLogin
			( callback
			, (_)->passportHandler(onClickDecide)
			);
	}
	
	static function onNGLogin():Void
	{
		isLoggedIn = true;
		userName = NG.core.user.name;
		logDebug('logged in! user:${NG.core.user.name}');
		
		// Save sessionId
		FlxG.save.data.ngioSessionId = NG.core.sessionId;
		FlxG.save.flush();
		
		NG.core.medals.loadList(onMedalsRequested);
		
		#if debug
		isContributor = true;
		#else
		isContributor = Content.isContributor(userName.toLowerCase());
		#end
		
		ngDataLoaded.dispatch();
	}
	
	static public function checkNgDate(onComplete:Void->Void):Void
	{
		NG.core.requestServerTime
		(
			function(outcome)
			{
				switch(outcome)
				{
					case SUCCESS(date): ngDate = date;
					case FAIL  (error): throw error.toString();
				}
				onComplete();
			}
		, true // useServerTime
		);
	}
	
	// --- SCOREBOARDS
	static function onScoreboardsRequested(outcome:Outcome<CallError>):Void
	{
		switch(outcome)
		{
			case SUCCESS: // nothing
			case FAIL(error):
				log('ERROR loading scoreboard: $error');
				return;
		}
		
		for (board in NG.core.scoreBoards)
		{
			boardsByName[board.name] = board.id;
			log('Scoreboard loaded ${board.name}:${board.id}');
			for (arcade in Content.arcades)
			{
				if (board.name == arcade.scoreboard)
				{
					arcade.scoreboardId = board.id;
					break;
				}
			}
		}
		
		ngScoresLoaded.dispatch();
	}
	
	static public function requestHiscores(id:String, limit = 10, skip = 0, social = false, ?callback:(Array<Score>)->Void)
	{
		if (!isLoggedIn)
			throw "Must log in to access player scores";
		
		if (NG.core.scoreBoards == null)
			throw "Cannot access scoreboards until ngScoresLoaded is dispatched";
		
		var boardId = getBoardById(id);
		if (boardId < 0)
			throw "Invalid board id:" + id;
		
		var board = NG.core.scoreBoards.get(boardId);
		if (callback != null)
			board.onUpdate.addOnce(()->callback(board.scores));
		board.requestScores(limit, skip, ALL, social);
	}
	
	static public function requestPlayerHiscore(id:String, callback:(Score)->Void)
	{
		if (!isLoggedIn)
			throw "Must log in to access player scores";
		
		if (NG.core.scoreBoards == null)
			throw "Cannot access scoreboards until ngScoresLoaded is dispatched";
		
		var boardId = getBoardById(id);
		if (boardId < 0)
			throw "Invalid board id:" + id;
		
		NG.core.scoreBoards.get(boardId).requestScores(1, 0, ALL, false, null, userName);
	}
	
	static public function requestPlayerHiscoreValue(id, callback:(Int)->Void)
	{
		requestPlayerHiscore(id, (score)->callback(score.value));
	}
	
	static public function postPlayerHiscore(id:String, value:Int, ?tag)
	{
		if (!isLoggedIn)
			return;
		
		if (NG.core.scoreBoards == null)
			throw "Cannot access scoreboards until ngScoresLoaded is dispatched";
		
		var boardId = getBoardById(id);
		if (boardId < 0)
			throw "Invalid board id:" + id;
		
		NG.core.scoreBoards.get(boardId).postScore(value, tag);
	}
	
	static function getBoardById(id:String)
	{
		if (boardsByName.exists(id))
			return boardsByName[id];
		
		if (Content.arcades.exists(id))
			return Content.arcades[id].scoreboardId;
		
		return -1;
	}
	
	// --- MEDALS
	static function onMedalsRequested(outcome:Outcome<CallError>):Void
	{
		switch(outcome)
		{
			case SUCCESS: // nothing
			case FAIL(error):
				log('ERROR loading medals: $error');
				return;
		}
		
		var numMedals = 0;
		var numMedalsLocked = 0;
		for (medal in NG.core.medals)
		{
			logVerbose('${medal.unlocked ? "unlocked" : "locked  "} - ${medal.name}');
			
			var dayMedal = medal.id - DAY_MEDAL_0 + 1;// one based
			if (!medal.unlocked)
				numMedalsLocked++;
			else if(dayMedal >= 1 && dayMedal <= 32)
			{
				logVerbose("seen day:" + dayMedal);
				// Save.daySeen(dayMedal);
			}
			
			numMedals++;
		}
		log('loaded $numMedals medals, $numMedalsLocked locked ');
	}
	
	static public function unlockDayMedal(day:Int, showDebugUnlock = true):Void
	{
		unlockMedal(DAY_MEDAL_0 + day - 1, showDebugUnlock);
	}
	
	static public function unlockMedalByName(name:String, showDebugUnlock = true):Void
	{
		if (!Content.medals.exists(name))
			throw 'invalid name:%name';
		
		unlockMedal(Content.medals[name]);
	}
	
	static public function unlockMedal(id:Int, showDebugUnlock = true):Void
	{
		#if !(NG_DEBUG_API_KEY)
		if (isLoggedIn && !Calendar.isDebugDay)
		{
			log("unlocking " + id);
			var medal = NG.core.medals.get(id);
			if (!medal.unlocked)
				medal.sendUnlock();
			else if (showDebugUnlock)
				#if debug medal.onUnlock.dispatch();
				#else log("already unlocked");
				#end
		}
		else
			log('no medal unlocked, loggedIn:$isLoggedIn debugDay${!Calendar.isDebugDay}');
		#else
		log('no medal unlocked, using debug api key');
		#end
	}
	
	static public function hasDayMedal(date:Int):Bool
	{
		return hasMedal(DAY_MEDAL_0 + date - 1);
	}
	
	static public function hasMedal(id:Int):Bool
	{
		#if NG_DEBUG_API_KEY
		return false;
		#else
		return isLoggedIn && NG.core.medals.get(id).unlocked;
		#end
	}
	
	static public function hasMedalByName(name:String):Bool
	{
		if (!Content.medals.exists(name))
		#if noContent
			return false;
		#else
			throw 'invalid name:%name';
		#end
		
		return hasMedal(Content.medals[name]);
	}
	
	static public function checkForMoviePremier(callback:(Null<String>)->Void)
	{
		NG.core.calls.loader.loadAuthorUrl()
			.addOutcomeHandler
				(	(outcome)->switch(outcome)
					{
						case FAIL(_):callback(moviePremier);
						case SUCCESS(data):
							if (data.url.indexOf(".mp4?") != -1)
								moviePremier = data.url;
							
							callback(moviePremier);
					}
				)
			.send();
	}
	
	static public function logEvent(event:NgEvent, once = false, ?pos:PosInfos)
	{
		#if !(NG_DEBUG_API_KEY)
		if (loggedEvents.contains(event))
		{
			if (once) return;
		}
		else
			loggedEvents.push(event);
		
		var platform = FlxG.onMobile ? "_mobile" : "_desktop";
		// swap _ for - because NG project events aren't allowing _
		var eventStr = (event + platform).split("_").join("-");
		log("logging event: " + eventStr, pos);
		NG.core.calls.event.logEvent(eventStr).send();
		#end
	}
	
	static public function logEventOnce(event:NgEvent, ?pos:PosInfos)
	{
		logEvent(event, true, pos);
	}
	
	inline static function logVerbose(msg:String, ?pos:PosInfos)
	{
		#if NG_VERBOSE log(msg, pos); #end
	}
	
	inline static function logDebug(msg:String, ?pos:PosInfos)
	{
		#if debug log(msg, pos); #end
	}
	
	inline static function log(msg:String, ?pos:PosInfos)
	{
		#if NG_LOG haxe.Log.trace(msg, pos); #end
	}
}

enum abstract NgEvent(String) from String to String
{
	var view;
	var enter;
	var attempt_connect;
	var first_connect;
	var connect;
	var daily_present;
	var intro_complete;
	var donate;
	var donate_yes;
}

