package freevana.util
{
    import flash.net.SharedObject;
    import flash.filesystem.File;
    import flash.system.Capabilities;

    public class Settings
    {
        private static var SHARED_OBJECT_NAME:String = "Settings";
        private static var SETUP_COMPLETED_KEY:String = "setup_completed";
        private static var PREFERRED_LANG_KEY:String = "preferred_lang";
        private static var SUBTITLES_DIR_KEY:String = "subtitles_dir";

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
                    trace("[Settings] " + error.message);
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