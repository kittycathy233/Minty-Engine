package states;

class WarningParticle extends FlxSprite
{
	var lifeTime:Float = 0;
	var decay:Float = 0;
	var originalScale:Float = 1;
	
	public function new(x:Float, y:Float, color:FlxColor)
	{
		super(x, y);
		this.color = color;

		// 使用简单的白色方块作为粒子，或者使用现有的粒子图像
		makeGraphic(4, 4, FlxColor.WHITE);
		
		lifeTime = FlxG.random.float(0.8, 1.2);
		decay = FlxG.random.float(0.5, 0.8);
		
		if(!ClientPrefs.data.flashing)
		{
			decay *= 0.5;
			alpha = 0.5;
		}

		originalScale = FlxG.random.float(0.5, 1.5);
		scale.set(originalScale, originalScale);

		scrollFactor.set(0, 0);
		velocity.set(FlxG.random.float(-20, 20), FlxG.random.float(-30, -50));
		acceleration.set(FlxG.random.float(-5, 5), 15);
		antialiasing = ClientPrefs.data.antialiasing;
	}

	override function update(elapsed:Float)
	{
		lifeTime -= elapsed;
		if(lifeTime < 0)
		{
			lifeTime = 0;
			alpha -= decay * elapsed;
			if(alpha > 0)
			{
				scale.set(originalScale * alpha, originalScale * alpha);
			}
		}
		super.update(elapsed);
	}
}