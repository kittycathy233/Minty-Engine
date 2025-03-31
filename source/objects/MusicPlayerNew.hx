// MusicPlayerNew.hx
package objects;

import flixel.group.FlxGroup;
import flixel.ui.FlxBar;
import flixel.util.FlxStringUtil;
import flixel.math.FlxMath;
import states.FreeplayStateNew;

/**
 * 新版顶部风格音乐播放器（优化版）
 */
@:access(states.FreeplayStateNew)
class MusicPlayerNew extends FlxGroup 
{
    public var instance:FreeplayStateNew;

    public var playing(get, never):Bool;
    public var paused(get, never):Bool;

    public var playingMusic:Bool = false;
    public var curTime:Float = 0;

    // UI 元素
    var topBar:FlxSprite;
    var songTitle:FlxText;
    var progressBar:FlxBar;
    var currentTimeText:FlxText;
    var totalTimeText:FlxText;
    var playPauseIcon:FlxSprite;
    var speedIndicator:FlxText;
    var progressBack:FlxSprite;

    public var playbackRate(get, set):Float;
    
    // 私有变量
    var _playbackRate:Float = 1;
    var wasPlaying:Bool = false;
    var holdPitchTime:Float = 0;

    public function new(instance:FreeplayStateNew)
    {
        super();
        this.instance = instance;
        createUI();
        switchPlayMusic();
    }

    function createUI()
    {
        // 顶部背景（半透明黑底，高度60）
        topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 60, 0xAA000000);
        topBar.alpha = 0.95;
        topBar.antialiasing = true;
        add(topBar);

        // 歌曲标题（顶部居中）
        songTitle = new FlxText(20, 8, FlxG.width - 40, "", 20);
        songTitle.setFormat(Paths.font(Language.get("game_font")), 20, FlxColor.WHITE, CENTER, 
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(songTitle);

        // 进度条背景
        progressBack = new FlxSprite(20, 38).makeGraphic(FlxG.width - 40, 6, 0x55444444);
        progressBack.antialiasing = true;
        add(progressBack);

        // 进度条（动态渐变）
        progressBar = new FlxBar(20, 38, LEFT_TO_RIGHT, FlxG.width - 40, 6);
        progressBar.createGradientBar([0x00000000], [0xFF4CAF50, 0xFF8BC34A], 1, 90, true, 0x00000000);
        progressBar.numDivisions = 1000;
        progressBar.antialiasing = true;
        add(progressBar);

        // 时间显示（左右分开）
        // 修改时间显示变量的定义（原timeDisplay拆分为两个）
        currentTimeText = new FlxText(20, 48, 100, "0:00", 14);
        currentTimeText.setFormat(Paths.font(Language.get("game_font")), 14, 0xFFCCCCCC);
        add(currentTimeText);

        totalTimeText = new FlxText(FlxG.width - 120, 48, 100, "0:00", 14);
        totalTimeText.setFormat(Paths.font(Language.get("game_font")), 14, 0xFFCCCCCC, RIGHT);
        add(totalTimeText);

        // 播放控制图标
        playPauseIcon = new FlxSprite(FlxG.width - 50, 15);
        playPauseIcon.frames = Paths.getSparrowAtlas('music_controls');
        playPauseIcon.animation.addByPrefix('play', 'play', 24);
        playPauseIcon.animation.addByPrefix('pause', 'pause', 24);
        playPauseIcon.animation.play('play');
        playPauseIcon.scale.set(0.8, 0.8);
        playPauseIcon.updateHitbox();
        add(playPauseIcon);

        // 速度指示器
        speedIndicator = new FlxText(FlxG.width - 110, 20, 80, "1.00x", 16);
        speedIndicator.setFormat(Paths.font(Language.get("game_font")), 16, 0xFF00FFFF, RIGHT);
        add(speedIndicator);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if (!playingMusic) return;

        handleControls(elapsed);
        updateProgress();
        syncVocals();
    }

    function handleControls(elapsed:Float)
    {
        // 基本控制
        if (instance.controls.UI_LEFT_P) seek(-5000);
        if (instance.controls.UI_RIGHT_P) seek(5000);
        if (instance.controls.UI_UP_P) adjustSpeed(0.05);
        if (instance.controls.UI_DOWN_P) adjustSpeed(-0.05);
        if (instance.controls.RESET) resetPlayback();

        // 持续快进/快退
        if (instance.controls.UI_LEFT || instance.controls.UI_RIGHT) {
            instance.holdTime += elapsed;
            if (instance.holdTime > 0.5) {
                var speed = 40000 * (instance.controls.UI_LEFT ? -1 : 1);
                seek(Std.int(speed * elapsed));
            }
        }
    }

    function updateProgress()
    {
        // 平滑进度条（使用缓动函数）
        var target = FlxG.sound.music.time;
        progressBar.value = FlxMath.lerp(progressBar.value, target, 0.25);

        // 时间显示
        // 修复时间显示变量名
        currentTimeText.text = formatTime(progressBar.value / 1000);
        totalTimeText.text = formatTime(FlxG.sound.music.length / 1000);
    }

    function formatTime(seconds:Float):String
    {
        var minutes = Math.floor(seconds / 60);
        var seconds = Std.int(seconds % 60);
        return '$minutes:' + (seconds < 10 ? '0$seconds' : '$seconds');
    }

    function seek(ms:Int)
    {
        curTime = FlxMath.bound(curTime + ms, 0, FlxG.sound.music.length);
        FlxG.sound.music.time = curTime;
        if (FreeplayStateNew.vocals != null) FreeplayStateNew.vocals.time = curTime;
    }

    function adjustSpeed(change:Float)
        {
            // 修复playbackRate访问方式
            this._playbackRate = FlxMath.roundDecimal(this._playbackRate + change, 2);
            set_playbackRate(this._playbackRate); // 调用setter更新效果
        }

    function resetPlayback()
    {
        // 修复playbackRate访问方式
        this._playbackRate = 1;
        set_playbackRate(this._playbackRate); // 调用setter更新效果
        seek(-2147483648);
    }

    function updateDisplay()
        {
            // 更新进度条
            progressBar.setRange(0, FlxG.sound.music.length);
            progressBar.value = FlxG.sound.music.time;
    
            // 更新时间显示（使用拆分后的两个组件）
            var current = FlxStringUtil.formatTime(FlxG.sound.music.time / 1000, false);
            var total = FlxStringUtil.formatTime(FlxG.sound.music.length / 1000, false);
            currentTimeText.text = current;
            totalTimeText.text = total;
    
            // 更新速度显示
            speedIndicator.text = '${_playbackRate}x';
            speedIndicator.x = FlxG.width - speedIndicator.width - 20;
    
            // 更新播放图标
            playPauseIcon.animation.play(playing ? 'pause' : 'play');
        }

    public function togglePlayback()
    {
        if (playing) {
            FlxG.sound.music.pause();
            if (FreeplayStateNew.vocals != null) FreeplayStateNew.vocals.pause();
        } else {
            FlxG.sound.music.resume();
            if (FreeplayStateNew.vocals != null) FreeplayStateNew.vocals.resume();
        }
        updateDisplay();
    }

    function handleContinuousInput(elapsed:Float)
    {
        if (instance.controls.UI_LEFT || instance.controls.UI_RIGHT)
        {
            instance.holdTime += elapsed;
            if (instance.holdTime > 0.5)
            {
                var speed = 40000 * (instance.controls.UI_LEFT ? -1 : 1);
                seek(Std.int(speed * elapsed));
            }
        }
    }

    function syncVocals()
        {
            if (FreeplayStateNew.vocals != null && Math.abs(FlxG.sound.music.time - FreeplayStateNew.vocals.time) > 16) {
                FreeplayStateNew.vocals.time = FlxG.sound.music.time;
            }
        }
    
        public function switchPlayMusic()
        {
            visible = playingMusic;
            topBar.visible = playingMusic;
            
            if (playingMusic) {
                songTitle.text = '正在播放: ${instance.songs[FreeplayStateNew.curSelected].songName}';
                instance.bottomText.text = "空格: 播放/暂停 | ←/→: 快退/快进 | R: 重置速度 | ESC: 返回";
                progressBar.setRange(0, FlxG.sound.music.length);
            } else {
                instance.bottomText.text = instance.bottomString;
            }
        }
    
        // Getters/Setters
        function get_playing():Bool return FlxG.sound.music.playing;
        function get_paused():Bool return !playing;
        
        function get_playbackRate():Float {
            return _playbackRate;
        }
        
        function set_playbackRate(value:Float):Float {
            value = FlxMath.roundDecimal(value, 2);
            _playbackRate = FlxMath.bound(value, 0.5, 2.0);
            FlxG.sound.music.pitch = _playbackRate;
            if (FreeplayStateNew.vocals != null) FreeplayStateNew.vocals.pitch = _playbackRate;
            speedIndicator.text = '${_playbackRate}x';
            return _playbackRate;
        }
    }