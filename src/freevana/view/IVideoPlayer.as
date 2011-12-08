package freevana.view
{
    import flash.events.IEventDispatcher;
    import mx.core.UIComponent;

    /*
    * @author tirino
    */
    public interface IVideoPlayer extends IEventDispatcher
    {
        function setMovieURL(movieURL:String):void;
        function setSubtitleURL(subtitleURL:String):void;
        function setSubtitleSize(subsSize:String):void;
        function getUIComponent():UIComponent;
        function init():void;
        function onAddedToStage():void;
    }
}