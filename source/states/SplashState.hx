package states;

import flixel.system.FlxSplash;
import flixel.FlxG;

class SplashState extends FlxSplash
{
    override public function onComplete():Void
    {
        super.onComplete();
        FlxG.switchState(new IntroState());
    }
}
