package states;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.ui.FlxButton;

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

import shader.Shaders.WiggleEffect;

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

    var tabMenu:FlxUITabMenu;

    var mainGroup:FlxUIGroup;
    var shaderGroup:FlxUIGroup;
    var systemGroup:FlxUIGroup;

    var currentVersion:String = "0.1.0";

    override public function create():Void
    {
        super.create();

        initCrashHandler();

        // BACKGROUND
        bg = new FlxSprite();
        bg.loadGraphic("assets/images/bg/cheeseburger.png");
        add(bg);

        shader = new WiggleEffect();
        shader.uTime.value = [0.0];
        shader.uSpeed.value = [speed];
        shader.uFrequency.value = [frequency];
        shader.uWaveAmplitude.value = [waveAmplitude];

        bg.shader = shader;

        brightnessOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        add(brightnessOverlay);

        // ======================
        // TAB MENU (SÓ ADIÇÃO)
        // ======================
        tabMenu = new FlxUITabMenu(null, [
            {name: "main", label: "Main"},
            {name: "shader", label: "Shader"},
            {name: "system", label: "System"}
        ], true);

        tabMenu.resize(320, 260);
        tabMenu.x = 10;
        tabMenu.y = 10;
        add(tabMenu);

        // ======================
        // MAIN TAB (SEUS BOTÕES)
        // ======================
        mainGroup = new FlxUIGroup();

        var loadBtn = new FlxButton(10, 10, "Add Image", function()
        {
            loadImage();
        });

        var exitBtn = new FlxButton(10, 50, "Exit", function()
        {
            closeGame();
        });

        var reconfigBtn = new FlxButton(10, 90, "Config", function()
        {
            FlxG.switchState(new ReConfigState());
        });

        var resetBtn = new FlxButton(10, 130, "Reset", function()
        {
            resetDefaults();
        });

        mainGroup.add(loadBtn);
        mainGroup.add(exitBtn);
        mainGroup.add(reconfigBtn);
        mainGroup.add(resetBtn);

        tabMenu.addGroup(mainGroup);

        // ======================
        // SHADER TAB (SEU UI ORIGINAL)
        // ======================
        shaderGroup = new FlxUIGroup();

        ampText = new FlxText(10, 10, 200, "");
        freqText = new FlxText(10, 40, 200, "");
        speedText = new FlxText(10, 70, 200, "");

        shaderGroup.add(ampText);
        shaderGroup.add(freqText);
        shaderGroup.add(speedText);

        tabMenu.addGroup(shaderGroup);

        // ======================
        // SYSTEM TAB
        // ======================
        systemGroup = new FlxUIGroup();

        versionText = new FlxText(10, 10, 200, "Version: " + currentVersion);
        timeText = new FlxText(10, 40, 200, "Time: 0");

        systemGroup.add(versionText);
        systemGroup.add(timeText);

        tabMenu.addGroup(systemGroup);

        updateShaderValues();
        updateBrightness();
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
        }
    }

    function updateShaderValues():Void
    {
        shader.uWaveAmplitude.value = [waveAmplitude];
        shader.uFrequency.value = [frequency];
        shader.uSpeed.value = [speed];

        ampText.text = "Amplitude: " + waveAmplitude;
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

        updateShaderValues();
    }

    function loadImage():Void
    {
        fileRef = new FileReference();
        fileRef.browse([new FileFilter("Images", "*.png;*.jpg;*.jpeg")]);
    }

    function initCrashHandler():Void
    {
        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
            UncaughtErrorEvent.UNCAUGHT_ERROR,
            function(e)
            {
                FlxG.log.error("Crash: " + e.error);
            }
        );
    }

    function closeGame():Void
    {
        #if sys
        Sys.exit(0);
        #else
        Lib.close();
        #end
    }
}
