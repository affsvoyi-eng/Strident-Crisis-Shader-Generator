package states;

import flixel.FlxState;
import flixel.FlxG;
import states.PlayState;
import states.ConfigState;

#if desktop
import hxcodec.flixel.FlxVideo; 
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class IntroState extends FlxState
{
    override public function create():Void
    {
        super.create();

        // Baseado na sintaxe do FlxVideo mostrada no vídeo
        var video = new FlxVideo("assets/videos/init.mp4");
        
        // Callback que é executado automaticamente assim que o vídeo termina.
        // É aqui que "depois disso você decide" a lógica do jogo.
        video.finishCallback = function() 
        {
            decideNextState();
        };

        // NOTA: Se você instalou o hxCodec (versões recentes), a sintaxe seria levemente diferente:
        // var video = new FlxVideo();
        // video.onEndReached.add(function() { decideNextState(); });
        // video.play("assets/videos/init.mp4");
    }

    // Movemos a sua função startGame() para cá, adaptada como uma mudança de Estado
    function decideNextState():Void
    {
        // Estado padrão caso nada seja encontrado
        var nextState:FlxState = new ConfigState();

        #if sys
        var bootPath:String = "assets/data/firstboot.txt";

        if (FileSystem.exists(bootPath))
        {
            var content:String = File.getContent(bootPath);

            if (content.indexOf("configured=true") != -1)
            {
                nextState = new PlayState();
            }
        }
        #end

        // Troca para o estado decidido (ConfigState ou PlayState)
        FlxG.switchState(nextState);
    }
}
