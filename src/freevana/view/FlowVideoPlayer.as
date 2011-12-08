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
    public class FlowVideoPlayer extends EventDispatcher implements IVideoPlayer
    {
        public static const SUBTITLES_SMALL:String = 'SMALL';
        public static const SUBTITLES_NORMAL:String = 'NORMAL';
        public static const SUBTITLES_BIG:String = 'BIG';
        
        public static const PLAYER_INITIALIZING:String = "VideoPlayerInitializing";
        public static const PLAYER_READY:String = "VideoPlayerReady";

        private var _flowplayerAppEvent:String = "FreevanaAppLoaded";

        private var _videoComponent:UIComponent = null;

        private var _preloader:Preloader = null;
        private var _flowLauncher:Launcher = null;
        private var _flowPlayer:Flowplayer = null;
        private var _movieIsLoading:Boolean = false;

        private var _movieURL:String;
        private var _subtitleURL:String;

        private var _subtitleSize:int = 20;
        private var _subtitleBoxSize:int = 50;

        public function FlowVideoPlayer(movieURL:String, subtitleURL:String):void
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
            if (subsSize == SUBTITLES_SMALL) {
                _subtitleSize = 16;
                _subtitleBoxSize = 46;
            } else if (subsSize == SUBTITLES_BIG) {
                _subtitleSize = 24;
                _subtitleBoxSize = 60;
            }
        }

        public function getUIComponent():UIComponent
        {
            return _videoComponent;
        }

        public function init():void
        {
            trace("[main] loading movie...");
            // TODO: if _subtitleURL is null or empty, don't include subs configuration code

            // Build the config string
            // TODO: work-around for Linux bug
            var captionsOpacity:String = '0.4';
            if (Utils.isLinux()) {
                captionsOpacity = '0.0';
            }

            var captionsPlugins:String = '"captions":{"url":"flowplayer.captions-3.2.3.swf","captionTarget":"content", "button":{"width":23,"height":15,"right":5,"bottom":30,"label":"Sub","opacity":'+captionsOpacity+'}}';
            var contentStyle:String = '"style":{"body":{"fontSize":"'+_subtitleSize+'","fontFamily":"Arial","textAlign":"center","color":"#FFFFFF"}}';
            var contentPlugins:String = '"content":{"url":"flowplayer.content-3.2.0.swf","opacity":1.0,"bottom":30, "width":"90%","height":'+_subtitleBoxSize+',"backgroundColor":"transparent","backgroundGradient":"none","borderRadius":4,"border":0,"textDecoration":"outline",'+contentStyle+'}';
            var plugins:String = '"plugins":{'+captionsPlugins+','+contentPlugins+'}';
            var playerConfig:String;

            if (_subtitleURL && _subtitleURL != '') {
                playerConfig = '{"canvas":{"backgroundGradient":"none"},"clip":{"url":"'+_movieURL+'","captionUrl":"'+_subtitleURL+'","scaling":"fit","autoPlay":true,"autoBuffering":true},'+plugins+'}'
            } else {
                playerConfig = '{"canvas":{"backgroundGradient":"none"},"clip":{"url":"'+_movieURL+'","scaling":"fit","autoPlay":true,"autoBuffering":true},'+plugins+'}'
            }

            var swfURL:String = 'videoplayers/flowplayer-3.2.7.swf?config=' + escape(playerConfig);
            trace(playerConfig);

            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.INIT, handleInit);

            function handleInit(event:Event):void {
                _preloader = event.target.loader.content;
                if (_preloader.getAppObject()) {
                    _flowLauncher = (_preloader.getAppObject() as Launcher);
                    _flowPlayer = _flowLauncher.getFlowplayer();

                    _flowPlayer.config.getPlaylist().onError(function(ev:*):void {
                        trace("[onError!] " + ev.toString());
                    });

                    dispatchEvent(new Event(VideoPlayer.PLAYER_READY));
                } else {
                    _preloader.addEventListener(_flowplayerAppEvent, handleFreevanaAppLoaded);
                    function handleFreevanaAppLoaded(ev:Event):void {
                        _flowLauncher = (_preloader.getAppObject() as Launcher);
                        _flowPlayer = _flowLauncher.getFlowplayer();

                        _flowPlayer.config.getPlaylist().onError(function(ev:*):void {
                            trace("[onError!] " + ev.toString());
                        });
                        dispatchEvent(new Event(VideoPlayer.PLAYER_READY));
                    }
                }

                var myComp:UIComponent = new UIComponent();
                myComp.addChild(event.target.loader.content);
                _videoComponent = myComp;
                dispatchEvent(new Event(VideoPlayer.PLAYER_INITIALIZING));
            }

            function onPauseEv(ev:Event):void {
                trace("[VideoPlaer] onPause! " + ev.toString());
            }

            // Load video player from external SWF
            loader.load(new URLRequest(swfURL));
        }

        public function onAddedToStage():void {
            // nothing
        }
    }
}