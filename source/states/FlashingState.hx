package states;

import flixel.FlxSubState;

import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warnText:FlxText;
	var particles:FlxTypedGroup<WarningParticle>;
	var particleTimer:Float = 0;
	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		// 创建粒子系统
		particles = new FlxTypedGroup<WarningParticle>();
		add(particles);

		warnText = new FlxText(0, 0, FlxG.width,
			"Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Press ENTER to disable them now or go to Options Menu.\n
			Press ESCAPE to ignore this message.\n
			You've been warned!",
			32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
	}

	override function update(elapsed:Float)
	{
		// 生成粒子效果
		if(!leftState)
		{
			particleTimer += elapsed;
			if(particleTimer > 0.05) // 每0.05秒生成一个粒子
			{
				particleTimer = 0;
				
				// 在警告文本周围生成粒子
				var particleX:Float = FlxG.random.float(warnText.x, warnText.x + warnText.width);
				var particleY:Float = FlxG.random.float(warnText.y, warnText.y + warnText.height);
				
				// 随机选择粒子颜色（白色、黄色、红色）
				var colors:Array<FlxColor> = [FlxColor.WHITE, FlxColor.YELLOW, FlxColor.RED];
				var particleColor:FlxColor = colors[FlxG.random.int(0, colors.length - 1)];
				
				var particle:WarningParticle = new WarningParticle(particleX, particleY, particleColor);
				particles.add(particle);
			}
		}
		
		if(!leftState) {
			var back:Bool = controls.BACK;
			if (controls.ACCEPT || back) {
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				if(!back) {
					ClientPrefs.data.flashing = false;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('confirmMenu'));
					FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker) {
						new FlxTimer().start(0.5, function (tmr:FlxTimer) {
							MusicBeatState.switchState(new TitleState());
						});
					});
				} else {
					FlxG.sound.play(Paths.sound('cancelMenu'));
					FlxTween.tween(warnText, {alpha: 0}, 1, {
						onComplete: function (twn:FlxTween) {
							MusicBeatState.switchState(new TitleState());
						}
					});
				}
			}
		}
		super.update(elapsed);
	}
}
