package options;

import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;

class ExtraGameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Extra Options\nWTF, silly Options\n\nNot Done';
		rpcTitle = 'Extra Gameplay Settings Menu'; //for Discord Rich Presence

		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('show Game Version', //Name
		Language.get("show_version_desc"),
		'exgameversion',
		'bool');
		addOption(option);

		var option:Option = new Option('Focus Game', //Name
		Language.get("focus_game_desc"),
		'autoPause',
		'bool');
		addOption(option);

		var option:Option = new Option('Show Extra-Rating',
		Language.get("show_exrating_desc"),
		'exratingDisplay',
		'bool');
		addOption(option);

		var option:Option = new Option('Rating Bounce',
		Language.get("rating_bounce_desc"),
		'ratbounce',
		'bool');
		addOption(option);

		var option:Option = new Option('Extra-Rating Bounce',
		Language.get("exrating_bounce_desc"),
		'exratbounce',
		'bool');
		addOption(option);

		var option:Option = new Option('Remove Perfect! Note Judgement',
		Language.get("rm_perfect_judge_desc"),
		'rmperfect',
		'bool');
		addOption(option);

		option = new Option('Score Incrase When BotPlay',
			Language.get("bot_addscore_desc"),
			'botplayScore',
			'bool');
		addOption(option);

		option = new Option('Show "Combo" Sprite',
			Language.get("gameplay_combospr_desc"),
			'comboSprDisplay',
			'bool');
		addOption(option);

		option = new Option('Show Event Information',
			Language.get("events_debug_desc"),
			'eventDebug',
			'bool');
		addOption(option);

		var option:Option = new Option('Ratings Opacity',
			Language.get("rating_opac_desc"),
			'ratingsAlpha',
			'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

				option = new Option('HUD Zoom Speed',
			Language.get("hud_zoomstyle_desc"),
			'hudZoomStyle',
			'string',
			['default', 'Fast', 'Slow', 'Kade']);
		addOption(option);

		option = new Option('HUD Zoom',
			Language.get("camhud_zoom_desc"),
			'hudSize',
			'float');
		option.displayFormat = '%v X';
		option.scrollSpeed = 1;
		option.minValue = 0.5;
		option.maxValue = 1.2;
		option.changeValue = 0.005;
		option.decimals = 3; //小数点后三位
		addOption(option);

		var option:Option = new Option('HealthBar Style',
		Language.get("healthbar_style_desc"),
		'healthbarstyle',
		'string',
		['Psych', 'OS', 'Kade']);
		addOption(option);


		option = new Option('IconBop Style',
			Language.get("iconbop_style_desc"),
			'iconbopstyle',
			'string',
			['Psych', 'OS', 'MintRhythm', 'Leather', 'SB', 'Vanilla', 'VSlice(New)', 'VSlice(Old)', 'Codename', 'Dave', 'NovaFlare', 'NONE']);
		addOption(option);

		option = new Option('ScoreTxt Style',
			Language.get("scoretxt_style_desc"),
			'scoretxtstyle',
			'string',
			['Psych', 'OS', 'MintRhythm', 'Kade', 'V-Slice']);
		addOption(option);

		var option:Option = new Option('Remove the "ms" offset',
		Language.get("rm_ms_offset_desc"),
		'rmmsTimeTxt',
		'bool');
		addOption(option);

		var option:Option = new Option('ScoreTxt bounce',
		Language.get("scoretxt_bounce_desc"),
		'scoretxtbounce',
		'bool');
		addOption(option);

		var option:Option = new Option('Loading Style',
		Language.get("loading_style_desc"),
		'customFadeStyle',
		'string',
		['Vanilla', 'NovaFlare Move', 'NovaFlare Alpha', 'MintRhythm']);
		addOption(option);

		/*var option:Option = new Option('Blue Archive MENU',
		Language.get("bamenu_desc"),
		'BAMenu',
		'bool');
		addOption(option);*/

		var option:Option = new Option('Single Note Splash Anim',
		Language.get("single_splashanim_desc"),
		'forceSingleSplashAnim',
		'bool');
		addOption(option);

		var option:Option = new Option('Vslice Anim',
		Language.get("vslice_animtest_desc"),
		'vsliceAnim',
		'bool');
		addOption(option);

		var option:Option = new Option('smooth HP Bar',
		Language.get("smooth_hpbar_desc"),
		'smoothHP',
		'bool');
		addOption(option);

		var option:Option = new Option('INF HP',
		Language.get("infhp_desc"),
		//'开启后血量上限无限，但超过2时会缓慢降低至2',
		'infHealth',
		'bool');
		addOption(option);

		/*var option:Option = new Option('Volume Style',
		//Language.get("loading_style_desc"),
		'（施工中）更改音量条主题',
		'volumeTheme',
		'string',
		['Vanilla', 'Psych', 'Archive']);
		addOption(option);*/

		var option:Option = new Option('TimeBar Style',
		Language.get("timebar_style_desc"),
		'timebarStyle',
		'string',
		['default', 'Kade']);
		addOption(option);

		var option:Option = new Option('CPU Strums',
		Language.get("cpu_strums_desc"),
		'cpuStrums',
		'bool');
		addOption(option);

		var option:Option = new Option('BotPlayTxt Style',
		Language.get("botplaytxt_style_desc"),
		'botplayStyle',
		'string',
		['Kade', 'Psych']);
		addOption(option);
		var option:Option = new Option('ShowCase Style',
		Language.get("showcase_style_desc"),
		'showcaseStyle',
		'string',
		['Kade', 'Psych']);
		addOption(option);

// ExtraGameplaySettingsSubState.hx 修改选项声明
var option:Option = new Option('FPS-Txt Style',
			Language.get("fpstxt_style_desc"),
	'fpstxtStyle',
	'string',
	['default', 'Kade']);
option.onChange = function() {
	if (Main.fpsVar != null) {
		Main.fpsVar.updateText(); // 强制刷新文本格式
	}
};
addOption(option);

		var option = new Option(
            "Engine Language",
			Language.get("change_language_desc"),
            'language',
            'string',
            ["en_us", "zh_cn", "zh_tw"]
        );
		option.onChange = function() {
			ClientPrefs.saveSettings(); // 保存设置
			Language.load();            // 立即重载语言
			refreshAllTexts();          // 自定义方法刷新界面文本
		};
		addOption(option);

		super();
	}

	function onChangeHitsoundVolume()
		FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);

	function onChangeAutoPause()
		FlxG.autoPause = ClientPrefs.data.autoPause;
}