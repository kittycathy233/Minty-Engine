// backend/ArchiveSoundTray.hx
package backend;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.system.ui.FlxSoundTray;
import flixel.util.FlxColor;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;

class ArchiveSoundTray extends FlxSoundTray
{
    private static final WIDTH:Int = 30;
    private static final HEIGHT:Int = 200;
    private static final PADDING:Int = 5;
    
    private var bg:Sprite;
    private var bar:Sprite;
    
    public function new()
    {
        super();
        removeChildren();
        
        // 背景
        bg = new Sprite();
        var bgGraphic = new BitmapData(WIDTH, HEIGHT, true, FlxColor.CYAN.withAlpha(0.5*255));
        bg.addChild(new Bitmap(bgGraphic));
        bg.x = FlxG.width - WIDTH - 10;
        bg.y = (FlxG.height - HEIGHT)/2;
        addChild(bg);
        
        // 进度条
        bar = new Sprite();
        bar.addChild(new Bitmap(new BitmapData(WIDTH - 2*PADDING, HEIGHT - 2*PADDING, true, FlxColor.BLUE)));
        bar.x = bg.x + PADDING;
        bar.y = bg.y + PADDING;
        addChild(bar);
        
        visible = false;
    }
    
    override public function update(MS:Float):Void
    {
        super.update(MS);
        
        // 更新进度条高度
        var volumeHeight = FlxMath.lerp(0, HEIGHT - 2*PADDING, FlxG.sound.volume);
        bar.scaleY = volumeHeight / (HEIGHT - 2*PADDING);
        bar.y = bg.y + PADDING + (HEIGHT - 2*PADDING - volumeHeight);
    }
    
    override public function show(up:Bool = false):Void
    {
        visible = true;
        _timer = 1;
        alpha = 1;
        
        // 播放默认声音反馈
        if (!silent) {
            var sound = up ? volumeUpSound : volumeDownSound;
            if (FlxG.sound.volume == 1.0) sound = volumeMaxSound;
            FlxG.sound.play(Paths.getSound('soundtray/$sound'));
        }
    }
}