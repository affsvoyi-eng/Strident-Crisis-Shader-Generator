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

    var tabMenu:FlxUITabMenu;

    var mainGroup:FlxUIGroup;
    var shaderGroup:FlxUIGroup;
    var imageGroup:FlxUIGroup;
    var systemGroup:FlxUIGroup;

    var currentVersion:String = "0.1.0";
    var defaultImage:String = "assets/images/bg/cheeseburger.png";

    override public function create():Void
    {
        super.create();

        initCrashHandler();
        loadSettings();

        // BACKGROUND
        bg = new FlxSprite().loadGraphic(defaultImage);
        add(bg);
        fitImageToScreen();

        shader = new WiggleEffect();
        shader.uTime.value = [0.0];
        shader.uSpeed.value = [speed];
        shader.uFrequency.value = [frequency];
        shader.uWaveAmplitude.value = [waveAmplitude];
        bg.shader = shader;

        brightnessOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        add(brightnessOverlay);

        // =========================
        // TAB MENU
        // =========================
        tabMenu = new FlxUITabMenu(null, [
            {name: "main", label: "Main"},
            {name: "shader", label: "Shader"},
            {name: "image", label: "Image"},
            {name: "system", label: "System"}
        ], true);

        tabMenu.resize(300, 250);
        tabMenu.x = 10;
        tabMenu.y = 10;
        add(tabMenu);

        // =========================
        // MAIN TAB
        // =========================
        mainGroup = new FlxUIGroup();

        var quitBtn = new FlxButton(10, 10, "Quit Application", function()
        {
            playClick();
            closeGame();
        });

        var settingsBtn = new FlxButton(10, 50, "Open Settings", function()
        {
            playClick();
            FlxG.switchState(new ReConfigState());
        });

        var resetBtn = new FlxButton(10, 90, "Restore Defaults", function()
        {
            playClick();
            resetDefaults();
        });

        mainGroup.add(quitBtn);
        mainGroup.add(settingsBtn);
        mainGroup.add(resetBtn);

        tabMenu.addGroup(mainGroup);

        // =========================
        // SHADER TAB
        // =========================
        shaderGroup = new FlxUIGroup();

        ampText = new FlxText(10, 10, 200, "Wave Amplitude: " + waveAmplitude);
        freqText = new FlxText(10, 40, 200, "Frequency: " + frequency);
        speedText = new FlxText(10, 70, 200, "Speed: " + speed);

        shaderGroup.add(ampText);
        shaderGroup.add(freqText);
        shaderGroup.add(speedText);

        var ampMinus = new FlxButton(10, 110, "-", () -> { waveAmplitude = Math.max(0, waveAmplitude - 0.005); updateShaderValues(); });
        var ampPlus  = new FlxButton(60, 110, "+", () -> { waveAmplitude += 0.005; updateShaderValues(); });

        var freqMinus = new FlxButton(10, 150, "-", () -> { frequency = Math.max(1, frequency - 1); updateShaderValues(); });
        var freqPlus  = new FlxButton(60, 150, "+", () -> { frequency += 1; updateShaderValues(); });

        var speedMinus = new FlxButton(10, 190, "-", () -> { speed = Math.max(0.1, speed - 0.1); updateShaderValues(); });
        var speedPlus  = new FlxButton(60, 190, "+", () -> { speed += 0.1; updateShaderValues(); });

        shaderGroup.add(ampMinus);
        shaderGroup.add(ampPlus);
        shaderGroup.add(freqMinus);
        shaderGroup.add(freqPlus);
        shaderGroup.add(speedMinus);
        shaderGroup.add(speedPlus);

        tabMenu.addGroup(shaderGroup);

        // =========================
        // IMAGE TAB
        // =========================
        imageGroup = new FlxUIGroup();

        var importBtn = new FlxButton(10, 10, "Import Background", function()
        {
            playClick();
            loadImage();
        });

        imageGroup.add(importBtn);

        tabMenu.addGroup(imageGroup);

        // =========================
        // SYSTEM TAB
        // =========================
        systemGroup = new FlxUIGroup();

        versionText = new FlxText(10, 10, 200, "Version: " + currentVersion);
        timeText = new FlxText(10, 40, 200, "Time: 0");

        systemGroup.add(versionText);
        systemGroup.add(timeText);

        tabMenu.addGroup(systemGroup);

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

        FlxTween.tween(window, {y: startY - 20}, 0.15, {
            ease: FlxEase.quadOut,
            onComplete: function(_) {
                FlxTween.tween(window, {y: startY + 400}, 0.4, {
                    ease: FlxEase.quadIn,
                    onComplete: function(_) {
                        #if sys Sys.exit(0); #else Lib.close(); #end
                    }
                });
            }
        });
        #end
    }

    function fitImageToScreen():Void
    {
        if (bg == null) return;

        var scaleX = FlxG.width / bg.width;
        var scaleY = FlxG.height / bg.height;
        var scale = Math.max(scaleX, scaleY);

        bg.scale.set(scale, scale);
        bg.updateHitbox();
        bg.screenCenter();
    }

    function loadImage():Void
    {
        fileRef = new FileReference();
        fileRef.addEventListener(Event.SELECT, function(_) {
            fileRef.addEventListener(Event.COMPLETE, onFileLoaded);
            fileRef.load();
        });

        fileRef.browse([new FileFilter("Images", "*.png;*.jpg;*.jpeg")]);
    }

    function onFileLoaded(e:Event):Void
    {
        var loader = new Loader();

        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(_) {
            var bmp:Bitmap = cast loader.content;
            bg.loadGraphic(bmp.bitmapData);
            fitImageToScreen();
            bg.shader = shader;
        });

        loader.loadBytes(fileRef.data);
    }

    function loadSettings():Void
    {
        if (FlxG.save.data.waveAmplitude != null) waveAmplitude = FlxG.save.data.waveAmplitude;
        if (FlxG.save.data.frequency != null) frequency = FlxG.save.data.frequency;
        if (FlxG.save.data.speed != null) speed = FlxG.save.data.speed;
    }

    function initCrashHandler():Void
    {
        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
            UncaughtErrorEvent.UNCAUGHT_ERROR,
            function(e:UncaughtErrorEvent)
            {
                var msg = Std.string(e.error);
                FlxG.log.error("CRASH: " + msg);
            }
        );
    }
    }
