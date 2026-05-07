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

    // Tabs system
    var currentTab:Int = 0;

    var controlUI:Array<Dynamic> = [];
    var imageUI:Array<Dynamic> = [];
    var shaderUI:Array<Dynamic> = [];

    var defaultImage:String = "assets/images/bg/cheeseburger.png";
    var currentVersion:String = "0.1.0";

    override public function create():Void
    {
        super.create();

        initCrashHandler();
        loadSettings();

        // BACKGROUND
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

        // VERSION TEXT
        versionText = new FlxText(20, FlxG.height - 50, 500, "Version: " + currentVersion);
        add(versionText);

        // =========================
        // TAB BUTTONS
        // =========================

        var tabControl = new FlxButton(20, 10, "Painel Geral", function()
        {
            switchTab(0);
        });

        var tabImage = new FlxButton(150, 10, "Imagem de Fundo", function()
        {
            switchTab(1);
        });

        var tabShader = new FlxButton(320, 10, "Efeitos Visuais", function()
        {
            switchTab(2);
        });

        add(tabControl);
        add(tabImage);
        add(tabShader);

        // =========================
        // CONTROL TAB
        // =========================

        var loadBtn = new FlxButton(20, 60, "Carregar Imagem", function()
        {
            playClick();
            loadImage();
        });

        var exitBtn = new FlxButton(20, 100, "Sair do App", function()
        {
            playClick();
            closeGame();
        });

        var configBtn = new FlxButton(20, 140, "Configurações", function()
        {
            playClick();
            FlxG.switchState(new ReConfigState());
        });

        var resetBtn = new FlxButton(20, 180, "Reset Tudo", function()
        {
            playClick();
            resetDefaults();
        });

        controlUI.push(loadBtn);
        controlUI.push(exitBtn);
        controlUI.push(configBtn);
        controlUI.push(resetBtn);
        controlUI.push(versionText);

        add(loadBtn);
        add(exitBtn);
        add(configBtn);
        add(resetBtn);

        // =========================
        // IMAGE TAB
        // =========================

        imageUI.push(loadBtn);

        // =========================
        // SHADER TAB
        // =========================

        ampText = new FlxText(20, 60, 400, "Amplitude: " + waveAmplitude);
        freqText = new FlxText(20, 120, 400, "Frequência: " + frequency);
        speedText = new FlxText(20, 180, 400, "Velocidade: " + speed);

        var ampMinus = new FlxButton(20, 80, "-", function()
        {
            waveAmplitude = Math.max(0, waveAmplitude - 0.005);
            updateShaderValues();
        });

        var ampPlus = new FlxButton(80, 80, "+", function()
        {
            waveAmplitude += 0.005;
            updateShaderValues();
        });

        var freqMinus = new FlxButton(20, 140, "-", function()
        {
            frequency = Math.max(1, frequency - 1);
            updateShaderValues();
        });

        var freqPlus = new FlxButton(80, 140, "+", function()
        {
            frequency += 1;
            updateShaderValues();
        });

        var speedMinus = new FlxButton(20, 200, "-", function()
        {
            speed = Math.max(0.1, speed - 0.1);
            updateShaderValues();
        });

        var speedPlus = new FlxButton(80, 200, "+", function()
        {
            speed += 0.1;
            updateShaderValues();
        });

        var brightMinus = new FlxButton(20, 260, "-", function()
        {
            brightness = Math.max(0, brightness - 0.1);
            updateBrightness();
        });

        var brightPlus = new FlxButton(80, 260, "+", function()
        {
            brightness = Math.min(1, brightness + 0.1);
            updateBrightness();
        });

        timeText = new FlxText(20, 320, 400, "Time: 0");

        shaderUI.push(ampText);
        shaderUI.push(freqText);
        shaderUI.push(speedText);
        shaderUI.push(timeText);

        shaderUI.push(ampMinus);
        shaderUI.push(ampPlus);
        shaderUI.push(freqMinus);
        shaderUI.push(freqPlus);
        shaderUI.push(speedMinus);
        shaderUI.push(speedPlus);
        shaderUI.push(brightMinus);
        shaderUI.push(brightPlus);

        add(ampText);
        add(freqText);
        add(speedText);
        add(timeText);

        add(ampMinus);
        add(ampPlus);
        add(freqMinus);
        add(freqPlus);
        add(speedMinus);
        add(speedPlus);
        add(brightMinus);
        add(brightPlus);

        // START TAB
        switchTab(0);

        updateBrightness();
    }

    // =========================
    // TAB SYSTEM
    // =========================

    function switchTab(tab:Int):Void
    {
        currentTab = tab;

        for (e in controlUI) e.visible = (tab == 0);
        for (e in imageUI) e.visible = (tab == 1);
        for (e in shaderUI) e.visible = (tab == 2);
    }

    // =========================
    // UPDATE
    // =========================

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        shader.uTime.value[0] += elapsed;
        timeText.text = "Time: " + Std.int(shader.uTime.value[0] * 100) / 100;

        if (FlxG.keys.justPressed.SPACE)
        {
            uiVisible = !uiVisible;

            for (e in uiElements)
            {
                e.visible = uiVisible;
                e.active = uiVisible;
            }
        }
    }

    // =========================
    // SHADER
    // =========================

    function updateShaderValues():Void
    {
        shader.uWaveAmplitude.value = [waveAmplitude];
        shader.uFrequency.value = [frequency];
        shader.uSpeed.value = [speed];

        ampText.text = "Amplitude: " + waveAmplitude;
        freqText.text = "Frequência: " + frequency;
        speedText.text = "Velocidade: " + speed;
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
    // IMAGE LOAD
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
    // CLOSE GAME
    // =========================

    function closeGame():Void
    {
        #if desktop
        var window:Window = Application.current.window;
        var startY:Float = window.y;

        FlxTween.tween(window, { y: startY - 20 }, 0.15, {
            ease: FlxEase.quadOut,
            onComplete: function(_)
            {
                FlxTween.tween(window, { y: startY + 400 }, 0.4, {
                    ease: FlxEase.quadIn,
                    onComplete: function(_)
                    {
                        #if sys Sys.exit(0); #else Lib.close(); #end
                    }
                });
            }
        });
        #end
    }

    // =========================
    // UTIL
    // =========================

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
                var errorMsg:String = e.error != null ? Std.string(e.error) : "Unknown Crash";

                #if sys
                try
                {
                    if (!FileSystem.exists("crash"))
                        FileSystem.createDirectory("crash");

                    File.saveContent("crash/playstate_" + Date.now().getTime() + ".txt", errorMsg);
                }
                catch (e:Dynamic) {}
                #end

                FlxG.log.error(errorMsg);
            }
        );
    }
}
