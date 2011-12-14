package freevana.download
{
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.TimerEvent;

    import flash.net.URLRequest;
    import flash.net.URLRequestHeader;
    import flash.net.URLRequestMethod;
    import flash.net.URLLoader;
    import flash.net.URLVariables;
    import flash.utils.Timer;

    import freevana.util.StringHelper;

    /*
    * @author tirino
    */
    public class Wupload extends EventDispatcher implements IFileHost
    {
        private static const DOWNLOAD_URL_PREFIX:String = 'http://www.wupload.com/file/';
        private static const COUNTDOWN_DELAY:String = 'countDownDelay';
        private static const DOWNLOAD_READY:String = 'Download Ready';

        private static const AJAX_URL_PATTERN:RegExp = new RegExp(/href="(.*?\?start=1)"/);
        private static const TM_PATTERN:RegExp = new RegExp("name='tm' value='(\\d+)'");
        private static const TM_HASH_PATTERN:RegExp = new RegExp("name='tm_hash' value='(\\w+)'");
        
        private static const DOWNLOAD_READY_PATTERN:RegExp = new RegExp('<span>Download Ready </span></h3>.*?<p><a href="(.*?)">', "s");

        private var _wURL:String = null;

        private var _urlLoader:URLLoader;
        private var _ajaxLoader:URLLoader;
        private var _captchaLoader:URLLoader;

        private var _counterTotal:int = 60;
        private var _timer:Timer = null;
        private var _forcedStop:Boolean = false;
        private var _ajaxURL:String = null;

        private var _counterValue:String = null;
        private var _downloadURL:String = null;
        private var _captchaNewChallenge:String = null;
        private var _recaptchaImageURL:String = null;

        private var _tm:String = null;
        private var _tmHash:String = null;

        public function Wupload(url:String):void
        {
            _wURL = url;
        }

        public function getCounterValue():String
        {
            return _counterValue;
        }

        public function getDownloadURL():String
        {
            return _downloadURL;
        }

        public function getRecaptchaImageURL():String
        {
            return _recaptchaImageURL;
        }

        public function sendRecaptchaText(txt:String):void
        {
            var urlVariables:URLVariables = new URLVariables("recaptcha_challenge_field=" + 
                                            _captchaNewChallenge + "&recaptcha_response_field=" + txt);
            trace("[Wupload] urlVariables: " + urlVariables);

            var urlReq:URLRequest = getAjaxURLRequest(_ajaxURL);
            urlReq.data = urlVariables;
            _ajaxLoader = new URLLoader();
            _ajaxLoader.load(urlReq);
            _ajaxLoader.addEventListener(Event.COMPLETE, onCaptchaResult);
        }

        private function onCaptchaResult(ev:Event):void {
            var html_:String = _ajaxLoader.data;
            readyOrCaptcha(html_);
        }

        public function start():void
        {
            var urlReq:URLRequest = new URLRequest(_wURL);
            urlReq.requestHeaders = getPageHeaders();
            _urlLoader = new URLLoader();
            _urlLoader.load(urlReq);
            _urlLoader.addEventListener(Event.COMPLETE, onPageDownloaded);
        }

        public function stop():void
        {
            _forcedStop = true;
            if (_timer != null) {
                _timer.removeEventListener(TimerEvent.TIMER_COMPLETE, loadRecaptcha);
                _timer.stop();
                trace("[Wupload] stopped counter!");
            }
            if (_urlLoader != null) {
                _urlLoader.removeEventListener(Event.COMPLETE, onPageDownloaded);
            }
        }

        private function onPageDownloaded(ev:Event):void {
            dispatchEvent(new Event(FileHost.PAGE_LOADED_EVENT));
            var html_:String = _urlLoader.data;

            var ajaxRes:Object = AJAX_URL_PATTERN.exec(html_);
            if (ajaxRes && ajaxRes[1]) {
                _ajaxURL = DOWNLOAD_URL_PREFIX + ajaxRes[1];
                var urlReq:URLRequest = getAjaxURLRequest(_ajaxURL);
                _ajaxLoader = new URLLoader();
                _ajaxLoader.load(urlReq);
                _ajaxLoader.addEventListener(Event.COMPLETE, onAjaxPageDownloaded);
            } else {
                dispatchEvent(new Event(FileHost.LINK_UNAVAILABLE_EVENT));
            }
        }

        private function onAjaxPageDownloaded(ev:Event):void {
            // Remove listener
            _ajaxLoader.removeEventListener(Event.COMPLETE, onAjaxPageDownloaded);

            var html_:String = _ajaxLoader.data;
            var countPos:int = html_.indexOf(COUNTDOWN_DELAY);
            if (countPos > -1) {
                _counterTotal = getCounterInitValue(html_) + 1;
                trace("[Wupload] has delay: " + _counterTotal);

                var tmRes:Object = TM_PATTERN.exec(html_);
                var tmHashRes:Object = TM_HASH_PATTERN.exec(html_);

                trace("[Wupload] TM: " + tmRes);
                trace("[Wupload] TM Hash: " + tmHashRes);

                if (tmRes && tmRes[1] && tmHashRes && tmHashRes[1]) {
                    _tm = tmRes[1];
                    _tmHash = tmHashRes[1];
                    trace("[Wupload] got TM data: " + _tm + ", " + _tmHash);

                    _timer = new Timer(1000, _counterTotal);
                    _timer.addEventListener(TimerEvent.TIMER, doCount);
                    _timer.addEventListener(TimerEvent.TIMER_COMPLETE, loadRecaptcha);
                    _timer.start();

                } else {
                    dispatchEvent(new Event(FileHost.LINK_UNAVAILABLE_EVENT));
                }
            } else {
                trace("[Wupload] does not have delay");
                readyOrCaptcha(html_);
            }
        }

        private function readyOrCaptcha(html_:String):void {
            // Is download ready?
            if (html_.indexOf(DOWNLOAD_READY) > -1) {
                trace("[Wupload] download is ready");
                var downRes:Object = DOWNLOAD_READY_PATTERN.exec(html_);
                if (downRes && downRes[1]) {
                    _downloadURL = downRes[1];
                    dispatchEvent(new Event(FileHost.LINK_AVAILABLE_EVENT));
                    trace("[Wupload] Video URL: " + _downloadURL);
                } else {
                    trace("[Wupload] Something went wrong. We couldn't get the download link");
                    dispatchEvent(new Event(FileHost.LINK_UNAVAILABLE_EVENT));
                }
            } else {
                var captchaRes:Object = Recaptcha.CHALLENGE_ID_PATTERN.exec(html_);
                if (captchaRes && captchaRes[1]) {
                    var captchaChallengeId:String = captchaRes[1];

                    var urlReq:URLRequest = new URLRequest(Recaptcha.CHALLENGE_URL + captchaChallengeId);
                    urlReq.requestHeaders = getCaptchaHeaders();
                    _captchaLoader = new URLLoader();
                    _captchaLoader.load(urlReq);
                    _captchaLoader.addEventListener(Event.COMPLETE, onCaptchaChallengePageDownloaded);
                } else {
                    dispatchEvent(new Event(FileHost.LINK_UNAVAILABLE_EVENT));
                }
            }
        }

        private function onCaptchaChallengePageDownloaded(ev:Event):void {
            var html_:String = _captchaLoader.data;
            //trace("[Wupload] new challenge html: " + html_);
            var captchaRes:Object = Recaptcha.NEW_CHALLENGE_PATTERN.exec(html_);
            if (captchaRes && captchaRes[1]) {
                _captchaNewChallenge = captchaRes[1];
                _recaptchaImageURL = Recaptcha.IMAGE_URL + _captchaNewChallenge;
                dispatchEvent(new Event(FileHost.RECAPTCHA_LOADED_EVENT));
            } else {
                dispatchEvent(new Event(FileHost.LINK_UNAVAILABLE_EVENT));
            }
        }

        private function getCounterInitValue(html_:String):int {
            var countPos:int = html_.indexOf(COUNTDOWN_DELAY);
            var countStartPos:int = html_.indexOf('=', countPos) + 1;
            var countEndPos:int = html_.indexOf(';', countStartPos);
            return parseInt(StringHelper.trim(html_.substr(countStartPos, countEndPos-countStartPos)));
        }
        

        private function doCount(ev:Event):void {
            _counterValue = (_counterTotal - ev.target.currentCount) + "";
            dispatchEvent(new Event(FileHost.COUNTER_CHANGED_EVENT));
        }

        private function loadRecaptcha(ev:Event):void {
            var urlVariables:URLVariables = new URLVariables("tm=" + _tm + "&tm_hash=" + _tmHash);
            trace("[Wupload] urlVariables: " + urlVariables);

            var urlReq:URLRequest = getAjaxURLRequest(_ajaxURL);
            urlReq.data = urlVariables;
            _ajaxLoader = new URLLoader();
            _ajaxLoader.load(urlReq);
            _ajaxLoader.addEventListener(Event.COMPLETE, onCaptchaPageDownloaded);
        }

        private function onCaptchaPageDownloaded(ev:Event):void {
            // Remove listener
            _ajaxLoader.removeEventListener(Event.COMPLETE, onCaptchaPageDownloaded);

            var html_:String = _ajaxLoader.data;
            readyOrCaptcha(html_);
        }

        private function getAjaxURLRequest(_url:String):URLRequest {
            var urlReq:URLRequest = new URLRequest(_url);
            urlReq.requestHeaders = getAjaxHeaders();
            urlReq.method = URLRequestMethod.POST;
            return urlReq;
        }

        private function getPageHeaders():Array {
            return new Array(
                        new URLRequestHeader("Referer", _wURL),
                        new URLRequestHeader("Origin", "http://www.wupload.com"),
                        new URLRequestHeader("Host", "www.wupload.com")
                    );
        }

        private function getAjaxHeaders():Array {
            return new Array(
                        new URLRequestHeader("Referer", _wURL),
                        new URLRequestHeader("Origin", "http://www.wupload.com"),
                        new URLRequestHeader("Host", "www.wupload.com"),
                        new URLRequestHeader("X-Requested-With", "XMLHttpRequest")
                    );
        }

        private function getCaptchaHeaders():Array
        {
            return new Array(new URLRequestHeader("Referer", _wURL));
        }

    }
}