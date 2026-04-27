package backend;

class Paths {
    public static function image(key:String):String {
        return 'assets/images/' + key + '.png';
    }

    public static function sound(key:String):String {
        return 'assets/sounds/' + key + '.ogg';
    }
}
