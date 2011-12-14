package freevana.download
{
    import flash.events.IEventDispatcher;
    /*
    * @author tirino
    */
    public interface IFileHost extends IEventDispatcher
    {
        function getCounterValue():String;
        function getDownloadURL():String;
        function getRecaptchaImageURL():String;
        function sendRecaptchaText(txt:String):void;
        function start():void;
        function stop():void;

    }
}