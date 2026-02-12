package debug;

import flixel.FlxG;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;
import backend.ClientPrefs;

/**
 * 简化版FPS计数器，添加Update和Draw数量统计
 * 背景更简化，性能开销更小
 */
class SimpleFPSCounter extends Sprite
{
    // FPS 相关
    public var currentFPS(default, null):Int;
    private var times:Array<Float>;
    
    // Update 和 Draw 计数相关
    private var updateCount:Int = 0;
    private var drawCount:Int = 0;
    private var updateTimer:Float = 0;
    private var drawTimer:Float = 0;
    private var lastUpdateCount:Int = 0;
    private var lastDrawCount:Int = 0;
    
    // UI 元素
    var tfFPS:TextField;
    var tfUpdate:TextField;
    var tfDraw:TextField;
    var tfMem:TextField;
    
    // 布局常量
    private static final TEXT_SIZE:Int = 14;
    private static final ROW_HEIGHT:Int = 16;
    private static final PADDING:Int = 8;
    private static final BG_ALPHA:Float = 0.3;
    
    public var updating:Bool = true;

    public function new(x:Float = 10, y:Float = 10)
    {
        super();
        
        this.x = x;
        this.y = y;
        
        currentFPS = 0;
        times = [];
        
        // 创建文本字段
        createTextFields();
        updateText();
        
        // 监听Update和Draw事件
        FlxG.signals.postUpdate.add(onPostUpdate);
        FlxG.signals.postDraw.add(onPostDraw);
    }
    
    private function createTextFields():Void
    {
        var fontName = getFontName();
        
        tfFPS = createTextField("FPS", PADDING, PADDING, fontName);
        tfUpdate = createTextField("Update", PADDING, PADDING + ROW_HEIGHT, fontName);
        tfDraw = createTextField("Draw", PADDING, PADDING + ROW_HEIGHT * 2, fontName);
        tfMem = createTextField("Memory", PADDING, PADDING + ROW_HEIGHT * 3, fontName);
        
        addChild(tfFPS);
        addChild(tfUpdate);
        addChild(tfDraw);
        addChild(tfMem);
    }
    
    private function createTextField(label:String, x:Float, y:Float, fontName:String):TextField
    {
        var tf = new TextField();
        tf.defaultTextFormat = new TextFormat(fontName, TEXT_SIZE, 0xFFFFFF);
        tf.x = x;
        tf.y = y;
        tf.selectable = false;
        tf.mouseEnabled = false;
        tf.autoSize = LEFT;
        tf.text = label;
        return tf;
    }
    
    private function getFontName():String
    {
        return (ClientPrefs.data.fpstxtStyle == 'Kade') ? 
            openfl.utils.Assets.getFont("assets/fonts/vcr.ttf").fontName : 
            "_typewriter";
    }
    
    /**
     * Update 事件监听器
     */
    private function onPostUpdate():Void
    {
        updateCount++;
    }
    
    /**
     * Draw 事件监听器
     */
    private function onPostDraw():Void
    {
        drawCount++;
    }
    
    private override function __enterFrame(deltaTime:Float):Void
    {
        if (!updating) return;
        
        // FPS 计算
        final now:Float = haxe.Timer.stamp() * 1000;
        times.push(now);
        while (times[0] < now - 1000)
            times.shift();
        
        currentFPS = times.length;
        
        // Update 和 Draw 计数计算
        updateTimer += deltaTime / 1000;
        drawTimer += deltaTime / 1000;
        
        // 每秒更新一次Update和Draw计数
        if (updateTimer >= 1.0)
        {
            lastUpdateCount = updateCount;
            updateCount = 0;
            updateTimer = 0;
        }
        
        if (drawTimer >= 1.0)
        {
            lastDrawCount = drawCount;
            drawCount = 0;
            drawTimer = 0;
        }
        
        updateText();
    }
    
    public function updateText():Void
    {
        // 更新FPS显示
        var fpsPercent:Float = currentFPS / FlxG.drawFramerate;
        var fpsColor:Int = getFPSColor(fpsPercent);
        
        tfFPS.defaultTextFormat = new TextFormat(getFontName(), TEXT_SIZE, fpsColor);
        tfFPS.text = 'FPS: ${currentFPS} / ${FlxG.drawFramerate}';
        
        // 更新Update计数
        tfUpdate.defaultTextFormat = new TextFormat(getFontName(), TEXT_SIZE, 0x00FFAA);
        tfUpdate.text = 'Update: ${lastUpdateCount}/s';
        
        // 更新Draw计数
        tfDraw.defaultTextFormat = new TextFormat(getFontName(), TEXT_SIZE, 0xFFAA00);
        tfDraw.text = 'Draw: ${lastDrawCount}/s';
        
        // 更新内存使用
        var memoryBytes:Float = System.totalMemory;
        tfMem.defaultTextFormat = new TextFormat(getFontName(), TEXT_SIZE, 0x66CCFF);
        tfMem.text = 'Memory: ${formatBytes(memoryBytes)}';
        
        // 更新背景尺寸
        updateBackground();
    }
    
    private function getFPSColor(percent:Float):Int
    {
        if (percent >= 1) return 0x00FF00;      // 绿色：性能良好
        if (percent >= 0.8) return 0xFFFF00;    // 黄色：性能一般
        if (percent >= 0.5) return 0xFFA500;    // 橙色：性能较差
        return 0xFF0000;                         // 红色：性能很差
    }
    
    private function formatBytes(bytes:Float):String
    {
        if (bytes < 1024) return '${bytes} B';
        if (bytes < 1024 * 1024) return '${Math.round(bytes / 1024 * 10) / 10} KB';
        return '${Math.round(bytes / (1024 * 1024) * 10) / 10} MB';
    }
    
    private function updateBackground():Void
    {
        graphics.clear();
        
        // 计算文本区域大小
        var maxWidth:Float = 0;
        var fields = [tfFPS, tfUpdate, tfDraw, tfMem];
        
        for (field in fields)
        {
            if (field.textWidth > maxWidth) maxWidth = field.textWidth;
        }
        
        var bgWidth:Float = maxWidth + PADDING * 2;
        var bgHeight:Float = ROW_HEIGHT * fields.length + PADDING * 2;
        
        // 绘制半透明背景
        graphics.beginFill(0x000000, BG_ALPHA);
        graphics.drawRect(0, 0, bgWidth, bgHeight);
        graphics.endFill();
        
        // 绘制边框
        graphics.lineStyle(1, 0x666666, 0.5);
        graphics.drawRect(0, 0, bgWidth, bgHeight);
    }
    
    /**
     * 清理资源
     */
    public function destroy():Void
    {
        FlxG.signals.postUpdate.remove(onPostUpdate);
        FlxG.signals.postDraw.remove(onPostDraw);
        
        if (parent != null) parent.removeChild(this);
    }
}