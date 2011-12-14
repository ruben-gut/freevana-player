package freevana.view
{
    /*
    * @author tirino
    */
    
    import freevana.util.Settings;

    public class VideoPlayer
    {
        public static const SUBTITLES_SMALL:String = 'SMALL';
        public static const SUBTITLES_NORMAL:String = 'NORMAL';
        public static const SUBTITLES_BIG:String = 'BIG';

        public static const VIDEO_PLAYER_OWN:String = 'OWN';
        public static const VIDEO_PLAYER_FLOW:String = 'FLOW';

        public static const PLAYER_INITIALIZING:String = "VideoPlayerInitializing";
        public static const PLAYER_READY:String = "VideoPlayerReady";
        public static const PLAYER_STOPPED:String = "VideoPlayerStopped";
        public static const VIDEO_NOT_AVAILABLE:String = "VideoNotAvailable";

        public static function create(settings:Settings, movieURL:String, subsURL:String):IVideoPlayer
        {
            if (settings.getPreferredPlayer() == VIDEO_PLAYER_FLOW) {
                return new FlowVideoPlayer(movieURL, subsURL);
            } else {
                return new FlashVideoPlayer(movieURL, subsURL);
            }
        }
    }
}