package freevana.download
{
    /*
    * @author tirino
    */
    public class Recaptcha
    {
        public static const CHALLENGE_URL:String = 'http://api.recaptcha.net/challenge?k=';
        public static const IMAGE_URL:String = 'http://www.google.com/recaptcha/api/image?c=';

        public static const CHALLENGE_ID_PATTERN:RegExp = new RegExp(/Recaptcha.create\("(.*?)"/);
        public static const NEW_CHALLENGE_PATTERN:RegExp = new RegExp(/challenge : '(.+?)',/);

    }
}