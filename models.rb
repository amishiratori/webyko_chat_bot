ActiveRecord::Base.establish_connection(ENV['DATABASE_URL']||"sqlite3:db/development.db")


class Post < ActiveRecord::Base
end

class Announcement < ActiveRecord::Base
end