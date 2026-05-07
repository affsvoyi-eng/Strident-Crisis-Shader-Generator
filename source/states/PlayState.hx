package states;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIGroup;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.net.FileFilter;
import openfl.display.Loader;
import openfl.display.Bitmap;
import openfl.Lib;

import lime.app.Application;
import lime.ui.Window;

import shader.Shaders.WiggleEffect;
import states.ReConfigState;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

class PlayState extends FlxState
{
    var bg:FlxSprite;
    var shader:WiggleEffect;
    var fileRef:FileReference;

    var ampText:FlxText;
    var freqText:FlxText;
    var speedText:FlxText;
    var brightText:FlxText;
    var timeText:FlxText;
    var versionText:FlxText;
    var toggleText:FlxText;

    var waveAmplitude:Float = 0.1;
    var frequency:Float = 5.0;
    var speed:Float = 2.0;
    var brightness:Float = 1.0;

    var brightnessOverlay:FlxSprite;

    var tabMenu:FlxUITabMenu;
    var uiVisible:Bool = true;

    var defaultImage:String = "assets/images/bg/cheeseburger.png";
    var currentVersion:String = "0.1.0";

    override public function create():Void
    {
        super.create();

        loadSettings();

        bg = new FlxSprite();
        bg.loadGraphic(defaultImage);
        fitImageToScreen();
        add(bg);

        shader = new WiggleEffect();
        shader.uTime.value = [0.0];
        shader.uSpeed.value = [speed];
        shader.uFrequency.value = [frequency];
        shader.uWaveAmplitude.value = [waveAmplitude];

        bg.shader = shader;

        brightnessOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        brightnessOverlay.scrollFactor.set();
        add(brightnessOverlay);

        versionText = new FlxText(20, FlxG.height - 50, 500, "Version: " + currentVersion);
        add(versionText);

        timeText = new FlxText(20, 410, 400, "Time: 0");
        add(timeText);

        toggleText = new FlxText(20, FlxG.height - 30, 500, "Press SPACE to toggle UI");
        add(toggleText);

        createTabMenu();
        add(tabMenu);

        updateBrightness();
    }

    function createTabMenu():Void
    {
        // -------- WIGGLE TAB --------
        var wiggleGroup = new FlxUIGroup();
        wiggleGroup.name = "Wiggle";

        ampText = new FlxText(10, 10, 380, "Wave Amplitude: " + waveAmplitude);
        wiggleGroup.add(ampText);

        freqText = new FlxText(10, 80, 380, "Frequency: " + frequency);
        wiggleGroup.add(freqText);

        speedText = new FlxText(10, 150, 380, "Speed: " + speed);
        wiggleGroup.add(speedText);

        // -------- BRIGHTNESS TAB --------
        var brightnessGroup = new FlxUIGroup();
        brightnessGroup.name = "Brightness";

        brightText = new FlxText(10, 10, 380, "Brightness: " + brightness);
        brightnessGroup.add(brightText);

        var actionsGroup = new FlxUIGroup();
        actionsGroup.name = "Actions";

        var loadBtn = new FlxButton(10, 10, "Add Image", function() loadImage());
        actionsGroup.add(loadBtn);

        var resetBtn = new FlxButton(10, 50, "Reset", function() resetDefaults());
        actionsGroup.add(resetBtn);

        var configBtn = new FlxButton(10, 90, "Config", function()
        {
            FlxG.switchState(new ReConfigState());
        });
        actionsGroup.add(configBtn);

        var exitBtn = new FlxButton(10, 130, "Exit", function() closeGame());
        actionsGroup.add(exitBtn);

        // -------- FIX DO TAB MENU --------
        var tabs = [
            { name: "wiggle", label: "Wiggle", content: wiggleGroup },
            { name: "brightness", label: "Brightness", content: brightnessGroup },
            { name: "actions", label: "Actions", content: actionsGroup }
        ];

        tabMenu = new FlxUITabMenu(null, tabs, true);
        tabMenu.resize(400, 300);
        tabMenu.x = 20;
        tabMenu.y = 20;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        shader.uTime.value[0] += elapsed;

        timeText.text = "Time: " + Std.string(Std.int(shader.uTime.value[0] * 100) / 100);

        if (FlxG.keys.justPressed.SPACE)
        {
            uiVisible = !uiVisible;
            tabMenu.visible = uiVisible;
            versionText.visible = uiVisible;
            timeText.visible = uiVisible;
            toggleText.visible = uiVisible;
        }
    }

    function updateBrightness():Void
    {
        brightnessOverlay.alpha = 1 - brightness;
        if (brightText != null)
            brightText.text = "Brightness: " + brightness;
    }

    function resetDefaults():Void
    {
        waveAmplitude = 0.1;
        frequency = 5;
        speed = 2;
        brightness = 1;

        updateBrightness();
    }

    function loadSettings():Void
    {
        if (FlxG.save.data.waveAmplitude != null)
            waveAmplitude = FlxG.save.data.waveAmplitude;

        if (FlxG.save.data.frequency != null)
            frequency = FlxG.save.data.frequency;

        if (FlxG.save.data.speed != null)
            speed = FlxG.save.data.speed;
    }

    function fitImageToScreen():Void
    {
        if (bg == null) return;

        var scaleX = FlxG.width / bg.width;
        var scaleY = FlxG.height / bg.height;

        var finalScale = Math.max(scaleX, scaleY);

        bg.scale.set(finalScale, finalScale);
        bg.updateHitbox();
        bg.screenCenter();
    }

    function closeGame():Void
    {
        #if desktop
        var window:Window = Application.current.window;
        var startY:Float = window.y;

        FlxTween.tween(window, {y: startY - 20}, 0.15, {
            ease: FlxEase.quadOut,
            onComplete: function(_) {
                FlxTween.tween(window, {y: startY + 400}, 0.4, {
                    ease: FlxEase.quadIn,
                    onComplete: function(_) {
                        #if sys
                        Sys.exit(0);
                        #else
                        Lib.close();
                        #end
                    }
                });
            }
        });
        #end
    }

    function loadImage():Void
    {
        fileRef = new FileReference();
        fileRef.addEventListener(Event.SELECT, function(_)
        {
            fileRef.addEventListener(Event.COMPLETE, onFileLoaded);
            fileRef.load();
        });

        fileRef.browse([new FileFilter("Images", "*.png;*.jpg;*.jpeg")]);
    }

    function onFileLoaded(e:Event):Void
    {
        var loader = new Loader();

        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(_)
        {
            var bmp:Bitmap = cast loader.content;
            bg.loadGraphic(bmp.bitmapData);
            fitImageToScreen();
            bg.shader = shader;
        });

        loader.loadBytes(fileRef.data);
    }
}
