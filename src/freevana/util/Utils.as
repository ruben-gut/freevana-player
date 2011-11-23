package freevana.util
{
    import flash.system.Capabilities;

    public class Utils
    {
        public static function isLinux():Boolean
        {
            var _os:String = Capabilities.os.substr(0, 3);
            return (_os != "Win" && _os != "Mac")
        }

        public static function isWindows():Boolean
        {
            var _os:String = Capabilities.os.substr(0, 3);
            return (_os == "Win");
        }

        public static function isMac():Boolean
        {
            var _os:String = Capabilities.os.substr(0, 3);
            return (_os == "Mac");
        }
    }
}