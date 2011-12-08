package freevana.view
{
    import mx.core.UIComponent;

    import flash.display.DisplayObject; 
    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.net.URLRequest;

    import freevana.util.Utils;
    import org.flowplayer.view.*;

    /*
    * @author tirino
    */
    public class FlashVideoPlayer extends EventDispatcher implements IVideoPlayer
    {
        private static const STOPPED_MOVIE:String = "STOPPED_MOVIE";
        private static const VIDEO_NOT_AVAILABLE:String = "VIDEO_NOT_AVAILABLE";

        private var _originalPlayer:* = null;
        private var _videoComponent:UIComponent = null;

        private var _preloader:Preloader = null;
        private var _flowLauncher:Launcher = null;
        private var _flowPlayer:Flowplayer = null;
        private var _movieIsLoading:Boolean = false;

        private var _movieURL:String;
        private var _subtitleURL:String;

        private var _subtitleSize:String = "normal";

        public function FlashVideoPlayer(movieURL:String, subtitleURL:String):void
        {
            setMovieURL(movieURL);
            setSubtitleURL(subtitleURL);
        }

        public function setMovieURL(movieURL:String):void
        {
            _movieURL = movieURL;
        }

        public function setSubtitleURL(subtitleURL:String):void
        {
            _subtitleURL = subtitleURL;
        }

        public function setSubtitleSize(subsSize:String):void
        {
            if (subsSize == VideoPlayer.SUBTITLES_SMALL) {
                _subtitleSize = "small";
            } else if (subsSize == VideoPlayer.SUBTITLES_BIG) {
                _subtitleSize = "big";
            }
        }

        public function getUIComponent():UIComponent
        {
            return _videoComponent;
        }

        public function init():void
        {
            trace("[main] loading movie...");
            var swfURL:String = 'videoplayers/FlashVideoPlayer.swf?video=' + escape(_movieURL) + '&subtitle=' + escape(_subtitleURL) + '&subtitleSize=' + escape(_subtitleSize);
            trace(swfURL);

            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.INIT, handleInit);

            function handleInit(event:Event):void {
                _originalPlayer = event.target.loader.content;
                var myComp:UIComponent = new UIComponent();
                myComp.addChild(event.target.loader.content);
                _videoComponent = myComp;
                dispatchEvent(new Event(VideoPlayer.PLAYER_INITIALIZING));
                _originalPlayer.addEventListener(STOPPED_MOVIE, onStoppedMovie);
                _originalPlayer.addEventListener(VIDEO_NOT_AVAILABLE, onVideoNotFound);
            }

            function onStoppedMovie(ev:Event):void {
                dispatchEvent(new Event(VideoPlayer.PLAYER_STOPPED));
            }

            function onVideoNotFound(ev:Event):void {
                dispatchEvent(new Event(VideoPlayer.VIDEO_NOT_AVAILABLE));
            }

            function onPauseEv(ev:Event):void {
                trace("[VideoPlaer] onPause! " + ev.toString());
            }

            // Load video player from external SWF
            loader.load(new URLRequest(swfURL));
        }
 
 
        public function onAddedToStage():void {
            trace("[flashvideoplayer] " + _originalPlayer);
            _originalPlayer.init();
            dispatchEvent(new Event(VideoPlayer.PLAYER_READY));
        }
    }
}