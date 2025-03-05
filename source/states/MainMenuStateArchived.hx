package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import options.OptionsState;

class MainMenuStateArchived extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.3';
	public static var extraKeysVersion:String = '0.4.9';
	public static var mintrhythmEngineVersion:String = '1.0.2';
	public static var curSelected:Int = 0;

	var menuItems:FlxSpriteGroup;
	var background:FlxSprite;
	var character:FlxSprite;
	var basePositions:Array<Array<Float>> = [];
	var isMouseControlling:Bool = false;

	final optionShit:Array<String> = [
		'story_mode', 'freeplay',
		'total_war', 'mods',
		'options', 'credits'
	];

	override function create()
	{
		super.create();

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		background = new FlxSprite().loadGraphic(Paths.image('menuExtend/baMenu/kivotosBG'));
		background.antialiasing = ClientPrefs.data.antialiasing;
		background.scrollFactor.set(0, 0);
		background.setGraphicSize(FlxG.width, FlxG.height);
		background.screenCenter();
		add(background);

		character = new FlxSprite(50, FlxG.height - 620);
		character.frames = Paths.getSparrowAtlas('menuExtend/baMenu/shiroko1st');
		character.animation.addByPrefix('idle', 'NP0172_spr_02', 24);
		character.animation.play('idle');
		character.setGraphicSize(Std.int(character.width * 0.8));
		character.updateHitbox();
		character.antialiasing = ClientPrefs.data.antialiasing;
		add(character);

		menuItems = new FlxSpriteGroup();
		add(menuItems);

		final startX = FlxG.width * 0.55;
		final startY = 150;
		final columnSpacing = 250;
		final rowSpacing = 140;

		for (i in 0...optionShit.length)
		{
			final col = i % 2;
			final row = Std.int(i / 2);
			final xPos = startX + (col * columnSpacing);
			final yPos = startY + (row * rowSpacing);
			basePositions.push([xPos, yPos]);

			final menuItem = new FlxSprite(xPos, yPos);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/${optionShit[i]}');
			menuItem.animation.addByPrefix('idle', 'idle', 24);
			menuItem.animation.addByPrefix('selected', 'selected', 24);
			menuItem.animation.play('idle');
			menuItem.scale.set(0.8, 0.8);
			menuItem.updateHitbox();
			menuItem.ID = i;
			menuItems.add(menuItem);
		}

		addVersionText();
		changeSelection(0);
	}

	function addVersionText()
	{
		var baseY = FlxG.height - 84;
		var texts = [
			{text: "BA Menu v1.0", y: baseY},
			{text: "MintRhythm v" + mintrhythmEngineVersion, y: baseY + 20},
			{text: "ExtraKeys v" + extraKeysVersion, y: baseY + 40},
			{text: "PsychEngine v" + psychEngineVersion, y: baseY + 60},
			{text: "FNF v" + Application.current.meta.get('version'), y: baseY + 80}
		];

		for (config in texts)
		{
			var text = new FlxText(12, config.y, 0, config.text, 16);
			text.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			add(text);
		}
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		character.y = FlxG.height - 620 + Math.sin(Conductor.songPosition * 0.001) * 5;

		var mouseX = (FlxG.mouse.x / FlxG.width - 0.5) * 25;
		var mouseY = (FlxG.mouse.y / FlxG.height - 0.5) * 15;
		background.x = FlxMath.lerp(background.x, mouseX, 0.1);
		background.y = FlxMath.lerp(background.y, mouseY, 0.1);

		updateMenuItemsPosition();
		handleMouseSelection();
		handleKeyboardNavigation();
	}

	function updateMenuItemsPosition()
	{
		final mouseXFactor = (FlxG.mouse.x / FlxG.width - 0.5) * 2;
		final mouseYFactor = (FlxG.mouse.y / FlxG.height - 0.5) * 2;

		for (i in 0...menuItems.members.length)
		{
			final item = menuItems.members[i];
			final offsetX = mouseXFactor * 20;
			final offsetY = mouseYFactor * 10;
			item.x = FlxMath.lerp(item.x, basePositions[i][0] + offsetX, 0.2);
			item.y = FlxMath.lerp(item.y, basePositions[i][1] + offsetY, 0.2);
		}
	}

	function handleMouseSelection()
	{
		if (FlxG.mouse.justMoved) isMouseControlling = true;
		if (FlxG.keys.anyJustPressed([UP, DOWN, LEFT, RIGHT])) isMouseControlling = false;

		if (isMouseControlling)
		{
			for (i in 0...menuItems.members.length)
			{
				final item = menuItems.members[i];
				if (FlxG.mouse.overlaps(item))
				{
					if (curSelected != i)
					{
						curSelected = i;
						updateSelectionVisual();
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
				}
			}
		}
	}

	function handleKeyboardNavigation()
	{
		if (!selectedSomethin && !isMouseControlling)
		{
			if (controls.UI_UP_P) changeSelection(-2);
			if (controls.UI_DOWN_P) changeSelection(2);
			if (controls.UI_LEFT_P) changeSelection(-1);
			if (controls.UI_RIGHT_P) changeSelection(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT) handleConfirm();
		}
	}

	function handleConfirm()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));
		selectedSomethin = true;

		FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, (_) -> 
		{
			switch (optionShit[curSelected]) {
				case 'story_mode': MusicBeatState.switchState(new StoryMenuState());
				case 'freeplay': MusicBeatState.switchState(new FreeplayState());
				#if MODS_ALLOWED case 'mods': MusicBeatState.switchState(new ModsMenuState()); #end
				case 'credits': MusicBeatState.switchState(new CreditsState());
				case 'options': MusicBeatState.switchState(new OptionsState());
				default: MusicBeatState.switchState(new MainMenuStateArchived());
			}
		});
	}

	function changeSelection(offset:Int)
	{
		var newSelection = curSelected + offset;
		newSelection = FlxMath.wrap(newSelection, 0, optionShit.length - 1);

		final currentCol = curSelected % 2;
		final targetCol = newSelection % 2;
		
		if (Math.abs(offset) == 1) {
			if (currentCol == 0 && offset == -1) newSelection = optionShit.length - 1;
			else if (currentCol == 1 && offset == 1) newSelection = 0;
			else if (currentCol != targetCol) newSelection += offset;
		}

		curSelected = FlxMath.wrap(newSelection, 0, optionShit.length - 1);
		updateSelectionVisual();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function updateSelectionVisual()
	{
		menuItems.forEach(item -> {
			if (item.ID == curSelected) {
				item.animation.play('selected');
				item.scale.set(1.0, 1.0);
			} else {
				item.animation.play('idle');
				item.scale.set(0.8, 0.8);
			}
			item.updateHitbox();
		});

		FlxG.camera.follow(menuItems.members[curSelected], LOCKON, 0.15);
	}
}