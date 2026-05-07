package states;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

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

import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIGroup;

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

    var tabMenu:FlxUITabMenu;
    var mainGroup:FlxUIGroup;
    var shaderGroup:FlxUIGroup;
    var systemGroup:FlxUIGroup;

    override public function create():Void
    {
        super.create();

        initCrashHandler();
        loadSettings();

        // =====================
        // BACKGROUND
        // =====================
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

        // =====================
        // TAB MENU
        // =====================
        tabMenu = new FlxUITabMenu(null, [
            {name: "main", label: "Main"},
            {name: "shader", label: "Shader"},
            {name: "system", label: "System"}
        ], true);

        tabMenu.resize(380, 320);
        tabMenu.x = 10;
        tabMenu.y = 10;
        add(tabMenu);

        // =====================
        // MAIN TAB
        // =====================
        mainGroup = new FlxUIGroup();

        var loadBtn = new FlxButton(20, 20, "Add Image", function()
        {
            playClick();
            loadImage();
        });

        var exitBtn = new FlxButton(20, 60, "Exit Game", function()
        {
            playClick();
            closeGame();
        });

        var configBtn = new FlxButton(20, 100, "Config", function()
        {
            playClick();
            FlxG.switchState(new ReConfigState());
        });

        var resetBtn = new FlxButton(20, 140, "Reset Values", function()
        {
            playClick();
            resetDefaults();
        });

        mainGroup.add(loadBtn);
        mainGroup.add(exitBtn);
        mainGroup.add(configBtn);
        mainGroup.add(resetBtn);

        tabMenu.addGroup(mainGroup);

        // =====================
        // SHADER TAB
        // =====================
        shaderGroup = new FlxUIGroup();

        ampText = new FlxText(20, 20, 400, "");
        freqText = new FlxText(20, 60, 400, "");
        speedText = new FlxText(20, 100, 400, "");
        timeText = new FlxText(20, 140, 400, "");

        shaderGroup.add(ampText);
        shaderGroup.add(freqText);
        shaderGroup.add(speedText);
        shaderGroup.add(timeText);

        tabMenu.addGroup(shaderGroup);

        // =====================
        // SYSTEM TAB
        // =====================
        systemGroup = new FlxUIGroup();

        versionText = new FlxText(20, 20, 500, "Version: " + currentVersion);
        var toggleText = new FlxText(20, 60, 500, "Press SPACE to toggle UI");

        systemGroup.add(versionText);
        systemGroup.add(toggleText);

        tabMenu.addGroup(systemGroup);

        updateShaderValues();
        updateBrightness();
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
            tabMenu.active = uiVisible;
        }
    }

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

    function fitImageToScreen():Void
    {
        if (bg == null || bg.graphic == null) return;

        var scaleX = FlxG.width / bg.width;
        var scaleY = FlxG.height / bg.height;
        var finalScale = Math.max(scaleX, scaleY);

        bg.scale.set(finalScale, finalScale);
        bg.updateHitbox();
        bg.screenCenter();
    }

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

    function loadSettings():Void
    {
        if (FlxG.save.data.waveAmplitude != null)
            waveAmplitude = FlxG.save.data.waveAmplitude;

        if (FlxG.save.data.frequency != null)
            frequency = FlxG.save.data.frequency;

        if (FlxG.save.data.speed != null)
            speed = FlxG.save.data.speed;
    }

    function initCrashHandler():Void
    {
        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
            UncaughtErrorEvent.UNCAUGHT_ERROR,
            function(e:UncaughtErrorEvent):Void
            {
                var errorMsg:String = e.error != null ? Std.string(e.error) : "Unknown Crash";

                #if sys
                try
                {
                    if (!FileSystem.exists("crash"))
                        FileSystem.createDirectory("crash");

                    File.saveContent(
                        "crash/playstate_crash_" + Date.now().getTime() + ".txt",
                        "Error: " + errorMsg
                    );
                }
                catch (saveError:Dynamic) {}
                #end

                FlxG.log.error("CRASH DETECTED: " + errorMsg);
            }
        );
    }
}
