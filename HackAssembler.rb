# This application takes in a file with no extension that is
# written in Symbolic Assembly for the Hack Computer and 
# translates and outputs the binary representation file

# there are 4 main parts to this process
# Parser - unpacks each instruction into its underlying fields
# Code - translates each field into its corresponding binary value
# SymbolTable - manages the symbol table
# Main - init's the I/O files and drives the process

class HackAssembler
    attr_reader :code, :bin    
    def initialize()
        # our array of code to process
        @code = []
        
        # our array of code translated into binary
        @bin = []
        
        # our lookup table
        @table = SymbolTable.new()
        
        # our Comment Stripper
        @cs = RemoveComments.new()
        
        # our Parser/Converter to Binary
        @pb = ParseToBinary.new()
    end
    
    def convert_symbols()
        @code = @table.convert_symbols(@code)    
    end
    
    def parse_code()
        @bin = @pb.convert_code(@code)    
    end
    
    def load_asm(from_file)
        File.readlines(from_file[0] + ".asm").each do |line|
            temp = @cs.remove_comments(line)
            if temp.match /[a-zA-Z0-9]/
                @code << temp.chomp
            end
        end
    end
    
    def save_hack(name)
        File.open(name + ".hack", 'w') do |f|
            @bin.each do |x|
                f.puts x
            end
        end
    end
end

class ParseToBinary
    def initialize
        @jmp = Hash.new(0)
        @dst = Hash.new(0)
        @cmp = Hash.new(0)
        
        # add the Jump Codes
        @jmp['null'] = '000'    # no jump
        @jmp['JGT'] = '001'     # if out > 0 jump
        @jmp['JEQ'] = '010'     # if out = 0 jump
        @jmp['JGE'] = '011'     # if out >= 0 jump
        @jmp['JLT'] = '100'     # if out < 0 jump
        @jmp['JNE'] = '101'     # if out != 0 jump
        @jmp['JLE'] = '110'     # if out <= 0 jump
        @jmp['JMP'] = '111'     # unconditional jump
        
        # add the Destination Codes
        @dst['0'] = '000'       # the value is not stored
        @dst['M'] = '001'       # RAM[A]
        @dst['D'] = '010'       # D Register
        @dst['MD'] = '011'      # RAM[A] & D Register
        @dst['A'] = '100'       # A Register
        @dst['AM'] = '101'      # A Register & RAM[A]
        @dst['AD'] = '110'      # A Register & D Register
        @dst['AMD'] = '111'     # A Register, RAM[A], D Register
        
        @cmp['0'] = ['101010','0']    # a=0
        @cmp['1'] = ['111111','0']    # a=0
        @cmp['-1'] = ['111010','0']   # a=0
        @cmp['D'] = ['001100','0']    # a=0
        @cmp['A'] = ['110000','0']    # a=0
        @cmp['!D'] = ['001101','0']   # a=0
        @cmp['!A'] = ['110001','0']   # a=0
        @cmp['-D'] = ['001111','0']   # a=0
        @cmp['-A'] = ['110011','0']   # a=0
        @cmp['D+1'] = ['011111','0']  # a=0
        @cmp['A+1'] = ['110111','0']  # a=0
        @cmp['D-1'] = ['001110','0']  # a=0
        @cmp['A-1'] = ['110010','0']  # a=0
        @cmp['D+A'] = ['000010','0']  # a=0
        @cmp['D-A'] = ['010011','0']  # a=0
        @cmp['A-D'] = ['000111','0']  # a=0
        @cmp['D&A'] = ['000000','0']  # a=0
        @cmp['D|A'] = ['010101','0']  # a=0
        
        @cmp['M'] = ['110000','1']    # a=1
        @cmp['!M'] = ['110001','1']   # a=1
        @cmp['-M'] = ['110011','1']   # a=1
        @cmp['M+1'] = ['110111','1']  # a=1
        @cmp['M-1'] = ['110010','1']  # a=1
        @cmp['D+M'] = ['000010','1']  # a=1
        @cmp['D-M'] = ['010011','1']  # a=1
        @cmp['M-D'] = ['000111','1']  # a=1
        @cmp['D&M'] = ['000000','1']  # a=1
        @cmp['D|M'] = ['010101','1']  # a=1
    end
    
    def convert_code(a)
        new_code = []
        a.each do |s|
			if is_numeric?(s) 
				new_code.push cvrt_a_ins(s)
			else
				new_code.push cvrt_c_ins(s)
			end
        end
		new_code
    end
    
    def is_numeric?(s)
        !!Float(s) rescue false
    end
    
    # convert number to binary set first bit to zero &
    # pad in-between bits to equal 16 bits
    def cvrt_a_ins(a)
        "%016b" % a
    end
    
    # convert jump, destination, & computation
    def cvrt_c_ins(a)
        vals = []
        temp = a
        
        if a.include? ';'
            vals = a.split(';')
            comp = @cmp[vals[0]]
            temp = "111" + comp[1].to_s + comp[0].to_s + "000" + @jmp[vals[1]].to_s
        end
        
        if a.include? '='
            vals = a.split('=')
			comp = @cmp[vals[1]]
            temp = "111" + comp[1].to_s + comp[0].to_s + @dst[vals[0]].to_s + "000"
        end
        temp
    end
end

class SymbolTable
    def initialize
        @symtable = Hash.new(0)
        
        @symtable['R0'] = 0
        @symtable['R1'] = 1
        @symtable['R2'] = 2
        @symtable['R3'] = 3
        @symtable['R4'] = 4
        @symtable['R5'] = 5
        @symtable['R6'] = 6
        @symtable['R7'] = 7
        @symtable['R8'] = 8
        @symtable['R9'] = 9
        @symtable['R10'] = 10
        @symtable['R11'] = 11
        @symtable['R12'] = 12
        @symtable['R13'] = 13
        @symtable['R14'] = 14
        @symtable['R15'] = 15
        @symtable['SP'] = 0
        @symtable['LCL'] = 1
        @symtable['ARG'] = 2
        @symtable['THIS'] = 3
        @symtable['THAT'] = 4
        @symtable['SCREEN'] = 16384
        @symtable['KBD'] = 24576
		# add for mem loc
		@symtable['0'] = 0
        @symtable['1'] = 1
        @symtable['2'] = 2
        @symtable['3'] = 3
        @symtable['4'] = 4
        @symtable['5'] = 5
        @symtable['6'] = 6
        @symtable['7'] = 7
        @symtable['8'] = 8
        @symtable['9'] = 9
        @symtable['10'] = 10
        @symtable['11'] = 11
        @symtable['12'] = 12
        @symtable['13'] = 13
        @symtable['14'] = 14
        @symtable['15'] = 15
    end
    
    # convert the three types of symbols
    # Variable Symbols, Label Sysmbols &
    # pre-defined symbols
    def convert_symbols(a)
        # find (labels) and add them to the symbol table and
        # reference the next line of code, then delete the
        # label
        a = replace_label_symbols(a)

        # Find all user Symbols, add them to Symbol Table if
        # not already there. Then replace the symbol in the
        # code with it's numerical equivalent.
        a = populate_user_symbols(a)
        
        # Replace pre-defined symbols with their numerical 
        # equivalent from the system table
        a = replace_predefined_symbols(a)
    end
    
    def replace_label_symbols(a)
        new_code = []
        count = 0
        a.each do |s|
            if s.include? '(' 
               clean_symbol = s.delete('(').delete(')')
               add_key(clean_symbol, count)
            else
                count += 1
                new_code.push s
            end
        end
        new_code
    end
    
    def populate_user_symbols(a)
        temp = []
        labels = get_labels(a)
        
        a.each do |s|
            if s.include? '@' 
                possible_symbol = s.delete('@')
				puts possible_sysmbol if possible_sysmbol == "ponggame.0"
                if not labels.include? possible_symbol 
                    val = get_value(possible_symbol)
                    if val == nil && possible_symbol != nil
                        add_key(possible_symbol, get_max_value() + 1)        
                    end
                end
            end
            temp.push s
        end
        temp
    end
    
    def replace_predefined_symbols(a)
        temp = []
        a.each do |s|
            if s.include? '@' 
                possible_symbol = s.delete('@')
				val = get_value(possible_symbol)
				s = val.to_s if val != nil 
                s = possible_symbol if is_numeric?(possible_symbol)
            end
            temp.push s
        end
        temp
    end
    
    def is_numeric?(s)
        !!Float(s) rescue false
    end
    
    def get_labels(a)
        labels = []
        a.each do |s|
            if s.include? '(' 
               labels.push( s.delete('(').delete(')') )
				#puts s
            end
        end
        labels
    end
    
    def get_value(keyval)
		#puts @symtable if keyval == "ponggame.0"
        return @symtable[keyval] if @symtable.key?(keyval)
        nil
    end
    
    # return the Max value if below the SCREEN address
    def get_max_value()
        temp = @symtable.values
        temp.keep_if { |x| x.to_i < 16384 }
        temp.max
    end
    
    def add_key(key, val)
		#puts "#{key}, #{val}" if key == "ponggame.0"
		puts @symtable if key == "ponggame.0"
        @symtable[key] = val            
    end
end

class RemoveComments
    def initialize
    end
    
    # here we need to strip out all white space lines,
    # all comment lines and all in-line comments
    def remove_comments(line)
        # strip out all whitesape    
        line = line.delete(' ')
        
        # return empty if line is < 2 in length
        return "" if line.length < 2
        
        # remove line if it a comment line
        if line.include? '//'
           i = line.index('//')
           return "" if i <= 2
           line = line[0..i-1]
        end
        
        # remove the in-line portion of the comment
        if line.include? "/*"
            start = line.index("/*")
            stop = line.index("*/")
            line = line[0..start-1] + line[stop+2..line.length]
        end
        line
    end
end

if __FILE__ == $0
    ha = HackAssembler.new() 
   
    # load asm file and strip out comments and whitespace
    ha.load_asm(ARGV)
    
    # convert the 3 types of symbols
    # 1). Label, 2). User, 3). Pre-Defined
    ha.convert_symbols()
    
    # Parse to Binary our Symbolic Assembly
    ha.parse_code()

    # after all do lets save the hack file
    ha.save_hack(ARGV.shift)
end
