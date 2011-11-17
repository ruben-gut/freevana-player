package freevana.view
{
    import mx.core.UIComponent;

    import flash.display.DisplayObject; 
    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.net.URLRequest;
    
    import org.flowplayer.view.*;

    public class VideoPlayer extends EventDispatcher
    {
        public static const PLAYER_INITIALIZING:String = "VideoPlayerInitializing";
        public static const PLAYER_READY:String = "VideoPlayerReady";

        private var _flowplayerAppEvent:String = "FreevanaAppLoaded";

        public var videoComponent:UIComponent = null;

        private var _preloader:Preloader = null;
        private var _flowLauncher:Launcher = null;
        private var _flowPlayer:Flowplayer = null;
        private var _movieIsLoading:Boolean = false;

        private var _movieURL:String;
        private var _subtitleURL:String;

        public function VideoPlayer(movieURL:String, subtitleURL:String):void
        {
            _movieURL = movieURL;
            _subtitleURL = subtitleURL;
        }

        public function init():void
        {
            trace("[main] loading movie...");
            // TODO: if _subtitleURL is null or empty, don't include subs configuration code

            // Build the config string
            var captionsPlugins:String = '"captions":{"url":"flowplayer.captions-3.2.3.swf","captionTarget":"content", "button":{"width":23,"height":15,"right":3,"bottom":30,"label":"Sub","opacity":0.4}}';
            var contentStyle:String = '"style":{"body":{"fontSize":"20","fontFamily":"Arial","textAlign":"center","color":"#FFFFFF"}}';
            var contentPlugins:String = '"content":{"url":"flowplayer.content-3.2.0.swf","bottom":30, "width":"90%","height":50,"backgroundColor":"transparent","backgroundGradient":"none","borderRadius":4,"border":0,"textDecoration":"outline",'+contentStyle+'}';
            var plugins:String = '"plugins":{'+captionsPlugins+','+contentPlugins+'}';
            var playerConfig:String = '{"canvas":{"backgroundGradient":"none"},"clip":{"url":"'+_movieURL+'","captionUrl":"'+_subtitleURL+'","scaling":"fit","autoPlay":true,"autoBuffering":true},'+plugins+'}'

            var swfURL:String = 'flowplayer/flowplayer-3.2.7.swf?config=' + escape(playerConfig);
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
                videoComponent = myComp;
                dispatchEvent(new Event(VideoPlayer.PLAYER_INITIALIZING));
            }

            function onPauseEv(ev:Event):void {
                trace("[VideoPlaer] onPause! " + ev.toString());
            }

            // Load video player from external SWF
            loader.load(new URLRequest(swfURL));
        }
    }
}