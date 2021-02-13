require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  
    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true
        sql = "PRAGMA table_info('#{table_name}')"
        table_info = DB[:conn].execute(sql)
        column_names = []
        table_info.each do |column|
          column_names << column["name"]
        end
        column_names.compact
    end

    def initialize(options={})
        options.each do |property, value|
            self.send("#{property}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |col_name|
          values << "'#{send(col_name)}'" unless send(col_name).nil?
        end
        values.join(", ")
    end

    def save #values_for_insert = "'1', 'Sam', '11'"
        sql = <<-SQL
        INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert})
        VALUES (#{values_for_insert})
        SQL
        DB[:conn].execute(sql)
        self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", [name])
    end

    def self.find_by(attribute) #{:name=>"Susan"}   #attribute[key1=> "Susan"
        key1 = nil
        value1 = nil
        pass = nil
        attribute.each do |key, value|
            key1 = key  # :name
            value1 = value   #"Susan"
        end
        key2 = key1.to_s.gsub(":","")  #"name"
        value2 = value1.to_s.gsub(":","")  #"Susan"
        #pass = attribute[key1]  
        #binding.pry
        if value2.is_a? Integer 
            DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE grade = ?", [value2])
        else
            DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", [value2])
        end
    end

end

# def self.find(id, db)
#     sql = "SELECT * FROM pokemon WHERE id = ?"
#     result = db.execute(sql, id)[0] #result => [1, "Pikachu", "electric"]
#     #Pokemon.new(id, result[1], result[2], db)
#     Pokemon.new(id: result[0], name: result[1], type: result[2], db: db)
# end