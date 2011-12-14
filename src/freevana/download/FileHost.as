package freevana.download
{
    /*
    * @author tirino
    */
    public class FileHost
    {
        public static const PAGE_LOADED_EVENT:String = "PageLoadedEvent";
        public static const COUNTER_CHANGED_EVENT:String = "CounterChangedEvent";
        public static const LINK_AVAILABLE_EVENT:String = "LinkAvailableEvent";
        public static const LINK_UNAVAILABLE_EVENT:String = "LinkUnavailableEvent";
        public static const RECAPTCHA_LOADED_EVENT:String = "RecaptchaLoadedEvent";

        public static const MEGAUPLOAD:String = 'megaupload';
        public static const WUPULOAD:String = 'wupload';

        public static function create(item:Object):IFileHost
        {
            if (item.source == WUPULOAD) {
                return new Wupload(item.url);
            } else {
                return new Megaupload(item.url);
            }
        }
    }
}