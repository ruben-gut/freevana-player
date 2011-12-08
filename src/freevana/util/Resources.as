package freevana.util
{
    import mx.controls.Alert;
    import mx.resources.ResourceManager;
    import mx.resources.IResourceManager;

    import flash.filesystem.File;
    import flash.net.FileFilter;
    import flash.events.Event;

    /*
    * @author tirino
    */
    [ResourceBundle("Strings")]
    public class Resources
    {
        public static var DATA_STORAGE_DIR:File = File.applicationStorageDirectory;
        public static var DATABASE_FILE_DIR:String = "db";
        public static var DATABASE_FILE_NAME:String = "freevana.db";
        public static var DATABASE_FILE_PATH:String = DATABASE_FILE_DIR + File.separator + DATABASE_FILE_NAME;

        public static var SUBTITLES_MOVIES_DIR:String = "movies";
        public static var SUBTITLES_SERIES_DIR:String = "series";

        private var _rm:IResourceManager = ResourceManager.getInstance();

        private var _dbCopyCallback:Function = null;
        private var _subsSelectCallback:Function = null;

        /**
        * Open a dialog to choose a Subtitles directory.
        * The callback function must accept a File as a parameter
        */
        public function selectSubtitlesDir(callback:Function):void
        {
            var dir:File = File.desktopDirectory;
            _subsSelectCallback = callback;
            dir.browseForDirectory(_rm.getString('Strings', 'BROWSE_FOR_SUBTITLES'));
            dir.addEventListener(Event.SELECT, selectedSubsDir);
        }

        /**
        * Check if the selected directory is valid and calls the user callback
        */
        private function selectedSubsDir(event:Event):void
        {
            var hasMovies:Boolean = false;
            var hasSeries:Boolean = false;
            var selectedDir:File = (event.target as File);
            if (selectedDir.isDirectory) {
                var dirs:Array = selectedDir.getDirectoryListing();
                for(var i:int; i<dirs.length; i++) {
                    if (dirs[i].name == SUBTITLES_MOVIES_DIR) {
                        hasMovies = true;
                    } else if (dirs[i].name == SUBTITLES_SERIES_DIR) {
                        hasSeries = true;
                    }
                }
                if (hasMovies && hasSeries) {
                    trace("[Resources] selected subs directory: " + selectedDir.nativePath);
                    if (_subsSelectCallback != null) {
                        _subsSelectCallback(selectedDir);
                    }
                } else {
                    Alert.show(_rm.getString('Strings', 'INVALID_SUBTITLES_DIR'));
                }
            }
        }

        public function checkDB():Boolean
        {
            var db:File = DATA_STORAGE_DIR.resolvePath(DATABASE_FILE_PATH);
            return db.exists;
        }

        public function copyDB(callback:Function):void
        {
            var filter_:FileFilter = new FileFilter("Database", "*.db;*.database");
            var dir:File = File.desktopDirectory;
            _dbCopyCallback = callback;
            dir.browseForOpen(_rm.getString('Strings', 'BROWSE_FOR_DB'), [filter_]);
            dir.addEventListener(Event.SELECT, doCopyDB);
            dir.addEventListener(Event.CANCEL, dbCopyCancelled);
        }

        private function doCopyDB(event:Event):void
        {
            var selectedFile:File = (event.target as File);
            var targetFile:File = DATA_STORAGE_DIR.resolvePath(DATABASE_FILE_PATH);

            trace("[Resources] " + selectedFile.nativePath + " => " + targetFile.nativePath);
            // Delete old one
            try {
                if (targetFile.exists) {
                    targetFile.deleteFile();
                }
            } catch (error:Error) {
                //Alert.show(error.message);
                trace("[Resources] Error Deleting: " + error.message);
            }
            // Copy
            try {
                selectedFile.copyTo(targetFile, true);
                if (_dbCopyCallback != null) {
                    _dbCopyCallback();
                }
            } catch (error:Error) {
                Alert.show(error.message);
                trace("[Resources] Error Copying: " + error.message);
            }
        }

        private function dbCopyCancelled(event:Event):void
        {
            Alert.show(_rm.getString('Strings', 'YOU_MUST_CHOOSE_DB'));
        }
    }
}