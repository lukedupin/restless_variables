require 'restless_hash'

	#These are the methods that are used by the user and the plug in
module RestlessVariables
	####################
	# Instance Methods #
	####################
		#Load up the user's pretty variables
	def load_variables( params, sessions, cookies )
			#Turn all the param variables into instance variables
		pull_params( params, :any )

			#Turn only capital session variables into instance variables
		pull_params( sessions, :cap )

			#trun only upper case cookie variables into instance variables
		pull_params( cookies, :upper, [/; path.*/, ''] )
	end

		#Store any pretty variables they now have
	def store_variables( user_vars )

			#Store the same varables or newly named ones
		user_vars.each do |var|
			if 		var =~ /^@__([A-Z0-9_]+)$/	#All caps are cookies
				puts "Cookie #$1"
				cookies[$1] = instance_variable_get(var)
			elsif var =~ /^@__([A-Za-z0-9_]+)$/	#Sessions can have any kind of names
				puts "Session #$1"
				session[$1] = instance_variable_get(var)
			end
		end
	end

	#Pull any anything out of this hash and max vars with it
	#Filter expects an array of arrays.
	#The first element is the regex using in a gsub, the second element is what 
	#will be replaced, if a their element is found, it should be a symbol of :sub
	#or :gsub, to tell me which to use
	def pull_params( hash, naming = :any, per = false, *filter )

			#Scope my regex
		regex = nil

			#Create a regex based on the naming convension the user wants
		case naming
		when :cap
			regex = /^[A-Z].*[a-z].*/
		when :upper
			regex = /^[A-Z0-9_]+$/
		when :lower
			regex = /^[^A-Z]+$/
		else	#Default
			regex = /.*/
		end

			#Create my variables that match my regex
		hash.each do |k, v|
				#Create the instance variable if we have a match
			if k.to_s =~ regex
					#If the user gave me a filter, apply the filter
				filter.each do |f|
						#Normalize the params the user might have given us
						#Duck typing can make your code woddle a little!
					v = v.to_s	#Need to to do this to ensure things will work
					f = [f] if !f.is_a? Array	
					reg = (f[0].is_a? Regexp)? f[0]: Regexp.new( f[0] )

						#Apply the filter here
					if f[2] == :sub
						v.sub!(reg, f[1].to_s)
					else
						v.gsub!(reg, f[1].to_s)
					end
				end

					#Convert value to a dash file if that makes sence to do
				v_con = (v.class.to_s.downcase =~ /^hash/)? RestlessHash.new(v): v

					#Generate the instance variable
				if !per
					instance_variable_set( "@_#{k}", v_con )
				else
					instance_variable_set("@__#{k}", v_con )
				end
			end
		end
	end

	#################
	# Class Methods #
	#################
		#Extend application controller right now so the filter will find its hook
	module ClassMethods
		def restless_variable_filter
			load_variables( params, session.data, cookies )
			yield
			store_variables( instance_variables )
		end
	end

	private
	# Used to create class methods along with instance methods
	def self.included(base)
		base.extend(ClassMethods)
	end
end
