package states;

import flixel.FlxState;
import flixel.FlxG;

import states.ConfigState;
import states.PlayState;

class IntroState extends FlxState
{
    override public function create():Void
    {
        super.create();
        decideNextState();
    }

    function decideNextState():Void
    {
        var configured:Bool = FlxG.save.data.configured != null && FlxG.save.data.configured == true;

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
