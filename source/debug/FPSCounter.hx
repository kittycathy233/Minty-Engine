package debug;

import states.MainMenuState;
import flixel.FlxG;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;

class FPSCounter extends Sprite
{
    // FPS 相关
    public var currentFPS(default, null):Int;
    public var memoryMegas(get, never):Float;
    public var memoryPeakMegas(get, never):Float;
    private var memoryPeak:Float = 0;
    @:noCompletion private var times:Array<Float>;

    // 抖动效果相关
    private var shakeTime:Float = 0;
    private var shakeStrength:Float = 0;
    private var baseX:Float = 10;
    private var baseY:Float = 10;

    // UI 元素
    private var bg:Shape;
    private var tfFPS:TextField;
    private var tfMem:TextField;
    private var tfPeak:TextField;
    private var tfVersion:TextField;
    private var tfDelay:TextField; // 新增延迟文本

    // 尺寸插值相关
    private var targetWidth:Float = 0;
    private var targetHeight:Float = 0;
    private var currentWidth:Float = 0;
    private var currentHeight:Float = 0;
    private static final SIZE_LERP_FACTOR:Float = 0.2; // 尺寸插值速度 (0-1)
    private static final SIZE_CHANGE_THRESHOLD:Float = 0.4; // 尺寸变化阈值(像素)

    // 布局常量
    private static final BASE_SIZE:Int = 16;
    private static final VERSION_SIZE:Int = 14;
    private static final ROW_HEIGHT:Int = 18;
    private static final VERSION_SPACING:Int = 4;
    private static final PADDING:Int = 10;
    private static final BG_CORNER:Int = 12;
    private static final BG_ALPHA:Float = 0.45;
    private static final BG_BORDER_ALPHA:Float = 0.5;

    private var currentDelay:Float = 0; // 当前延迟（ms）
    private var delayUpdateTimer:Float = 0; // 延迟刷新计时器
    private static final DELAY_UPDATE_INTERVAL:Float = 0.2; // 延迟刷新间隔（秒）

    public function new(x:Float = 10, y:Float = 10, color:Int = 0x00FF00)
    {
        super();

        this.baseX = x;
        this.baseY = y;
        this.x = x;
        this.y = y;

        currentFPS = 0;
        times = [];

        // 初始化背景
        bg = new Shape();
        addChild(bg);

        // 创建文本字段
        var monoFont = getFontName();
        tfFPS = createField(PADDING, PADDING, BASE_SIZE, monoFont);
        tfDelay = createField(PADDING, PADDING + ROW_HEIGHT, BASE_SIZE, monoFont); // 新增延迟文本
        tfMem = createField(PADDING, PADDING + ROW_HEIGHT * 2, BASE_SIZE, monoFont);
        tfPeak = createField(PADDING, PADDING + ROW_HEIGHT * 3, BASE_SIZE, monoFont);
        tfVersion = createField(PADDING, PADDING + ROW_HEIGHT * 4 + VERSION_SPACING, VERSION_SIZE, monoFont);
        
        // 版本信息特殊设置
        tfVersion.multiline = true;
        tfVersion.wordWrap = true;
        tfVersion.width = 230; // 初始宽度，会被动态调整
        
        addChild(tfFPS);
        addChild(tfDelay); // 新增
        addChild(tfMem);
        addChild(tfPeak);
        addChild(tfVersion);

        // 初始绘制
        updateText();
    }

    private function createField(px:Float, py:Float, size:Int, font:String):TextField {
        var tf = new TextField();
        tf.defaultTextFormat = new TextFormat(font, size, 0xFFFFFF, size == BASE_SIZE);
        tf.x = px;
        tf.y = py;
        tf.selectable = false;
        tf.mouseEnabled = false;
        tf.autoSize = LEFT;
        return tf;
    }

    private function getFontName():String {
        return (ClientPrefs.data.fpstxtStyle == 'Kade') ? 
            openfl.utils.Assets.getFont("assets/fonts/vcr.ttf").fontName : 
            "_typewriter";
    }

    var deltaTimeout:Float = 0.0;

    private override function __enterFrame(deltaTime:Float):Void
    {
        if (deltaTimeout > 1000) {
            deltaTimeout = 0.0;
            return;
        }

        // FPS 计算
        final now:Float = haxe.Timer.stamp() * 1000;
        times.push(now);
        while (times[0] < now - 1000) times.shift();

        currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;

        // 延迟刷新逻辑
        delayUpdateTimer += deltaTime / 1000;
        if (delayUpdateTimer >= DELAY_UPDATE_INTERVAL) {
            delayUpdateTimer = 0;
            if (currentFPS > 0)
                currentDelay = Math.fround(1000.0 / currentFPS * 10) / 10; // 保留一位小数
            else
                currentDelay = 0;
        }

        updateText();
        deltaTimeout += deltaTime;

        // 抖动效果
        if (currentFPS < FlxG.drawFramerate * 0.8) {
            shakeTime = 0.12;
            shakeStrength = 0.8 + (FlxG.drawFramerate * 0.8 - currentFPS) * 0.03;
        }
        if (shakeTime > 0) {
            shakeTime -= deltaTime / 1000;
            this.x = baseX + (Math.random() - 0.5) * shakeStrength * 2;
            this.y = baseY + (Math.random() - 0.5) * shakeStrength * 2;
        } else {
            // 平滑回位
            this.x += (baseX - this.x) * 0.25;
            this.y += (baseY - this.y) * 0.25;
            if (Math.abs(this.x - baseX) < 0.1) this.x = baseX;
            if (Math.abs(this.y - baseY) < 0.1) this.y = baseY;
        }

        // 尺寸插值
        var widthChanged = Math.abs(targetWidth - currentWidth) > SIZE_CHANGE_THRESHOLD;
        var heightChanged = Math.abs(targetHeight - currentHeight) > SIZE_CHANGE_THRESHOLD;
        
        if (widthChanged || heightChanged) {
            currentWidth += (targetWidth - currentWidth) * SIZE_LERP_FACTOR;
            currentHeight += (targetHeight - currentHeight) * SIZE_LERP_FACTOR;
            
            // 接近目标值时直接设为准确值
            if (Math.abs(targetWidth - currentWidth) < SIZE_CHANGE_THRESHOLD) currentWidth = targetWidth;
            if (Math.abs(targetHeight - currentHeight) < SIZE_CHANGE_THRESHOLD) currentHeight = targetHeight;
            
            drawBackground();
        }
    }

    public dynamic function updateText():Void {
        if (memoryMegas > memoryPeak) memoryPeak = memoryMegas;

        // FPS 颜色渐变
        var percent:Float = currentFPS / FlxG.drawFramerate;
        var fpsColor:Int;
        if (percent >= 1) {
            fpsColor = 0x00FF00; // 绿色
        } else if (percent >= 0.8) {
            fpsColor = lerpColor(0xFFFF00, 0x00FF00, (percent - 0.8) / 0.2);
        } else if (percent >= 0.5) {
            fpsColor = lerpColor(0xFF0000, 0xFFFF00, (percent - 0.5) / 0.3);
        } else {
            fpsColor = 0xFF0000; // 红色
        }

        // 更新文本
        tfFPS.defaultTextFormat = new TextFormat(getFontName(), BASE_SIZE, fpsColor, true);
        tfFPS.text = 'FPS:   ${currentFPS} / ${FlxG.drawFramerate}';

        tfDelay.defaultTextFormat = new TextFormat(getFontName(), BASE_SIZE, 0xFFD700, true);
        tfDelay.text = 'Delay: ${currentDelay} ms';

        tfMem.defaultTextFormat = new TextFormat(getFontName(), BASE_SIZE, 0x00BFFF, true);
        tfMem.text = 'Memory:   ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)}';

        tfPeak.defaultTextFormat = new TextFormat(getFontName(), BASE_SIZE, 0xFFA500, true);
        tfPeak.text = 'MEM Peak: ${flixel.util.FlxStringUtil.formatBytes(memoryPeak)}';

        // 版本信息
        tfVersion.visible = ClientPrefs.data.exgameversion;
        if (tfVersion.visible) {
            tfVersion.defaultTextFormat = new TextFormat(getFontName(), VERSION_SIZE, 0xCCCCCC, false);
            tfVersion.text = 'MintRhythm v${MainMenuState.mintrhythmEngineVersion}\nExtraKeys v${MainMenuState.extraKeysVersion}\nPsych Engine v${MainMenuState.psychEngineVersion}';
        }

        // 计算目标尺寸
        var bgHeight = PADDING * 2 + ROW_HEIGHT * 4; // 行数+1
        if (tfVersion.visible) {
            bgHeight += VERSION_SPACING + Std.int(tfVersion.textHeight);
        }

        var maxTextWidth = tfFPS.textWidth;
        if (tfDelay.textWidth > maxTextWidth) maxTextWidth = tfDelay.textWidth;
        if (tfMem.textWidth > maxTextWidth) maxTextWidth = tfMem.textWidth;
        if (tfPeak.textWidth > maxTextWidth) maxTextWidth = tfPeak.textWidth;
        if (tfVersion.visible && tfVersion.textWidth > maxTextWidth) maxTextWidth = tfVersion.textWidth;
        
        targetWidth = Std.int(maxTextWidth) + PADDING * 2 + 4;
        targetHeight = bgHeight;

        // 更新各文本位置
        tfFPS.x = tfDelay.x = tfMem.x = tfPeak.x = PADDING;
        tfFPS.y = PADDING;
        tfDelay.y = PADDING + ROW_HEIGHT;
        tfMem.y = PADDING + ROW_HEIGHT * 2;
        tfPeak.y = PADDING + ROW_HEIGHT * 3;

        if (tfVersion.visible) {
            tfVersion.width = targetWidth - PADDING * 2;
            tfVersion.y = PADDING + ROW_HEIGHT * 4 + VERSION_SPACING;
        }

        // 初始绘制或尺寸无变化时立即更新
        if (currentWidth == 0 || currentHeight == 0 || 
            (Math.abs(targetWidth - currentWidth) < SIZE_CHANGE_THRESHOLD && 
             Math.abs(targetHeight - currentHeight) < SIZE_CHANGE_THRESHOLD)) {
            currentWidth = targetWidth;
            currentHeight = targetHeight;
            drawBackground();
        }
    }

    private function drawBackground():Void {
        bg.graphics.clear();
        bg.graphics.beginFill(0x000000, BG_ALPHA);
        bg.graphics.lineStyle(2, 0xFFFFFF, BG_BORDER_ALPHA);
        bg.graphics.drawRoundRect(0, 0, currentWidth, currentHeight, BG_CORNER, BG_CORNER);
        bg.graphics.endFill();
    }

    private static function lerpColor(from:Int, to:Int, t:Float):Int {
        t = Math.max(0, Math.min(1, t));
        var fr = (from >> 16) & 0xFF, fg = (from >> 8) & 0xFF, fb = from & 0xFF;
        var tr = (to >> 16) & 0xFF, tg = (to >> 8) & 0xFF, tb = to & 0xFF;
        var r = Std.int(fr + (tr - fr) * t);
        var g = Std.int(fg + (tg - fg) * t);
        var b = Std.int(fb + (tb - fb) * t);
        return (r << 16) | (g << 8) | b;
    }

    inline function get_memoryMegas():Float
        return cast(System.totalMemory, UInt);
        
    inline function get_memoryPeakMegas():Float
        return memoryPeak;
}