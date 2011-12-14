package freevana.download
{
    //import mx.controls.Alert;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.TimerEvent;

    import flash.net.URLRequest;
    import flash.net.URLLoader;
    import flash.utils.Timer;

    import freevana.util.StringHelper;
    //import flash.html.HTMLLoader;

    /*
    * @author tirino
    */
    public class Megaupload extends EventDispatcher implements IFileHost
    {
        private static const MEGAUPLOAD_SONG_URL:String = 'http://cdn.megaupload.com/file.mp4';
        
        private var _megaURL:String = null;

        private var _urlLoader:URLLoader;
        private var _counterTotal:int = 60;
        private var _timer:Timer = null;
        private var _forcedStop:Boolean = false;
        private var _private_downloadURL:String = null;

        private var _counterValue:String = null;
        private var _downloadURL:String = null;

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
            return "";
        }

        public function sendRecaptchaText(txt:String):void
        {
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
            if (_urlLoader != null) {
                _urlLoader.removeEventListener(Event.COMPLETE, onPageDownloaded);
            }
        }

        private function onPageDownloaded(ev:Event):void {
            dispatchEvent(new Event(FileHost.PAGE_LOADED_EVENT));

            var html_:String = _urlLoader.data;
            _counterTotal = getCounterInitValue(html_) + 1; // one more second, just in case
            _private_downloadURL = getDownloadLink(html_);

            if (_private_downloadURL && _private_downloadURL != MEGAUPLOAD_SONG_URL && 
                _counterTotal && !_forcedStop) {
                _timer = new Timer(1000, _counterTotal);
                _timer.addEventListener(TimerEvent.TIMER, doCount);
                _timer.addEventListener(TimerEvent.TIMER_COMPLETE, doFinishCount);
                _timer.start();
            } else {
                dispatchEvent(new Event(FileHost.LINK_UNAVAILABLE_EVENT));
                //Alert.show("Could not get file data on Megaupload!");
            }
        }

        private function doCount(ev:Event):void {
            _counterValue = (_counterTotal - ev.target.currentCount) + "";
            dispatchEvent(new Event(FileHost.COUNTER_CHANGED_EVENT));
        }

        private function doFinishCount(ev:Event):void {
            _downloadURL = _private_downloadURL;
            dispatchEvent(new Event(FileHost.LINK_AVAILABLE_EVENT));
            trace("[Megaupload] Video URL: " + _downloadURL);
        }

        private function getDownloadLink(_html:String):String
        {
            var idPos:int = _html.indexOf('id="dlbuttondisabled"');
            if (idPos > 0) {
                var hrefPos:int = _html.indexOf('href', idPos); // make sure we're in the <a> link
                var linkStartPos:int = _html.indexOf('http://', hrefPos); // now look for http://
                var linkEndPos:int = _html.indexOf('"', linkStartPos);
                return _html.substr(linkStartPos, linkEndPos-linkStartPos);
            } else {
                return null;
            }
        }

        private function getCounterInitValue(html_:String):int
        {
            var scriptTag:String = '<script type="text/javascript">';
            var countEndPos:int = html_.indexOf('function countdown('); // 'count' is just before this
            // now get the <script> tag right before countdown function
            var scriptPos:int = html_.lastIndexOf(scriptTag, countEndPos);
            var countStartPos:int = scriptPos + scriptTag.length;
            // get the content between script and function countdown() and trim it.
            var counterValue:String = StringHelper.trim(html_.substr(countStartPos, countEndPos-countStartPos));
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
            dispatchEvent(new Event(FileHost.PAGE_LOADED_EVENT));

            trace("[Megaupload] onComplete!");
            var downLink:Object = _htmlLoader.window.document.getElementById("downloadlink");
            if (downLink && downLink.hasChildNodes()) {
                for(var i:int=0; i < downLink.childNodes.length; i++) {
                    _downloadURL = downLink.childNodes[i].href;
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
                dispatchEvent(new Event(FileHost.LINK_AVAILABLE_EVENT));
                trace("[Megaupload] Movie is here: " + _downloadURL);
            } else {
                _counterValue = _countDown.innerHTML;
                dispatchEvent(new Event(FileHost.COUNTER_CHANGED_EVENT));
                if (_counterValue == "1") {
                    trace("[Megaupload] Will stop on next iteration!");
                    _stopOnNext = true;
                }
            }
        }
        */
    }
}