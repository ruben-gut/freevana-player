package freevana.util
{
    import flash.events.*;
    import flash.net.URLRequest;
    import flash.net.URLLoader;
    import com.adobe.serialization.json.JSON; 

    /*
    * @author tirino
    */
    public class Updates
    {
        public static const PLAYER:String = 'player';
        public static const PLAYER_LINK:String = 'player_link';
        public static const PLAYER_TEXT:String = 'player_text';
        public static const DATABASE:String = 'db';
        public static const DATABASE_LINK:String = 'db_link';
        public static const DATABASE_TEXT:String = 'db_text';

        private static const UPDATES_URL:String = 'http://tirino.github.com/freevana/updates.json';
        private static const CHECK_INTERVAL:int = 60 * 60 * 12; // 24 hours

        private var _urlLoader:URLLoader;
        private var _settings:Settings;

        public function Updates():void
        {
            _settings = new Settings();
        }

        /**
        * Check for updates agains Freevana's servers
        */
        public function checkForUpdates(callback:Function):void
        {
            var date:Date = new Date();
            var now:Number = Math.round(date.time / 1000);
            if (now < (_settings.getLastUpdateCheck() + CHECK_INTERVAL)) {
                trace("[Updates] we already checked on " + new Date(_settings.getLastUpdateCheck() * 1000));
                return;
            }

            _urlLoader = new URLLoader();
            _urlLoader.addEventListener(Event.COMPLETE, handleResult);
            _urlLoader.addEventListener(Event.CANCEL, handleResult);
            _urlLoader.addEventListener(Event.SELECT, handleResult);
            _urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, handleResult);
            _urlLoader.addEventListener(IOErrorEvent.IO_ERROR, handleResult);
            _urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleResult);

            function handleResult(event:Event):void {
                if (event.type == Event.COMPLETE) {
                    var jsonUpdate:Object;
                    var update:String = _urlLoader.data;
                    trace("[Updates] Got update: " + update);
                    try {
                        jsonUpdate = JSON.decode(update);
                        if (callback != null) {
                            callback(jsonUpdate);
                            _settings.setLastUpdateCheck(now);
                        }
                    } catch (error:Error) {
                        trace("[Updates] Error: " + error.message);
                    }
                } else if (event.type == IOErrorEvent.IO_ERROR || 
                        event.type == Event.CANCEL || 
                        event.type == SecurityErrorEvent.SECURITY_ERROR) {
                    trace("[Updates] download > Event error: " + event);
                }
            }
            var _time:Date = new Date();
            _urlLoader.load(new URLRequest(UPDATES_URL + '?' + _time.time));
        }
   }
}