package;

import openfl.display.Sprite;
import flixel.FlxGame;
import states.PlayState;
import ConfigState;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

class Main extends Sprite
{
    public function new()
    {
        super();

        var firstState:Class<Dynamic>;
        var bootPath = "assets/data/firstboot.txt";

        if (!FileSystem.exists(bootPath))
        {
            firstState = ConfigState;
        }
        else
        {
            var content = File.getContent(bootPath);
            firstState = (content.indexOf("configured=true") != -1) ? PlayState : ConfigState;
        }

        addChild(new FlxGame(1280, 720, firstState));
    }
}
