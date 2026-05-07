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

import states.ReConfigState;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

class PlayState extends FlxState
{
    var bg:FlxSprite;
    var fileRef:FileReference;

    var shader:WiggleEffect;

    var waveAmplitude:Float = 0.1;
    var frequency:Float = 5.0;
    var speed:Float = 2.0;
    var brightness:Float = 1.0;

    var brightnessOverlay:FlxSprite;

    var tabMenu:FlxUITabMenu;

    var mainGroup:FlxUIGroup;
    var shaderGroup:FlxUIGroup;
    var imageGroup:FlxUIGroup;
    var systemGroup:FlxUIGroup;

    var ampText:FlxText;
    var freqText:FlxText;
    var speedText:FlxText;
    var timeText:FlxText;
    var versionText:FlxText;

    var uiVisible:Bool = true;

    var currentVersion:String = "0.1.0";
    var defaultImage:String = "assets/images/bg/cheeseburger.png";

    override public function create():Void
    {
        super.create();

        initCrashHandler();

        // =====================
        // BACKGROUND
        // =====================
        bg = new FlxSprite().loadGraphic(defaultImage);
        add(bg);

        shader = new WiggleEffect();
        shader.uTime.value = [0.0];
        shader.uSpeed.value = [speed];
        shader.uFrequency.value = [frequency];
        shader.uWaveAmplitude.value = [waveAmplitude];

        bg.shader = shader;

        brightnessOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        add(brightnessOverlay);

        // =====================
        // TAB MENU
        // =====================
        tabMenu = new FlxUITabMenu(null, [
            {name: "main", label: "Main"},
            {name: "shader", label: "Shader"},
            {name: "image", label: "Image"},
            {name: "system", label: "System"}
        ], true);

        tabMenu.resize(340, 280);
        tabMenu.x = 10;
        tabMenu.y = 10;
        add(tabMenu);

        // =====================
        // MAIN TAB
        // =====================
        mainGroup = new FlxUIGroup();

        var quitBtn = new FlxButton(10, 10, "Quit Game", function()
        {
            FlxG.exit();
        });

        var settingsBtn = new FlxButton(10, 50, "Open Settings", function()
        {
            FlxG.switchState(new ReConfigState());
        });

        var resetBtn = new FlxButton(10, 90, "Reset Values", function()
        {
            waveAmplitude = 0.1;
            frequency = 5.0;
            speed = 2.0;
            updateShader();
        });

        mainGroup.add(quitBtn);
        mainGroup.add(settingsBtn);
        mainGroup.add(resetBtn);

        tabMenu.addGroup(mainGroup, "main");

        // =====================
        // SHADER TAB
        // =====================
        shaderGroup = new FlxUIGroup();

        ampText = new FlxText(10, 10, 200, "");
        freqText = new FlxText(10, 40, 200, "");
        speedText = new FlxText(10, 70, 200, "");

        shaderGroup.add(ampText);
        shaderGroup.add(freqText);
        shaderGroup.add(speedText);

        var ampMinus = new FlxButton(10, 110, "-", function()
        {
            waveAmplitude -= 0.01;
            updateShader();
        });

        var ampPlus = new FlxButton(60, 110, "+", function()
        {
            waveAmplitude += 0.01;
            updateShader();
        });

        var freqMinus = new FlxButton(10, 150, "-", function()
        {
            frequency -= 1;
            updateShader();
        });

        var freqPlus = new FlxButton(60, 150, "+", function()
        {
            frequency += 1;
            updateShader();
        });

        var speedMinus = new FlxButton(10, 190, "-", function()
        {
            speed -= 0.1;
            updateShader();
        });

        var speedPlus = new FlxButton(60, 190, "+", function()
        {
            speed += 0.1;
            updateShader();
        });

        shaderGroup.add(ampMinus);
        shaderGroup.add(ampPlus);
        shaderGroup.add(freqMinus);
        shaderGroup.add(freqPlus);
        shaderGroup.add(speedMinus);
        shaderGroup.add(speedPlus);

        tabMenu.addGroup(shaderGroup, "shader");

        // =====================
        // IMAGE TAB
        // =====================
        imageGroup = new FlxUIGroup();

        var importBtn = new FlxButton(10, 10, "Import Image", function()
        {
            loadImage();
        });

        imageGroup.add(importBtn);

        tabMenu.addGroup(imageGroup, "image");

        // =====================
        // SYSTEM TAB
        // =====================
        systemGroup = new FlxUIGroup();

        versionText = new FlxText(10, 10, 200, "Version: " + currentVersion);
        timeText = new FlxText(10, 40, 200, "Time: 0");

        systemGroup.add(versionText);
        systemGroup.add(timeText);

        tabMenu.addGroup(systemGroup, "system");

        updateShader();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        shader.uTime.value[0] += elapsed;
        timeText.text = "Time: " + Std.int(shader.uTime.value[0]);

        if (FlxG.keys.justPressed.SPACE)
        {
            uiVisible = !uiVisible;
            tabMenu.visible = uiVisible;
            tabMenu.active = uiVisible;
        }
    }

    function updateShader():Void
    {
        shader.uWaveAmplitude.value = [waveAmplitude];
        shader.uFrequency.value = [frequency];
        shader.uSpeed.value = [speed];

        ampText.text = "Amplitude: " + waveAmplitude;
        freqText.text = "Frequency: " + frequency;
        speedText.text = "Speed: " + speed;
    }

    function loadImage():Void
    {
        fileRef = new FileReference();

        fileRef.addEventListener(Event.SELECT, function(_)
        {
            fileRef.addEventListener(Event.COMPLETE, function(_)
            {
                var loader = new Loader();

                loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(_)
                {
                    var bmp:Bitmap = cast loader.content;
                    bg.loadGraphic(bmp.bitmapData);
                    bg.shader = shader;
                });

                loader.loadBytes(fileRef.data);
            });

            fileRef.load();
        });

        fileRef.browse([new FileFilter("Images", "*.png;*.jpg;*.jpeg")]);
    }

    function initCrashHandler():Void
    {
        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
            UncaughtErrorEvent.UNCAUGHT_ERROR,
            function(e:UncaughtErrorEvent)
            {
                FlxG.log.error("Crash: " + Std.string(e.error));
            }
        );
    }
}
