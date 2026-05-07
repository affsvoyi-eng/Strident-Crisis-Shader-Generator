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
import openfl.events.UncaughtErrorEvent;
import openfl.net.FileFilter;
import openfl.display.Loader;
import openfl.display.Bitmap;
import openfl.Lib;

import lime.app.Application;
import lime.ui.Window;

import shader.Shaders;
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
    var timeText:FlxText;
    var versionText:FlxText;

    var waveAmplitude:Float = 0.1;
    var frequency:Float = 5.0;
    var speed:Float = 2.0;
    var brightness:Float = 1.0;

    var brightnessOverlay:FlxSprite;

    var uiVisible:Bool = true;
    var uiElements:Array<Dynamic> = [];

    var defaultImage:String = "assets/images/bg/cheeseburger.png";
    var currentVersion:String = "0.1.0";

    // =========================
    // TAB MENU (EXAMPLE UI)
    // =========================
    var tabMenu:FlxUITabMenu;
    var mainGroup:FlxUIGroup;
    var settingsGroup:FlxUIGroup;

    override public function create():Void
    {
        super.create();

        initCrashHandler();
        loadSettings();

        // =========================
        // BACKGROUND
        // =========================
        bg = new FlxSprite();
        bg.loadGraphic(defaultImage);
        fitImageToScreen();
        add(bg);

        // =========================
        // SHADER
        // =========================
        shader = new WiggleEffect();
        shader.uTime.value = [0.0];
        shader.uSpeed.value = [speed];
        shader.uFrequency.value = [frequency];
        shader.uWaveAmplitude.value = [waveAmplitude];

        bg.shader = shader;

        // =========================
        // DARK OVERLAY
        // =========================
        brightnessOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        brightnessOverlay.scrollFactor.set();
        add(brightnessOverlay);

        // =========================
        // TAB MENU UI
        // =========================
        var tabs = [
            {name: "main", label: "Main"},
            {name: "settings", label: "Settings"}
        ];

        tabMenu = new FlxUITabMenu(null, tabs, true);
        tabMenu.resize(320, 300);
        tabMenu.x = 20;
        tabMenu.y = 20;
        add(tabMenu);

        // =========================
        // MAIN TAB
        // =========================
        mainGroup = new FlxUIGroup();

        var addImageBtn = new FlxButton(20, 20, "Load Image", function()
        {
            playClick();
            loadImage();
        });

        var exitBtn = new FlxButton(20, 60, "Exit Game", function()
        {
            playClick();
            closeGame();
        });

        var resetBtn = new FlxButton(20, 100, "Reset Values", function()
        {
            playClick();
            resetDefaults();
        });

        mainGroup.add(addImageBtn);
        mainGroup.add(exitBtn);
        mainGroup.add(resetBtn);

        tabMenu.addGroup(mainGroup);

        // =========================
        // SETTINGS TAB (TEXT INFO)
        // =========================
        settingsGroup = new FlxUIGroup();

        ampText = new FlxText(20, 20, 300, "");
        freqText = new FlxText(20, 50, 300, "");
        speedText = new FlxText(20, 80, 300, "");
        timeText = new FlxText(20, 110, 300, "");

        settingsGroup.add(ampText);
        settingsGroup.add(freqText);
        settingsGroup.add(speedText);
        settingsGroup.add(timeText);

        tabMenu.addGroup(settingsGroup);

        // =========================
        // VERSION TEXT
        // =========================
        versionText = new FlxText(20, FlxG.height - 40, 400, "Version: " + currentVersion);
        add(versionText);

        updateShaderValues();
        updateBrightness();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        shader.uTime.value[0] += elapsed;

        timeText.text = "Time: " + Std.string(
            Std.int(shader.uTime.value[0] * 100) / 100
        );

        if (FlxG.keys.justPressed.SPACE)
        {
            uiVisible = !uiVisible;
            tabMenu.visible = uiVisible;
            tabMenu.active = uiVisible;
        }
    }

    // =========================
    // SHADER UPDATES
    // =========================
    function updateShaderValues():Void
    {
        shader.uWaveAmplitude.value = [waveAmplitude];
        shader.uFrequency.value = [frequency];
        shader.uSpeed.value = [speed];

        ampText.text = "Wave Amplitude: " + waveAmplitude;
        freqText.text = "Frequency: " + frequency;
        speedText.text = "Speed: " + speed;
    }

    function updateBrightness():Void
    {
        brightnessOverlay.alpha = 1 - brightness;
    }

    function resetDefaults():Void
    {
        waveAmplitude = 0.1;
        frequency = 5.0;
        speed = 2.0;
        brightness = 1.0;

        updateShaderValues();
        updateBrightness();
    }

    function playClick():Void
    {
        FlxG.sound.play("assets/sounds/click.ogg");
    }

    // =========================
    // EXIT ANIMATION FIXED
    // =========================
    function closeGame():Void
    {
        #if desktop
        var window:Window = Application.current.window;
        var startY:Float = window.y;

        FlxTween.tween(window, {
            y: startY - 20
        }, 0.15, {
            ease: FlxEase.quadOut,
            onComplete: function(_)
            {
                FlxTween.tween(window, {
                    y: startY + 400
                }, 0.4, {
                    ease: FlxEase.quadIn,
                    onComplete: function(_)
                    {
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

    // =========================
    // IMAGE FIT
    // =========================
    function fitImageToScreen():Void
    {
        var scaleX = FlxG.width / bg.width;
        var scaleY = FlxG.height / bg.height;
        var finalScale = Math.max(scaleX, scaleY);

        bg.scale.set(finalScale, finalScale);
        bg.updateHitbox();
        bg.screenCenter();
    }

    // =========================
    // IMAGE LOADER
    // =========================
    function loadImage():Void
    {
        fileRef = new FileReference();
        fileRef.addEventListener(Event.SELECT, onFileSelected);
        fileRef.browse([new FileFilter("Images", "*.png;*.jpg;*.jpeg")]);
    }

    function onFileSelected(e:Event):Void
    {
        fileRef.addEventListener(Event.COMPLETE, onFileLoaded);
        fileRef.load();
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

    // =========================
    // SETTINGS LOAD
    // =========================
    function loadSettings():Void
    {
        if (FlxG.save.data.waveAmplitude != null)
            waveAmplitude = FlxG.save.data.waveAmplitude;

        if (FlxG.save.data.frequency != null)
            frequency = FlxG.save.data.frequency;

        if (FlxG.save.data.speed != null)
            speed = FlxG.save.data.speed;
    }

    // =========================
    // CRASH HANDLER
    // =========================
    function initCrashHandler():Void
    {
        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
            UncaughtErrorEvent.UNCAUGHT_ERROR,
            function(e:UncaughtErrorEvent):Void
            {
                var errorMsg:String = Std.string(e.error);

                #if sys
                try
                {
                    if (!FileSystem.exists("crash"))
                        FileSystem.createDirectory("crash");

                    File.saveContent(
                        "crash/error_" + Date.now().getTime() + ".txt",
                        errorMsg
                    );
                }
                catch (e:Dynamic) {}
                #end

                FlxG.log.error(errorMsg);
            }
        );
    }
}
