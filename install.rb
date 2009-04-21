require 'ftools'

  # Insert code into a file
  # The proc is called when it is time to insert data
  # The proc should return an array which will be inserted into the file
def self.insert_code( filename, search, first_line = [], comment = false, &e )
    #Quit if our params aren't valid
  return false if filename.nil? or e.nil? or !File.exists?( filename )

    #Create my local variables
  output = Array.new(first_line)
  state = :search
  sp = ''
  tv = ''

    #Read in all the data of this file
  File.open(filename).readlines.each do |line|
    case state
    when :search        #Search for the create table call
      if line =~ /^=begin/
        state = :comment_block
      elsif ((comment)? line: line.sub(/#.*/,'')) =~ /#{search}/
        state = :insert
        sp = line.sub(/#{search}.*/, '  ').chomp
        tv = line.sub(/.*\|[\t ]*([a-zA-Z0-9_]+).*/, '\1').chomp
      end
    when :comment_block #Skip over a comment block
      state = :search if line =~ /^=end/
    when :insert        #Insert my fields into this baby
      e.call( sp, tv ).each {|ul| output.push( ul )}
      state = :done
    else                #Likely in the done case
    end

      #Always keep the original contents
    output.push(line)
  end

    #Write the migration back out, updated with the new fields
  file = File.open(filename, 'w')
  output.each {|line| file.puts line}
  file.close

  return true
end

# Install hook code here
File.copy(File.join(File.dirname(__FILE__), 'lib', 'restless_variables.rb'),
          File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'restless_variables.rb'))
File.copy(File.join(File.dirname(__FILE__), 'lib', 'restless_hash.rb'),
          File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'restless_hash.rb'))


  #Now open up my main controller and add in the filter
output = Array.new

output.push("  #--Inserted by Restless Variables")
output.push("require 'restless_variables'")
output.push("  #--End insert")
output.push( '' )

  #Insert my restless variables
filename ="#{File.dirname(__FILE__)}/../../../app/controllers/application_controller.rb"
match = "class ApplicationController"
insert_code( filename, match, output ) { |sp, tv|
  output = Array.new

    #Insert my code
  output.push("#{sp}  #--Inserted by Restless Variables")
  output.push("#{sp}include RestlessVariables")
  output.push('')
  output.push("#{sp}around_filter :restless_variable_filter")
  output.push("#{sp}  #--End insert")
}
