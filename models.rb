if :development
  ActiveRecord::Base.establish_connection("sqlite3:db/development.db")
end
if :production
  ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
end

class Post < ActiveRecord::Base
end