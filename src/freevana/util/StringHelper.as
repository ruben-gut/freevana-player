package freevana.util
{
    /*
    * @author tirino
    */
    public class StringHelper
    {
        public static function trim(str:String):String
        {
            str = str.replace(/^\s+/, '');
            for (var i:int = str.length - 1; i >= 0; i--) {
                if (/\S/.test(str.charAt(i))) {
                    str = str.substring(0, i + 1);
                    break;
                }
            }
            return str;
        }
    }
}