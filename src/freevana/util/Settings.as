package freevana.util
{
    import flash.net.SharedObject;
    import flash.filesystem.File;
    import flash.system.Capabilities;
    import freevana.view.VideoPlayer;

    public class Settings
    {
        private static var SHARED_OBJECT_NAME:String = "Settings";
        private static var SETUP_COMPLETED_KEY:String = "setup_completed";
        private static var PREFERRED_LANG_KEY:String = "preferred_lang";
        private static var SUBTITLES_SIZE_KEY:String = "subtitles_size";
        private static var SUBTITLES_DIR_KEY:String = "subtitles_dir";
        private static var LAST_UPDATE_CHECK:String = "last_update_check";
        private static var LAST_UPDATE_SHOWN:String = "last_update_shown";
        private static var LAST_DB_UPDATE_SHOWN:String = "last_db_update_shown";

        private var sharedObj:SharedObject;

        public function Settings():void
        {
            sharedObj = SharedObject.getLocal(SHARED_OBJECT_NAME);
        }

        /**
        * Tell if the user has enough data to use Freevana Player
        */
        public function isSetupCompleted():Boolean
        {
            var res:Object = this.getValue(SETUP_COMPLETED_KEY);
            return (res && res === true);
        }

        /**
        * Save a flag to know this user has enough data to use Freevana Player
        */
        public function markSetupCompleted():void
        {
            this.setValue(SETUP_COMPLETED_KEY, true);
        }

        /**
        * Return the preferred language set by the user, or the default one
        * according to their system settings
        */
        public function getPreferredLanguage():String
        {
            var res:String = String(this.getValue(PREFERRED_LANG_KEY));
            if (!res) {
                var langs:Array = Capabilities.languages;
                res = (langs[0] as String).toUpperCase();
            }
            return res;
        }

        /**
        * Save the preferred language for the user
        */
        public function setPreferredLanguage(lang:String):void
        {
            this.setValue(PREFERRED_LANG_KEY, lang.toUpperCase());
        }

        /**
        * Return the select subtitles size
        */
        public function getSubtitlesSize():String
        {
            var res:String = String(this.getValue(SUBTITLES_SIZE_KEY));
            if (!res) {
                res = VideoPlayer.SUBTITLES_NORMAL;
            }
            return res;
        }

        /**
        * Save the selected subtitles size
        */
        public function setSubtitlesSize(subsSize:String):void
        {
            this.setValue(SUBTITLES_SIZE_KEY, subsSize.toUpperCase());
        }

        /**
        * Return when we last checked for updates
        */
        public function getLastUpdateCheck():Number
        {
            var res:int = int(this.getValue(LAST_UPDATE_CHECK));
            if (!res) {
                res = 0;
            }
            return res;
        }

        /**
        * Set when we last checked for updates
        */
        public function setLastUpdateCheck(updateCheck:Number):void
        {
            this.setValue(LAST_UPDATE_CHECK, updateCheck);
        }

        /**
        * Return the last update number that was shown to the user
        */
        public function getLastUpdateShown():String
        {
            var res:String = String(this.getValue(LAST_UPDATE_SHOWN));
            if (!res) {
                res = '';
            }
            return res;
        }

        /**
        * Set the update number that was last shown to the user
        */
        public function setLastUpdateShown(updateVersion:String):void
        {
            this.setValue(LAST_UPDATE_SHOWN, updateVersion);
        }

        /**
        * Return the last update number that was shown to the user
        */
        public function getLastDBUpdateShown():String
        {
            var res:String = String(this.getValue(LAST_DB_UPDATE_SHOWN));
            if (!res) {
                res = '';
            }
            return res;
        }

        /**
        * Set the update number that was last shown to the user
        */
        public function setLastDBUpdateShown(updateVersion:String):void
        {
            this.setValue(LAST_DB_UPDATE_SHOWN, updateVersion);
        }

        /**
        * Return the preferred language set by the user, or the default one
        * according to their system settings
        */
        public function getSubtitlesDir():File
        {
            var dir:File = null;
            var res:String = String(this.getValue(SUBTITLES_DIR_KEY));
            if (res != null) {
                try {
                    dir = new File(res);
                } catch (error:Error) {
                    trace("[Settings] getSubtitlesDir " + error.message);
                }
                // Make sure the dir still exists
                if (dir != null && !dir.exists) {
                    dir = null;
                    this.setSubtitlesDir(null);
                }
            }
            return dir;
        }

        /**
        * Save the preferred language for the user
        */
        public function setSubtitlesDir(dir:File):void
        {
            if (dir != null && dir.exists) {
                this.setValue(SUBTITLES_DIR_KEY, dir.nativePath);
            } else {
                this.setValue(SUBTITLES_DIR_KEY, null);
            }
        }

        private function setValue(key:String, val:Object):void
        {
            sharedObj.setProperty(key, val);
            sharedObj.flush();
        }

        private function getValue(key:String):Object
        {
            var res:Object = null;
            if (sharedObj.size > 0 && typeof sharedObj.data[key] != "undefined")
            {
                res = sharedObj.data[key];
            }
            return res;
        }
    }
}