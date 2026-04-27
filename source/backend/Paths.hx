package backend;

import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets;

class Paths {
    public static function image(key:String):String {
        return 'assets/images/' + key + '.png';
    }

    public static function xml(key:String):String {
        return 'assets/images/' + key + '.xml';
    }

    public static function sound(key:String):String {
        return 'assets/sounds/' + key + '.ogg';
    }

    public static function getSparrowAtlas(key:String):FlxAtlasFrames {
        return FlxAtlasFrames.fromSparrow(
            image(key),
            Assets.getText(xml(key))
        );
    }
}
