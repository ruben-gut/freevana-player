package freevana.util
{
    import flash.data.SQLConnection;
    import flash.data.SQLStatement;
    import flash.filesystem.File;

    public class FreevanaDB
    {
        private var _sqlConn:SQLConnection = new SQLConnection();
        private var _dbFile:File;
        private var _dbVersionNumber:String;

        public function FreevanaDB(dbFile:String):void
        {
            _dbFile = File.applicationStorageDirectory.resolvePath(dbFile);
            trace("[FreevanaDB] dbFile: " + _dbFile.nativePath);
            _sqlConn.open(_dbFile);
            _dbVersionNumber = getVersionNumber();
        }

        public function runQuery(query:String):Array
        {
            var statement:SQLStatement = new SQLStatement();
            statement.sqlConnection = _sqlConn;
            statement.text = query;
            statement.execute();
            return statement.getResult().data;
        }

        public function getVersionNumber():String
        {
            var version_:String = "";
            var versionQuery:String = "SELECT CAST(version AS TEXT) AS vers FROM database_version WHERE id = 1";
            var res:Array = runQuery(versionQuery);
            if (res.length > 0) {
                version_ = res[0].vers;
            }
            return version_;
        }
        public function getVersionName():String
        {
            var version_:String = "";
            var versionQuery:String = "SELECT ('v' || CAST(version AS TEXT) || ' ' || release_date)"
            versionQuery += " AS vers FROM database_version WHERE id = 1";
            var res:Array = runQuery(versionQuery);
            if (res.length > 0) {
                version_ = res[0].vers;
            }
            return version_;
        }

        public function getMovies():Array
        {
            var moviesQuery:String;
            if (_dbVersionNumber == "1.0") {
                moviesQuery = "SELECT m.*, src.url FROM movies m INNER JOIN movie_sources src " +
                            "ON (src.movie_id=m.id AND src.source = 'megaupload') ORDER BY m.name";
            } else {
                moviesQuery = "SELECT m.*, (m.name || ' [' || src.definition || 'p]') AS name, src.url " +
                            "FROM movies m INNER JOIN movie_sources src " +
                            "ON (src.movie_id=m.id AND src.source = 'megaupload') ORDER BY m.name";
            }
            return runQuery(moviesQuery);
        }

        public function getSeries():Array
        {
            var seriesQuery:String = "SELECT s.* FROM series s ORDER BY s.name";
            return runQuery(seriesQuery);
        }

        public function getSeasons(seriesId:int):Array
        {
            var seasonsQuery:String = "SELECT * FROM series_seasons WHERE series_id="+seriesId+" ORDER BY number";
            return runQuery(seasonsQuery);
        }

        public function getEpisodes(seasonId:int):Array
        {
            // We need to CAST e.number as INTEGER when sorting as it is actually a
            // TEXT column, because some episode numbers can be in the format: 20-21
            var episodesQuery:String;
            if (_dbVersionNumber == "1.0") {
                episodesQuery = "SELECT e.*, (e.number || ') ' || e.short_name) as name, src.url " +
                                        "FROM series_episodes e INNER JOIN series_episode_sources src " + 
                                        "ON (src.series_episode_id = e.id AND src.source ='megaupload') " +
                                        "WHERE e.season_id="+seasonId+" ORDER BY CAST(e.number AS INTEGER)";
            } else {
                episodesQuery = "SELECT e.*, (e.number || ') ' || e.name || ' [' || src.definition || 'p]') as name, src.url " +
                                        "FROM series_episodes e INNER JOIN series_episode_sources src " + 
                                        "ON (src.series_episode_id = e.id AND src.source ='megaupload') " +
                                        "WHERE e.season_id="+seasonId+" ORDER BY CAST(e.number AS INTEGER)";
            }
            return runQuery(episodesQuery);
        }
    }
}