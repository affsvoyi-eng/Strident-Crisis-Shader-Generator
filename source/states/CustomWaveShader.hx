package states;

import flixel.system.FlxAssets.FlxShader;
import openfl.utils.Assets;

class CustomWaveShader extends FlxShader
{
    @:glFragmentSource('
        #pragma header

        uniform float uTime;
        uniform float uSpeed;
        uniform float uFrequency;
        uniform float uWaveAmplitude;

        vec2 sineWave(vec2 pt)
        {
            float x = 0.0;
            float y = 0.0;

            float offsetY = sin(pt.y * uFrequency + 10.0 * pt.x + uTime * uSpeed) * uWaveAmplitude;
            float offsetX = sin(pt.x * uFrequency + 5.0 * pt.y + uTime * uSpeed) * uWaveAmplitude;

            pt.y += offsetY;
            pt.x += offsetX;

            return vec2(pt.x + x, pt.y + y);
        }

        void main()
        {
            vec2 uv = sineWave(openfl_TextureCoordv);
            gl_FragColor = texture2D(bitmap, uv);
        }
    ')

    public function new()
    {
        super();

        #if !macro
        var frag:String = Assets.getText("assets/data/shader/Wavy.frag");

        if (frag != null && frag.length > 0)
        {
            __glFragmentSource = frag;
        }
        #end
    }
}
