package;

#if (android && !macro)
import extension.androidtools.content.Context;
#end

//import debug.FPSCounter;
import debug.SimpleFPSCounter;
import flixel.FlxGame;
import flixel.FlxG;
import haxe.io.Path;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;
import states.MainMenuState;

#if linux
import lime.graphics.Image;
#end

// Crash handler imports
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
#end

import backend.ExtraKeysHandler;

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end

class MainOptimized extends Sprite
{
	// Game configuration constants
	private static final GAME_CONFIG = {
		windowWidth: 1280,
		windowHeight: 720,
		initialState: TitleState,
		zoom: -1.0,
		framerate: 120,
		skipSplash: false,
		startFullscreen: false
	};

	public static var fpsVar:SimpleFPSCounter;
	private var flxGame:FlxGame;

	public static function main():Void
	{
		Lib.current.addChild(new MainOptimized());
	}

	public function new()
	{
		super();
		setupWorkingDirectory();
		
		if (stage != null)
		{
			initializeGame();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, initializeGame);
		}
	}

	/**
	 * 设置工作目录（Android/iOS）
	 */
	private function setupWorkingDirectory():Void
	{
		// Credits to MAJigsaw77
		#if (android && !macro)
			Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif ios
			Sys.setCwd(lime.system.System.applicationStorageDirectory);
		#end
	}

	/**
	 * 游戏初始化主函数
	 */
	private function initializeGame(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, initializeGame);
		}

		setupGameConfiguration();
		initializeGameSystems();
		setupPlatformSpecificFeatures();
		registerEventHandlers();
	}

	/**
	 * 设置游戏基础配置
	 */
	private function setupGameConfiguration():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		Language.load();

		// 计算缩放比例
		var finalWidth = GAME_CONFIG.windowWidth;
		var finalHeight = GAME_CONFIG.windowHeight;
		var finalZoom = GAME_CONFIG.zoom;

		if (GAME_CONFIG.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / GAME_CONFIG.windowWidth;
			var ratioY:Float = stageHeight / GAME_CONFIG.windowHeight;
			finalZoom = Math.min(ratioX, ratioY);
			finalWidth = Math.ceil(stageWidth / finalZoom);
			finalHeight = Math.ceil(stageHeight / finalZoom);
		}

		// 创建游戏实例
		flxGame = new FlxGame(finalWidth, finalHeight, GAME_CONFIG.initialState, 
			#if (flixel < "5.0.0") finalZoom, #end 
			GAME_CONFIG.framerate, GAME_CONFIG.framerate, 
			GAME_CONFIG.skipSplash, GAME_CONFIG.startFullscreen);

		addChild(flxGame);
	}

	/**
	 * 初始化游戏系统
	 */
	private function initializeGameSystems():Void
	{
		#if LUA_ALLOWED
			Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call));
		#end

		// 初始化控制相关系统
		Controls.instance = new Controls();
		ExtraKeysHandler.instance = new ExtraKeysHandler();
		ClientPrefs.loadDefaultKeys();

		#if ACHIEVEMENTS_ALLOWED
			Achievements.load();
		#end

		// 设置引擎版本信息
		MainMenuState.mtEngineVersion = Application.current.meta.get('version');

		// 设置FPS计数器
		setupFPSCounter();

		// Discord初始化
		#if DISCORD_ALLOWED
			DiscordClient.prepare();
		#end

		// Windows桌面特定功能
		#if desktop
			setupWindowsFeatures();
		#end
	}

	/**
	 * 设置FPS计数器
	 */
	private function setupFPSCounter():Void
	{
		#if !mobile
			fpsVar = new SimpleFPSCounter(10, 10);
			addChild(fpsVar);
			fpsVar.x = 10;
			Lib.current.stage.align = "tl";
			Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
			
			if(fpsVar != null)
			{
				fpsVar.visible = ClientPrefs.data.showFPS;
			}
		#end
	}

	/**
	 * Windows桌面特定功能设置
	 */
	private function setupWindowsFeatures():Void
	{
		// WindowColorMode.setDarkMode();
		WindowColorMode.setWindowBorderColor([135, 206, 250], true, false);
		WindowsAPI.resetWindowsFuncs();
		WindowsAPI.sendWindowsNotification("你好", "我是傻逼");
	}

	/**
	 * 平台特定功能设置
	 */
	private function setupPlatformSpecificFeatures():Void
	{
		#if linux
			setupLinuxIcon();
		#end

		#if html5
			FlxG.autoPause = false;
			FlxG.mouse.visible = false;
		#end
	}

	/**
	 * Linux平台图标设置
	 */
	private function setupLinuxIcon():Void
	{
		#if linux
			var icon = Image.fromFile("icon.png");
			Lib.current.stage.window.setIcon(icon);
		#end
	}

	/**
	 * 注册事件处理器
	 */
	private function registerEventHandlers():Void
	{
		// 崩溃处理
		#if CRASH_HANDLER
			Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		// 游戏窗口大小变化处理
		FlxG.signals.gameResized.add(onGameResized);
	}

	/**
	 * 游戏窗口大小变化处理
	 */
	private function onGameResized(w:Int, h:Int):Void
	{
		// 重置着色器缓存
		if (FlxG.cameras != null)
		{
			for (cam in FlxG.cameras.list)
			{
				if (cam != null && cam.filters != null)
				{
					resetSpriteCache(cam.flashSprite);
				}
			}
		}

		if (FlxG.game != null)
		{
			resetSpriteCache(FlxG.game);
		}
	}

	/**
	 * 重置精灵缓存（Shader坐标修复）
	 */
	private static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	/**
	 * 崩溃处理函数
	 * 代码由 sqirra-rng 为 "Izzy Engine" 编写
	 */
	#if CRASH_HANDLER
	private function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		
		// 生成时间戳格式的文件名
		var dateNow:String = Date.now().toString();
		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");
		
		path = "./crash/" + "PsychEngine_" + dateNow + ".txt";

		// 构建错误信息
		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error + 
		         "\nIf this is related to EK, report it here: https://github.com/FunkinExtraKeys/FNF-PsychEngine-EK" +
		         "\nIf not, report this error to Psych Engine: https://github.com/ShadowMario/FNF-PsychEngine" +
		         "\n\n> Crash Handler written by: sqirra-rng";

		// 确保崩溃目录存在
		if (!FileSystem.exists("./crash/"))
		{
			FileSystem.createDirectory("./crash/");
		}

		// 保存崩溃日志
		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		// 显示错误对话框
		Application.current.window.alert(errMsg, "Error!");
		
		#if DISCORD_ALLOWED
			DiscordClient.shutdown();
		#end
		
		Sys.exit(1);
	}
	#end
}