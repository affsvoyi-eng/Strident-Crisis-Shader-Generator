package states;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.tweens.TweenCallback;
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

        initCrashHandler();
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

        /** Itens que ficam fora do menu, mantidos na tela principal **/
        versionText = new FlxText(20, FlxG.height - 50, 500, "Version: " + currentVersion);
        add(versionText);

        timeText = new FlxText(20, 410, 400, "Time: 0");
        add(timeText);

        toggleText = new FlxText(20, FlxG.height - 30, 500, "Press SPACE to toggle UI");
        add(toggleText);

        /** Construção do menu de abas (principal mudança) **/
        createTabMenu();
        add(tabMenu);

        updateBrightness();
    }

    function createTabMenu():Void
    {
        // ─── Aba "Wiggle" ────────────────────────────────────────
        var wiggleGroup = new FlxUIGroup();
        wiggleGroup.name = "Wiggle";   // nome da aba (usado como rótulo)

        ampText = new FlxText(10, 10, 380, "Wave Amplitude: " + waveAmplitude);
        wiggleGroup.add(ampText);

        var ampMinus = new FlxButton(10, 40, "-", function() {
            waveAmplitude = Math.max(0, waveAmplitude - 0.005);
            updateShaderValues();
        });
        wiggleGroup.add(ampMinus);

        var ampPlus = new FlxButton(110, 40, "+", function() {
            waveAmplitude += 0.005;
            updateShaderValues();
        });
        wiggleGroup.add(ampPlus);

        freqText = new FlxText(10, 80, 380, "Frequency: " + frequency);
        wiggleGroup.add(freqText);

        var freqMinus = new FlxButton(10, 110, "-", function() {
            frequency = Math.max(1, frequency - 1);
            updateShaderValues();
        });
        wiggleGroup.add(freqMinus);

        var freqPlus = new FlxButton(110, 110, "+", function() {
            frequency += 1;
            updateShaderValues();
        });
        wiggleGroup.add(freqPlus);

        speedText = new FlxText(10, 150, 380, "Speed: " + speed);
        wiggleGroup.add(speedText);

        var speedMinus = new FlxButton(10, 180, "-", function() {
            speed = Math.max(0.1, speed - 0.1);
            updateShaderValues();
        });
        wiggleGroup.add(speedMinus);

        var speedPlus = new FlxButton(110, 180, "+", function() {
            speed += 0.1;
            updateShaderValues();
        });
        wiggleGroup.add(speedPlus);

        // ─── Aba "Brightness" ────────────────────────────────────
        var brightnessGroup = new FlxUIGroup();
        brightnessGroup.name = "Brightness";

        brightText = new FlxText(10, 10, 380, "Brightness: " + brightness);
        brightnessGroup.add(brightText);

        var brightMinus = new FlxButton(10, 40, "-", function() {
            brightness = Math.max(0, brightness - 0.1);
            updateBrightness();
        });
        brightnessGroup.add(brightMinus);

        var brightPlus = new FlxButton(110, 40, "+", function() {
            brightness = Math.min(1, brightness + 0.1);
            updateBrightness();
        });
        brightnessGroup.add(brightPlus);

        // ─── Aba "Actions" ───────────────────────────────────────
        var actionsGroup = new FlxUIGroup();
        actionsGroup.name = "Actions";

        var loadBtn = new FlxButton(10, 10, "Add Image", function() {
            playClick();
            loadImage();
        });
        actionsGroup.add(loadBtn);

        var resetBtn = new FlxButton(10, 50, "Reset", function() {
            playClick();
            resetDefaults();
        });
        actionsGroup.add(resetBtn);

        var configBtn = new FlxButton(10, 90, "Config", function() {
            playClick();
            FlxG.switchState(new ReConfigState());
        });
        actionsGroup.add(configBtn);

        var exitBtn = new FlxButton(10, 130, "Exit", function() {
            playClick();
            closeGame();
        });
        actionsGroup.add(exitBtn);

        // Cria o menu com as três abas
        tabMenu = new FlxUITabMenu(null, [wiggleGroup, brightnessGroup, actionsGroup]);
        tabMenu.x = 20;
        tabMenu.y = 20;
    }

    function initCrashHandler():Void { /* ... */ }   // igual ao seu original

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
            versionText.visible = uiVisible;
            timeText.visible = uiVisible;
            toggleText.visible = uiVisible;
        }
    }

    function resetDefaults():Void { /* ... */ }

    function updateBrightness():Void {
        brightnessOverlay.alpha = 1 - brightness;
        brightText.text = "Brightness: " + brightness;
    }

    function updateShaderValues():Void { /* ... */ }

    function playClick():Void {
        FlxG.sound.play("assets/sounds/click.ogg");
    }

    function closeGame():Void
    {
        #if desktop
        var window:Window = Application.current.window;
        var startY:Float = window.y;

        // Callback tipado explicitamente para evitar erro de tipo
        var step1:TweenCallback = function(_) {
            var step2:TweenCallback = function(_) {
                #if sys
                Sys.exit(0);
                #else
                Lib.close();
                #end
            };
            FlxTween.tween(window, {y: startY + 400}, 0.4, {
                ease: FlxEase.quadIn,
                onComplete: step2
            });
        };

        FlxTween.tween(window, {y: startY - 20}, 0.15, {
            ease: FlxEase.quadOut,
            onComplete: step1
        });
        #end
    }

    function fitImageToScreen():Void
{
    if (bg == null || bg.graphic == null) return;

    bg.scale.set(1, 1);
    bg.updateHitbox();

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

function loadSettings():Void
{
    if (FlxG.save.data.waveAmplitude != null)
        waveAmplitude = FlxG.save.data.waveAmplitude;
    if (FlxG.save.data.frequency != null)
        frequency = FlxG.save.data.frequency;
    if (FlxG.save.data.speed != null)
        speed = FlxG.save.data.speed;
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
