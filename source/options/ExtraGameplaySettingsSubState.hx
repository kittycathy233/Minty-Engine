package options;

class ExtraGameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Extra Options\nWTF, silly Chinese Option\n\nNot Done';
		rpcTitle = 'Extra Gameplay Settings Menu'; //for Discord Rich Presence

		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('show Game Version', //Name
		"在FPS Counter的位置附加显示当前版本", //Description
		'exgameversion',
		'bool');
		addOption(option);

		var option:Option = new Option('Focus Game', //Name
		"当游戏未处于焦点时会暂停", //Description
		'autoPause',
		'bool');
		addOption(option);

		var option:Option = new Option('Show Extra-Rating',
		"显示额外的rating\n文件名（例子）: sick-extra.png\n别在pixel场景启用它，因为大喵没有做，除非你有类似贴图",
		'exratingDisplay',
		'bool');
		addOption(option);

		var option:Option = new Option('Rating Bounce',
		"加强评分图标的跳动效果\n注：此选项存在较多bug，建议禁用",
		'ratbounce',
		'bool');
		addOption(option);

		var option:Option = new Option('Extra-Rating Bounce',
		"加强扩展评分图标的跳动效果\n当然同上，这个选项也存在一些bug",
		'exratbounce',
		'bool');
		addOption(option);

		var option:Option = new Option('Remove Perfect! Note Judgement',
		"如名，移除“Perfect！”评级\n同时扩展评级贴图也会改变",
		'rmperfect',
		'bool');
		addOption(option);

		var option:Option = new Option('Ratings Opacity',
			'修改评级贴图的不透明度，100%为不修改.',
			'ratingsAlpha',
			'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('HealthBar Style',
		Language.get("healthbar_style_desc"),
		'healthbarstyle',
		'string',
		['Psych', 'OS', 'Kade']);
		addOption(option);


		var option:Option = new Option('IconBop Style',
		Language.get("iconbop_style_desc"),
		'iconbopstyle',
		'string',
		['Psych', 'OS', 'MintRhythm', 'Kade', 'NONE']);
		addOption(option);

		var option:Option = new Option('ScoreTxt Style',
		Language.get("scoretxt_style_desc"),
		'scoretxtstyle',
		'string',
		['Psych', 'OS', 'MintRhythm', 'Kade']);
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

		var option:Option = new Option('Blue Archive MENU',
		Language.get("bamenu_desc"),
		'BAMenu',
		'bool');
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
		};        addOption(option);

		super();
	}

	function onChangeHitsoundVolume()
		FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);

	function onChangeAutoPause()
		FlxG.autoPause = ClientPrefs.data.autoPause;
}