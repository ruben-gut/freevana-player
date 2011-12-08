package freevana.util
{
    // TODO: only import what we actually use
    import flash.net.*;
    import flash.filesystem.*;
    import flash.events.*;
    import flash.utils.ByteArray;

    /*
    * @author tirino
    */
    public class Subtitles
    {
        private static var MOVIES_SUBTITLES_BASEURL:String = 'http://sc.cuevana.tv/files/sub/';
        private static var SERIES_SUBTITLES_BASEURL:String = 'http://sc.cuevana.tv/files/s/sub/';
        private static var SUBTITLES_DIR:String = "subtitles";
        private var _settings:Settings;

        public function Subtitles()
        {
            _settings = new Settings();
        }

        /**
        *
        */
        public function getSubtitlesPathForVideo(itemId:int, isMovie:Boolean, lang:String, callback:Function):void
        {
            var storageFile:File = buildLocalStoragePathForSubs(itemId, isMovie, lang);
            if (storageFile != null && storageFile.exists) { // subs are in the storage dir
                trace("[Subtitles] found storage file");
                callback(storageFile);
            } else {
                var subsDirFile:File = buildSubsDirPathForSubs(itemId, isMovie, lang);
                 // subs are in user's subs dir, copy them to the storage folder and use that one
                if (subsDirFile != null && subsDirFile.exists && subsDirFile.copyTo(storageFile, true)) {
                    trace("[Subtitles] found user's subs file, copied to storage file");
                    callback(storageFile);
                } else { // get them from the internet
                    var subsURL:String = (isMovie) ? MOVIES_SUBTITLES_BASEURL : SERIES_SUBTITLES_BASEURL;
                    subsURL += buildSubsFilename(itemId, lang);
                    trace("[Subtitles] will attempt to download from server: " + subsURL);
                    downloadFileFromServer(subsURL, storageFile, callback);
                }
            }
        }

        private function downloadFileFromServer(url_:String, toFile:File, callback:Function):void
        {
            var req:URLRequest = new URLRequest(url_);
            var stream:URLStream = new URLStream();
            var finished:Boolean = false;
            stream.addEventListener(Event.COMPLETE, handleResult);
            stream.addEventListener(Event.CANCEL, handleResult);
            stream.addEventListener(Event.SELECT, handleResult);
            stream.addEventListener(HTTPStatusEvent.HTTP_STATUS, handleResult);
            stream.addEventListener(IOErrorEvent.IO_ERROR, handleResult);
            stream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleResult);

            function handleResult(event:Event):void
            {
                if (event.type == Event.COMPLETE) {
                    var fileData:ByteArray = new ByteArray();
                    stream.readBytes(fileData, 0, stream.bytesAvailable);
                    var fileStream:FileStream = new FileStream();
                    fileStream.open(toFile, FileMode.WRITE);
                    fileStream.writeBytes(fileData, 0, fileData.length);
                    fileStream.close();
                    trace("[Subtitles] Finished downloading subs: " + event);
                    callback(toFile);
                } else if (event.type == IOErrorEvent.IO_ERROR || 
                        event.type == Event.CANCEL || 
                        event.type == SecurityErrorEvent.SECURITY_ERROR) {
                    trace("[Subtitles] download > Event error: " + event);
                    callback(toFile);
                } else {
                    // for debugging purposes
                    trace("[Subtitles] download > event: " + event);
                }
            }
            stream.load(req);
        }

        private function buildSubsDirPathForSubs(itemId:int, isMovie:Boolean, lang:String):File
        {
            var subsFile:File = null;
            var subsDir:File = _settings.getSubtitlesDir();
            if (subsDir != null && subsDir.exists) {
                subsFile = buildPathForSubs(subsDir, itemId, isMovie, lang);
            }
            return subsFile;
        }

        private function buildLocalStoragePathForSubs(itemId:int, isMovie:Boolean, lang:String):File
        {
            return buildPathForSubs(Resources.DATA_STORAGE_DIR, itemId, isMovie, lang);
        }

        private function buildPathForSubs(baseFolder:File, itemId:int, isMovie:Boolean, lang:String):File
        {
            var typePath:String = (isMovie) ? Resources.SUBTITLES_MOVIES_DIR : Resources.SUBTITLES_SERIES_DIR;
            var tempPath:String = SUBTITLES_DIR + File.separator + typePath + File.separator + lang.toUpperCase();
            tempPath += File.separator + buildSubsFilename(itemId, lang);
            var subsFile:File = baseFolder.resolvePath(tempPath);
            //trace("[Subtitles] URL: " + subsFile.url);
            return subsFile;
        }

        private function buildSubsFilename(itemId:int, lang:String):String
        {
            return itemId + "_" + lang + ".srt";
        }
    }
}