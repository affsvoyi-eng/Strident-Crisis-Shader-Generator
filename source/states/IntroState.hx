package states;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;

import states.ConfigState;
import states.PlayState;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class IntroState extends FlxState
{
    override public function create()
    {
        super.create();
            decideNextState();
    }

    function decideNextState():Void
    {
        var nextState:FlxState = new ConfigState();

        #if sys
        var bootPath:String = "assets/data/firstboot.txt";

        if (FileSystem.exists(bootPath))
        {
            var content:String = File.getContent(bootPath);

            if (content != null && content.indexOf("configured=true") != -1)
            {
                nextState = new PlayState();
            }
        }
        #end

        FlxG.switchState(nextState);
    }
}
