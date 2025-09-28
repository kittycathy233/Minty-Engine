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

    public var charting:Bool = false; // 检测是否在制谱器

    // 抖动效果相关
    var shakeTime:Float = 0;
    var shakeStrength:Float = 0;
    public var baseX:Float = 10;
    public var baseY:Float = 10;

    // UI 元素
    var bg:Shape;
    var tfFPS:TextField;
    var tfMem:TextField;
    var tfPeak:TextField;
    var tfVersion:TextField;
    var tfDelay:TextField;

    // 尺寸插值相关
    private var targetWidth:Float = 0;
    private var targetHeight:Float = 0;
    private var currentWidth:Float = 0;
    private var currentHeight:Float = 0;
    private static final SIZE_LERP_FACTOR:Float = 0.2;
    private static final SIZE_CHANGE_THRESHOLD:Float = 0.4;

    // 布局常量
    private static final BASE_SIZE:Int = 16;
    private static final VERSION_SIZE:Int = 14;
    private static final ROW_HEIGHT:Int = 18;
    private static final VERSION_SPACING:Int = 4;
    private static final PADDING:Int = 10;
    private static final BG_CORNER:Int = 12;
    private static final BG_ALPHA:Float = 0.45;
    private static final BG_BORDER_ALPHA:Float = 0.5;

    private var currentDelay:Float = 0;
    private var delayUpdateTimer:Float = 0;
    private static final DELAY_UPDATE_INTERVAL:Float = 0.2;

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
        tfDelay = createField(PADDING, PADDING + ROW_HEIGHT, BASE_SIZE, monoFont);
        tfMem = createField(PADDING, PADDING + ROW_HEIGHT * 2, BASE_SIZE, monoFont);
        tfPeak = createField(PADDING, PADDING + ROW_HEIGHT * 3, BASE_SIZE, monoFont);
        tfVersion = createField(PADDING, PADDING + ROW_HEIGHT * 4 + VERSION_SPACING, VERSION_SIZE, monoFont);
        
        tfVersion.multiline = true;
        tfVersion.wordWrap = true;
        tfVersion.width = 230;
        
        addChild(tfFPS);
        addChild(tfDelay);
        addChild(tfMem);
        addChild(tfPeak);
        addChild(tfVersion);

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
                currentDelay = Math.fround(1000.0 / currentFPS * 10) / 10;
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
            
            if (Math.abs(targetWidth - currentWidth) < SIZE_CHANGE_THRESHOLD) currentWidth = targetWidth;
            if (Math.abs(targetHeight - currentHeight) < SIZE_CHANGE_THRESHOLD) currentHeight = targetHeight;
            
            drawBackground();
        }
    }

    public dynamic function updateText():Void {
        if (memoryMegas > memoryPeak) memoryPeak = memoryMegas;

        if (charting)
        {
            // 制谱器模式 - 只显示FPS和内存峰值
            tfFPS.defaultTextFormat = new TextFormat(getFontName(), BASE_SIZE, 0x90D0FF, true);
            tfFPS.text = 'FPS: ${currentFPS} / ${FlxG.drawFramerate}';
            
            tfPeak.defaultTextFormat = new TextFormat(getFontName(), BASE_SIZE, 0xF1A0FF, true);
            tfPeak.text = 'MEM: ${flixel.util.FlxStringUtil.formatBytes(memoryPeak)}';
            
            // 隐藏其他字段
            tfDelay.visible = false;
            tfMem.visible = false;
            tfVersion.visible = false;
            
            // 计算背景尺寸
            var bgHeight = PADDING * 2 + ROW_HEIGHT * 2;
            var maxTextWidth = Math.max(tfFPS.textWidth, tfPeak.textWidth);
            
            targetWidth = Std.int(maxTextWidth) + PADDING * 2 + 4;
            targetHeight = bgHeight;
            
            // 更新文本位置
            tfFPS.x = PADDING;
            tfFPS.y = PADDING;
            tfPeak.x = PADDING;
            tfPeak.y = PADDING + ROW_HEIGHT;
        }
        else
        {
            // 正常模式 - 显示所有信息
            var percent:Float = currentFPS / FlxG.drawFramerate;
            var fpsColor:Int;
            if (percent >= 1) {
                fpsColor = 0x00FF00;
            } else if (percent >= 0.8) {
                fpsColor = lerpColor(0xFFFF00, 0x00FF00, (percent - 0.8) / 0.2);
            } else if (percent >= 0.5) {
                fpsColor = lerpColor(0xFF0000, 0xFFFF00, (percent - 0.5) / 0.3);
            } else {
                fpsColor = 0xFF0000;
            }

            tfFPS.defaultTextFormat = new TextFormat(getFontName(), BASE_SIZE, fpsColor, true);
            tfFPS.text = 'FPS:   ${currentFPS} / ${FlxG.drawFramerate}';

            tfDelay.defaultTextFormat = new TextFormat(getFontName(), BASE_SIZE, 0xFFD700, true);
            tfDelay.text = 'Delay: ${currentDelay} ms';

            tfMem.defaultTextFormat = new TextFormat(getFontName(), BASE_SIZE, 0x00BFFF, true);
            tfMem.text = 'Memory:   ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)}';

            tfPeak.defaultTextFormat = new TextFormat(getFontName(), BASE_SIZE, 0xFFA500, true);
            tfPeak.text = 'MEM Peak: ${flixel.util.FlxStringUtil.formatBytes(memoryPeak)}';

            // 显示所有字段
            tfDelay.visible = true;
            tfMem.visible = true;
            
            // 版本信息
            tfVersion.visible = ClientPrefs.data.exgameversion;
            if (tfVersion.visible) {
                tfVersion.defaultTextFormat = new TextFormat(getFontName(), VERSION_SIZE, 0xCCCCCC, false);
                tfVersion.text = 'Minty Engine v${MainMenuState.mtEngineVersion}\nExtraKeys v${MainMenuState.extraKeysVersion}\nPsych Engine v${MainMenuState.psychEngineVersion}';
            }
            
            // 计算背景尺寸
            var bgHeight = PADDING * 2 + ROW_HEIGHT * 4;
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

            // 更新文本位置
            tfFPS.x = tfDelay.x = tfMem.x = tfPeak.x = PADDING;
            tfFPS.y = PADDING;
            tfDelay.y = PADDING + ROW_HEIGHT;
            tfMem.y = PADDING + ROW_HEIGHT * 2;
            tfPeak.y = PADDING + ROW_HEIGHT * 3;

            if (tfVersion.visible) {
                tfVersion.width = targetWidth - PADDING * 2;
                tfVersion.y = PADDING + ROW_HEIGHT * 4 + VERSION_SPACING;
            }
        }

        // 立即更新背景尺寸
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