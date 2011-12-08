package freevana.util
{
    //import mx.controls.Alert;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.TimerEvent;

    import flash.net.URLRequest;
    import flash.net.URLLoader;
    import flash.utils.Timer;

    //import flash.html.HTMLLoader;

    /*
    * @author tirino
    */
    public class Megaupload extends EventDispatcher
    {
        public static var PAGE_LOADED_EVENT:String = "PageLoadedEvent";
        public static var COUNTER_CHANGED_EVENT:String = "CounterChangedEvent";
        public static var LINK_AVAILABLE_EVENT:String = "LinkAvailableEvent";
        public static var LINK_UNAVAILABLE_EVENT:String = "LinkUnavailableEvent";

        private var _megaURL:String = null;

        private var _urlLoader:URLLoader;
        private var _counterTotal:int = 60;
        private var _timer:Timer = null;
        private var _forcedStop:Boolean = false;
        public var _privateDownloadURL:String = null;

        public var downloadURL:String = null;
        public var counterValue:String = null;

        // Old, unused variables
        /*
        private var DEFAULT_TIMER_IVAL:int = 120;
        private var _htmlLoader:HTMLLoader;
        private var _countDown:Object = null;
        private var _stopOnNext:Boolean = false;
        */
    
        public function Megaupload(url:String):void 
        {
            _megaURL = url;
        }

        public function start():void
        {
            _forcedStop = false;
            _urlLoader = new URLLoader();
            _urlLoader.load(new URLRequest(_megaURL));
            _urlLoader.addEventListener(Event.COMPLETE, onPageDownloaded);
        }

        public function stop():void
        {
            _forcedStop = true;
            if (_timer != null) {
                _timer.removeEventListener(TimerEvent.TIMER_COMPLETE, doFinishCount);
                _timer.stop();
                trace("[Megaupload] stopped counter!");
            }
        }

        private function onPageDownloaded(ev:Event):void {
            dispatchEvent(new Event(PAGE_LOADED_EVENT));

            var html_:String = _urlLoader.data;
            _counterTotal = getCounterInitValue(html_) + 1; // one more second, just in case
            _privateDownloadURL = getDownloadLink(html_);

            if (_privateDownloadURL && _counterTotal && !_forcedStop) {
                _timer = new Timer(1000, _counterTotal);
                _timer.addEventListener(TimerEvent.TIMER, doCount);
                _timer.addEventListener(TimerEvent.TIMER_COMPLETE, doFinishCount);
                _timer.start();
            } else {
                dispatchEvent(new Event(LINK_UNAVAILABLE_EVENT));
                //Alert.show("Could not get file data on Megaupload!");
            }
        }

        private function doCount(ev:Event):void {
            counterValue = (_counterTotal - ev.target.currentCount) + "";
            dispatchEvent(new Event(COUNTER_CHANGED_EVENT));
        }

        private function doFinishCount(ev:Event):void {
            downloadURL = _privateDownloadURL;
            dispatchEvent(new Event(LINK_AVAILABLE_EVENT));
            trace("[Megaupload] Video URL: " + downloadURL);
        }

        private function getDownloadLink(_html:String):String
        {
            var idPos:int = _html.indexOf('id="downloadlink"');
            if (idPos > 0) {
                var hrefPos:int = _html.indexOf('href', idPos); // make sure we're in the <a> link
                var linkStartPos:int = _html.indexOf('http://', hrefPos); // now look for http://
                var linkEndPos:int = _html.indexOf('"', linkStartPos);
                return _html.substr(linkStartPos, linkEndPos-linkStartPos);
            } else {
                return null;
            }
        }

        private function getCounterInitValue(_html:String):int
        {
            var scriptTag:String = '<script type="text/javascript">';
            var countEndPos:int = _html.indexOf('function countdown('); // 'count' is just before this
            // now get the <script> tag right before countdown function
            var scriptPos:int = _html.lastIndexOf(scriptTag, countEndPos);
            var countStartPos:int = scriptPos + scriptTag.length;
            // get the content between script and function countdown() and trim it.
            var counterValue:String = StringHelper.trim(_html.substr(countStartPos, countEndPos-countStartPos));
            counterValue = counterValue.replace(/count=/,''); // replace variable name
            counterValue = counterValue.replace(/;/,''); // remove semi-colon
            return parseInt(counterValue);
        }

        /* Old (slow) way of handling Megaupload starts here */
        /*
        public function old_start():void
        {
            trace("[Megaupload] Loading: " + _megaURL);
            _htmlLoader = new HTMLLoader();
            _htmlLoader.width = 10;
            _htmlLoader.height = 10;
            //_htmlLoader.addEventListener(Event.HTML_DOM_INITIALIZE, onComplete);
            _htmlLoader.addEventListener(Event.COMPLETE, _onPageComplete);
            _htmlLoader.addEventListener(Event.HTML_RENDER, function (ev:Event):void {
                trace("[Megaupload] HTML_RENDER");
                trace("[Megaupload] >> downloadlink: " + _htmlLoader.window.document.getElementById("downloadlink"));
                trace("[Megaupload] >> countdown: " + _htmlLoader.window.document.getElementById("countdown"));
            });
            _htmlLoader.load(new URLRequest(_megaURL));
        }

        private function _onPageComplete(ev:Event):void
        {
            dispatchEvent(new Event(PAGE_LOADED_EVENT));

            trace("[Megaupload] onComplete!");
            var downLink:Object = _htmlLoader.window.document.getElementById("downloadlink");
            if (downLink && downLink.hasChildNodes()) {
                for(var i:int=0; i < downLink.childNodes.length; i++) {
                    downloadURL = downLink.childNodes[i].href;
                    break;
                }
            } else {
                Alert.show("Error: could not get download link!");
            }
        
            _countDown = _htmlLoader.window.document.getElementById("countdown");
            if (_countDown) {
                var count:String = _countDown.innerHTML;
                var timer:Timer = new Timer(1000, DEFAULT_TIMER_IVAL * 1000);
                timer.addEventListener(TimerEvent.TIMER, _timerHandler);
                timer.start();
            } else {
                Alert.show("Error: couldt not get countDown ID!");
            }
        }

        private function _timerHandler(ev:TimerEvent):void
        {
            var timer:Timer = Timer(ev.target);
            if (_stopOnNext) {
                trace("[Megaupload] Finished counter!");
                timer.stop();
                _stopOnNext = false;
                dispatchEvent(new Event(LINK_AVAILABLE_EVENT));
                trace("[Megaupload] Movie is here: " + downloadURL);
            } else {
                counterValue = _countDown.innerHTML;
                dispatchEvent(new Event(COUNTER_CHANGED_EVENT));
                if (counterValue == "1") {
                    trace("[Megaupload] Will stop on next iteration!");
                    _stopOnNext = true;
                }
            }
        }
        */
    }
}