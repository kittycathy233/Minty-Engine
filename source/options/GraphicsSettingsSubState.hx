package options;

import objects.Character;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	var antialiasingOption:Int;
	//var boyfriend:Character = null;
	var aronaScr:Int;
	var arona:FlxGifSprite = null;
	var aronaTween:FlxTween;
	var warningText:FlxText; // 警告文本变量

	public function new()
	{
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		/*boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		boyfriend.animation.finishCallback = function (name:String) boyfriend.dance();
		boyfriend.visible = false;*/

		// 初始化Ais动画
		arona = new FlxGifSprite(0, 0);
		arona.loadGif('assets/shared/images/arona.gif');
		arona.setGraphicSize(Std.int(arona.width * 2.5));
		arona.screenCenter();
		arona.x = 1500;
		arona.antialiasing = ClientPrefs.data.antialiasing;
		arona.visible = true;
		arona.alpha = 0.9;

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', //Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', //Description
			'lowQuality', //Save data variable name
			'bool'); //Variable type
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'antialiasing',
			'bool');
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);
		antialiasingOption = optionsArray.length-1;

		var option:Option = new Option('Shaders', //Name
			"If unchecked, disables shaders.\nIt's used for some visual effects, and also CPU intensive for weaker PCs.", //Description
			'shaders',
			'bool');
		addOption(option);

		var option:Option = new Option('GPU Caching', //Name
			"If checked, allows the GPU to be used for caching textures, decreasing RAM usage.\nDon't turn this on if you have a shitty Graphics Card.", //Description
			'cacheOnGPU',
			'bool');
		addOption(option);

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?",
			'framerate',
			'int');
		addOption(option);
		aronaScr = optionsArray.length - 1;

		final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
		option.minValue = 20;
		option.maxValue = 1000;
		option.defaultValue = Std.int(FlxMath.bound(refreshRate, option.minValue, option.maxValue));
		option.displayFormat = '%v ';
		option.onChange = onChangeFramerate;
		#end

		super();
		//insert(1, boyfriend);
		insert(3, arona);

		// 初始化警告文本
		warningText = new FlxText(0, 50, FlxG.width - 40, "", 24);
		warningText.setFormat(Paths.font("ResourceHanRoundedCN-Bold.ttf"), 32, FlxColor.YELLOW, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		warningText.visible = false;
		warningText.alpha = 0.8; // 添加透明度
		add(warningText); // 确保在最上层

	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:FlxSprite = cast sprite;
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.data.antialiasing;
			}
		}
	}

	function onChangeFramerate()
	{
		if(ClientPrefs.data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.data.framerate;
			FlxG.drawFramerate = ClientPrefs.data.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.data.framerate;
			FlxG.updateFramerate = ClientPrefs.data.framerate;
		}
	}

	override function changeSelection(change:Int = 0)
	{
		// 安全清理之前的tween
		if (aronaTween != null)
		{
			aronaTween.cancel();
			aronaTween.destroy();
			aronaTween = null;
		}

		super.changeSelection(change);

		// 确保arona存在再创建tween
		if (arona != null && arona.exists)
		{
			aronaTween = FlxTween.tween(arona, {
				x: ((aronaScr == curSelected) || (antialiasingOption == curSelected)) ? 900 : 1500,
				angle: (aronaScr == curSelected) ? arona.angle : (Math.round(arona.angle / 360) * 360)
			}, 0.4, {
				ease: FlxEase.quadOut,
				onComplete: function(twn:FlxTween) {
					if (aronaTween == twn)
						aronaTween = null;
				}
			});
		}
	}
override function update(elapsed:Float)
	{
		super.update(elapsed);

		// 更新arona动画
		if (arona != null && aronaScr == curSelected)
			//arona.angle += elapsed * 100; // 使用时间增量保持旋转速度一致
			arona.angle += 1;

		#if !html5
		final showWarning:Bool = curSelected == aronaScr && 
			(ClientPrefs.data.framerate < 60 || ClientPrefs.data.framerate > 240);

		final isCritical:Bool = curSelected == aronaScr && ClientPrefs.data.framerate > 480;

		warningText.visible = showWarning || isCritical;
		if (isCritical) {
			warningText.text = Language.get("fps_warning_2");
			warningText.color = FlxColor.RED;
		} else if (showWarning) {
			warningText.text = Language.get("fps_warning_1");
			warningText.color = FlxColor.YELLOW;
		}
		#end
	}

	override function destroy()
	{
		if (aronaTween != null)
		{
			aronaTween.cancel();
			aronaTween.destroy();
			aronaTween = null;
		}
		
		if (arona != null)
		{
			arona.destroy();
			arona = null;
		}
		
		super.destroy();
	}

}