package states;

import flixel.FlxState;
import flixel.FlxG;

import states.ConfigState;
import states.PlayState;

import flixel.addons.video.FlxVideo;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class InitState extends FlxState
{
    var vid:FlxVideo;
    var nextState:FlxState;

    override public function create()
    {
        super.create();

        vid = new FlxVideo();
        vid.load("assets/videos/init.mp4");
        vid.play();

        vid.finishCallback = function()
        {
            decideNextState();
        };
    }

    function decideNextState():Void
    {
        nextState = new ConfigState();

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

    override public function destroy()
    {
        if (vid != null)
        {
            vid.stop();
            vid = null;
        }

        super.destroy();
    }
}
