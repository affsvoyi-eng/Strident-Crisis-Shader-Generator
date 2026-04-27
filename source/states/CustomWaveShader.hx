// CustomWaveShader.hx
package states;

import flixel.system.FlxAssets.FlxShader;
import sys.io.File;

class CustomWaveShader extends FlxShader
{
    @:glFragmentSource("")
    public function new()
    {
        super();

        var shaderPath:String = "assets/wavy-shader/wavy.frag";
        var fragSource:String = File.getContent(shaderPath);

        this.glFragmentSource = fragSource;
    }
}
