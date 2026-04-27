package states;

import flixel.FlxState;
import flathx.util.FlxDirectionFlags;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxTypedGroup;
import flixel.util.FlxTimer;
import backend.Paths;

class PlayState extends FlxState {
    var packman:FlxSprite;
    var body:FlxTypedGroup<FlxSprite>;
    var moveSpeed:Float = 0.15;
    var direction:Int = 1; // 0 = up, 1 = down
    var gridSize:Int = 32;

    override public function create() {
        super.create();

        // Fundo simples
        bgColor = 0xFF000000;

        // Grupo do corpo
        body = new FlxTypedGroup<FlxSprite>();
        add(body);

        // Cabeça da cobra usando sprite com animação idle
        packman = new FlxSprite(FlxG.width / 2, FlxG.height / 2);
        packman.frames = Paths.getSparrowAtlas("packman"); // assets/images/packman.png + xml
        packman.animation.addByPrefix("idle", "idle", 24, true);
        packman.animation.play("idle");
        packman.scale.set(0.5, 0.5);
        packman.updateHitbox();
        add(packman);

        // Timer de movimento
        new FlxTimer().start(moveSpeed, moveSnake, 0);
    }

    function moveSnake(timer:FlxTimer) {
        // Controles
        if (FlxG.keys.justPressed.UP) direction = 0;
        if (FlxG.keys.justPressed.DOWN) direction = 1;

        // Segmento antigo
        var segment = new FlxSprite(packman.x, packman.y);
        segment.makeGraphic(gridSize, gridSize, 0xFF00FF00);
        body.add(segment);

        // Movimento vertical
        switch (direction) {
            case 0:
                packman.y -= gridSize;
            case 1:
                packman.y += gridSize;
        }

        // Limite de tela
        if (packman.y < 0) packman.y = FlxG.height - gridSize;
        if (packman.y > FlxG.height - gridSize) packman.y = 0;

        // Limitar tamanho da cobra
        if (body.length > 8) {
            var old = body.members[0];
            if (old != null) {
                body.remove(old, true);
                old.destroy();
            }
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        // Mantém idle sempre ativo
        if (packman.animation.curAnim == null || !packman.animation.curAnim.name.equals("idle")) {
            packman.animation.play("idle");
        }
    }
}
