package states;

import flixel.system.FlxSplash;
import flixel.FlxG;

class SplashState extends FlxSplash
{
    override public function create():Void
    {
        super.create();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (finished)
        {
            FlxG.switchState(new IntroState());
        }
    }
}
