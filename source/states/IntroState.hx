package states;

import flixel.FlxState;
import flixel.FlxG;

import states.ConfigState;
import states.PlayState;

import openfl.media.Video;
import openfl.media.VideoStream;
import openfl.display.Sprite;
import openfl.events.Event;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class IntroState extends FlxState
{
    var video:Video;
    var container:Sprite;

    override public function create()
    {
        super.create();

        container = new Sprite();
        FlxG.stage.addChild(container);

        video = new Video();
        video.x = 0;
        video.y = 0;

        container.addChild(video);

        video.attachNetStream(new VideoStream());
        video.attachNetStream(null); 

        var url = "assets/videos/init.mp4";
        video.attachNetStream(new openfl.net.NetStream(new openfl.net.NetConnection()));

        video.addEventListener(Event.COMPLETE, onVideoEnd);
        FlxG.stage.addEventListener(Event.ENTER_FRAME, checkVideoEnd);
    }

    function checkVideoEnd(e:Event):Void
    {
        if (video == null) return;

        if (video.playing == false)
        {
            finishVideo();
        }
    }

    function onVideoEnd(e:Event):Void
    {
        finishVideo();
    }

    function finishVideo():Void
    {
        if (container != null && container.parent != null)
            FlxG.stage.removeChild(container);

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

    override public function destroy()
    {
        if (video != null)
        {
            video = null;
        }

        if (container != null)
        {
            FlxG.stage.removeChild(container);
            container = null;
        }

        super.destroy();
    }
}
