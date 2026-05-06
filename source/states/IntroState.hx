package states;

import flixel.FlxState;
import flixel.FlxG;

import states.ConfigState;
import states.PlayState;

import openfl.Assets;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class IntroState extends FlxState
{
    override public function create():Void
    {
        super.create();
        decideNextState();
    }

    function decideNextState():Void
    {
        if (FlxG.save.data.configured != null && FlxG.save.data.configured == true)
        {
            configured = true;
        }
    }

        if (configured)
        {
            FlxG.switchState(new PlayState());
        }
        else
        {
            FlxG.switchState(new ConfigState());
        }
    }
}
