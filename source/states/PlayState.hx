package states;

import flixel.FlxState;
import flixel.text.FlxText;

class PlayState extends FlxState {
    override public function create() {
        super.create();

        var txt = new FlxText(0, 0, 1280, "Template Ready!");
        txt.setFormat(null, 32);
        txt.screenCenter();
        add(txt);
    }
}
