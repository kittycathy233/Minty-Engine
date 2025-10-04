package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;

import substates.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	// 在类字段部分添加滚动条变量
	var scrollBarBG:FlxSprite;
	var scrollBarThumb:FlxSprite;
	private var isDraggingScrollBar:Bool = false;
	private var dragOffsetY:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;
	var missingTextTween:FlxTween; // 新增：错误文本渐隐动画

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

	var player:MusicPlayer;

	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.targetY = i;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			
			// too laggy with a lot of songs, so i had to recode the logic for it
			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
    // 调整原有分数显示位置避免重叠
    scoreText.x = FlxG.width * 0.6; // 从0.7改为0.6

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);


		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		missingText.alpha = 0;
		add(missingText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		// 添加初始窗口标题栏颜色设置
		#if windows
		var colorArray = [
			(intendedColor >> 16) & 0xFF, // R
			(intendedColor >> 8) & 0xFF, // G
			intendedColor & 0xFF // B
		];
		WindowColorMode.setWindowBorderColor(colorArray, true, false);
		//WindowColorMode.redrawWindowHeader();
		#end

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
// 在 create() 中找到滚动条创建部分替换为：
scrollBarBG = new FlxSprite(FlxG.width - 28, 50).makeGraphic(12, FlxG.height - 150, 0xFF444444);
scrollBarBG.alpha = 0.6;
add(scrollBarBG);

scrollBarThumb = new FlxSprite(scrollBarBG.x, scrollBarBG.y).makeGraphic(12, 40, 0xFFFFFFFF);
scrollBarThumb.alpha = 0.8;
add(scrollBarThumb);

FlxG.mouse.visible = true; // 添加鼠标可见
		bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);
		
		player = new MusicPlayer(this);
		add(player);
		
		changeSelection();
		updateTexts();
		super.create();
	}

	/**
	 * 统一错误显示函数
	 * @param errorStr 错误信息
	 */
	private function showError(errorStr:String)
	{
		// 取消之前的渐隐动画（支持打断）
		if (missingTextTween != null) {
			missingTextTween.cancel();
			missingTextTween = null;
		}

		// 设置错误文本
		missingText.text = (errorStr.contains('Missing file: assets/data/') ? 'ERROR WHILE LOADING CHART:\n' : 'ERROR WHILE LOADING SONG:\n') + errorStr;
		missingText.screenCenter(Y);
		
		// 显示错误信息
		missingTextBG.visible = true;
		missingText.visible = true;
		
		// 渐入效果
		missingTextBG.alpha = 0;
		missingText.alpha = 0;
		
		FlxTween.tween(FlxG.camera, {x: -10}, 0.2, {ease: FlxEase.quartOut});
		FlxTween.tween(FlxG.camera, {x: 0}, 0.2, {ease: FlxEase.quartIn, startDelay: 0.2});
		FlxTween.tween(missingTextBG, {alpha: 0.6}, 0.4, {ease: FlxEase.quartOut});
		FlxTween.tween(missingText, {alpha: 1}, 0.4, {ease: FlxEase.quartOut});
		
		// 2秒后渐隐
		if (missingTextTween != null && !missingTextTween.finished) {
			missingTextTween.cancel();
		}
		missingTextTween = FlxTween.tween(missingTextBG, {alpha: 0}, 0.5, {
			startDelay: 2,
			onComplete: function(twn:FlxTween) {
				missingTextBG.visible = false;
				missingText.visible = false;
				missingTextTween = null;
			}
		});
		FlxTween.tween(missingText, {alpha: 0}, 0.5, {startDelay: 2});
		
		FlxG.sound.play(Paths.sound('cancelMenu'));
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (!player.playingMusic)
		{
			scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
			positionHighscore();
			
			if(songs.length > 1)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;	
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;	
				}
				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}

				if(FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}

			if (controls.UI_LEFT_P)
			{
				changeDiff(-1);
				_updateSongLastDifficulty();
			}
			else if (controls.UI_RIGHT_P)
			{
				changeDiff(1);
				_updateSongLastDifficulty();
			}
		}

		if (controls.BACK)
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;

				player.playingMusic = false;
				player.switchPlayMusic();

				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else 
			{
				persistentUpdate = false;
				if(colorTween != null) {
					colorTween.cancel();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				/*if (!ClientPrefs.data.BAMenu) */MusicBeatState.switchState(new MainMenuState());
				//else MusicBeatState.switchState(new MainMenuStateArchived());
			}
		}

		if(FlxG.keys.justPressed.CONTROL && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(FlxG.keys.justPressed.SPACE)
		{
			if(instPlaying != curSelected && !player.playingMusic)
			{
				// 添加试听时的错误检查
				try
				{
					destroyFreeplayVocals();
					FlxG.sound.music.volume = 0;

					Mods.currentModDirectory = songs[curSelected].folder;
					var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
					PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
					if (PlayState.SONG.needsVoices)
					{
						var vocalsPath:String = "";
						var vocalsLoaded:Bool = false;
						
						trace('Loading vocals for song: ${PlayState.SONG.song}');
						destroyFreeplayVocals(); // 确保清理旧的人声音频

						// 加载人声音频的主逻辑
						var vocalPathsToTry:Array<String> = [];
						
						// 构建尝试路径列表
						if(PlayState.SONG.specialVocal != null && PlayState.SONG.specialVocal.length > 0) {
							trace('Found specialVocal: ${PlayState.SONG.specialVocal}');
							// 1. 特殊人声路径
							vocalPathsToTry.push('Voices-${PlayState.SONG.specialVocal}');
							// 2. 特殊角色人声路径
							vocalPathsToTry.push('Voices-${PlayState.SONG.specialVocal}-opponent');
							vocalPathsToTry.push('Voices-${PlayState.SONG.specialVocal}-player');
						}
						// 3. 默认人声路径
						vocalPathsToTry.push('Voices');
						// 4. 默认角色人声路径
						vocalPathsToTry.push('Voices-opponent');
						vocalPathsToTry.push('Voices-player');

						// 按顺序尝试加载
						for(path in vocalPathsToTry) {
							if(vocalsLoaded) break;
							
							try {
								trace('Attempting to load vocals: $path');
								vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song, path));
								FlxG.sound.list.add(vocals);
								vocals.volume = 0.8;
								vocals.persist = true;
								vocals.looped = true;
								vocalsLoaded = true;
								trace('Successfully loaded vocals from: $path');
								
								// 确保人声与伴奏同步
								if(FlxG.sound.music.playing) {
									vocals.time = FlxG.sound.music.time;
									vocals.play();
								}
							} catch(e:Dynamic) {
								trace('Failed to load vocals from $path: $e');
							}
						}

						if(!vocalsLoaded) {
							trace('All vocal loading attempts failed, creating empty sound object');
							vocals = new FlxSound();
							FlxG.sound.list.add(vocals);
						}
						
						trace('Vocal loading completed. Final status: ${vocalsLoaded ? "SUCCESS" : "FAILED"}');
						
						if(!vocalsLoaded) {
							trace('All vocal loading attempts failed, creating empty sound object');
							vocals = new FlxSound();
						}
						
						trace('Vocal loading completed. Final status: ${vocalsLoaded ? "SUCCESS" : "FAILED"}');
						FlxG.sound.list.add(vocals);
						vocals.persist = true;
						vocals.looped = true;
					}
					else if (vocals != null)
					{
						vocals.stop();
						vocals.destroy();
						vocals = null;
					}

					var instPath:String = PlayState.SONG.specialInst != null ? Std.string(PlayState.SONG.specialInst) : "";
					FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, instPath), 0.8);
					if(vocals != null) //Sync vocals to Inst
					{
						vocals.play();
						vocals.volume = 0.8;
					}
					instPlaying = curSelected;

					player.playingMusic = true;
					player.curTime = 0;
					player.switchPlayMusic();
				}
				catch(e:Dynamic)
				{
					trace('ERROR WHILE LOADING MUSIC PREVIEW! $e');
					var errorStr:String = e.toString();
					if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(34, errorStr.length-1); //Missing chart
					
					// 使用统一的错误显示函数
					showError(errorStr);
					
					// 重置试听状态
					instPlaying = -1;
					player.playingMusic = false;
					player.switchPlayMusic();
				}
			}
			else if (instPlaying == curSelected && player.playingMusic)
			{
				player.pauseOrResume(player.paused);
			}
		}
		else if (controls.ACCEPT && !player.playingMusic)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			/*#if MODS_ALLOWED
			if(!FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !FileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
			#else
			if(!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
			#end
				poop = songLowercase;
				curDifficulty = 1;
				trace('Couldnt find file');
			}*/
			trace(poop);

			try
			{
				PlayState.SONG = Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;

				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
				if(colorTween != null) {
					colorTween.cancel();
				}
			}
			catch(e:Dynamic)
			{
				trace('ERROR! $e');

				var errorStr:String = e.toString();
				if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(34, errorStr.length-1); //Missing chart
				
				// 使用统一的错误显示函数替换原来的错误显示
				showError(errorStr);
				
				updateTexts(elapsed);
				super.update(elapsed);
				return;
			}
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.volume = 0;
					
			destroyFreeplayVocals();
			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
		else if(controls.RESET && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		updateTexts(elapsed);
// 鼠标拖动滚动条处理
var mousePos = FlxG.mouse.getScreenPosition(camera);
if (FlxG.mouse.justPressed) {
    if (scrollBarThumb.overlapsPoint(mousePos)) {
        isDraggingScrollBar = true;
        dragOffsetY = mousePos.y - scrollBarThumb.y;
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4); // 添加拖动开始音效
    } else if (scrollBarBG.overlapsPoint(mousePos)) {
        var localY = mousePos.y - scrollBarBG.y;
        var percent = localY / scrollBarBG.height;
        curSelected = Std.int(percent * (songs.length - 1));
        changeSelection(0, false);
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        isDraggingScrollBar = true;
        lerpSelected = curSelected; // 立即同步lerp值
    }
}

if (isDraggingScrollBar && FlxG.mouse.pressed) {
    // 计算滑块新位置
    var newY = FlxMath.bound(mousePos.y - dragOffsetY, scrollBarBG.y, scrollBarBG.y + scrollBarBG.height - scrollBarThumb.height);
    
    // 直接设置滑块位置
    scrollBarThumb.y = newY;
    
    // 根据滑块位置计算选中项
    var percent = (newY - scrollBarBG.y) / (scrollBarBG.height - scrollBarThumb.height);
    curSelected = Std.int(percent * (songs.length - 1));
	curSelected = Math.round(FlxMath.bound(curSelected, 0, songs.length - 1));
	
	// 立即同步显示
    lerpSelected = curSelected; // 跳过平滑过渡
    changeSelection(0, false);  // 不播放音效
    updateTexts();              // 强制立即更新
}

if (FlxG.mouse.justReleased) {
    isDraggingScrollBar = false;
}
super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic)
			return;

		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + lastDifficultyName.toUpperCase() + ' >';
		else
			diffText.text = lastDifficultyName.toUpperCase();

		positionHighscore();
		// 隐藏错误信息（如果有）
		if (missingTextTween != null) {
			missingTextTween.cancel();
			missingTextTween = null;
		}
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic)
			return;

		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var lastList:Array<String> = Difficulty.list;
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
			
		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
			// 添加初始窗口标题栏颜色设置
			#if windows
			var colorArray = [
				(intendedColor >> 16) & 0xFF, // R
				(intendedColor >> 8) & 0xFF, // G
				intendedColor & 0xFF // B
			];
			WindowColorMode.setWindowBorderColor(colorArray, true, false);
			//WindowColorMode.redrawWindowHeader();
			#end
		}

		// selector.y = (70 * curSelected) + 30;

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			bullShit++;
			item.alpha = 0.6;
			if (item.targetY == curSelected)
				item.alpha = 1;
		}
		
		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !lastList.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
	}

	inline private function _updateSongLastDifficulty()
	{
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			var icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}
		var totalSongs:Int = songs.length;
		if (totalSongs > 0 && !isDraggingScrollBar) { // 拖动时跳过自动更新
			var thumbHeight:Float = Math.max(20, Math.min(scrollBarBG.height * 0.5, scrollBarBG.height / totalSongs));
			scrollBarThumb.makeGraphic(12, Math.floor(thumbHeight), 0xFFFFFFFF);
			
			var maxScroll:Float = scrollBarBG.height - thumbHeight;
			var scrollPosition:Float = (lerpSelected / (totalSongs - 1)) * maxScroll;
			
			if (Math.abs(scrollBarThumb.y - (scrollBarBG.y + scrollPosition)) > 1) {
				FlxTween.cancelTweensOf(scrollBarThumb);
				FlxTween.tween(scrollBarThumb, {y: scrollBarBG.y + scrollPosition}, 0.2, {ease: FlxEase.quadOut});
			}
		}
	
	}

	override function destroy():Void
	{
		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}	
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}