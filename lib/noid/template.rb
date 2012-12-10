module Noid
  class Template
    attr_reader :template

    # @param [String] template A Template is a coded string of the form Prefix.Mask that governs how identifiers will be minted. 
    def initialize template
      @template = template
      parse_template
    end

    def mint n
      str = prefix
      str += n2xdig(n)
      str += checkdigit(str) if checkdigit?

      str
    end

    # A noid has the structure (prefix)(code)(checkdigit)
    # the regexp has the following captures
    #  1 - the prefix and the code
    #  2 - the changing id characters (not the prefix and not the checkdigit)
    #  3 - the checkdigit, if there is one. This field is missing if there is no checkdigit
    def validation_regexp
      return @validation_regexp if @validation_regexp
      pattern_list = ['\A', '(', Regexp.escape(prefix), '(']
      if generator == 'z'
        pattern_list << character_to_pattern(@character_list.last) << '*'
      end
      @character_list.each do |c|
        pattern_list << character_to_pattern(c)
      end
      pattern_list << ')' << ')'  # close <code> and <body>
      if checkdigit?
        pattern_list << '(' << character_to_pattern('e') << ')'
      end
      pattern_list << '\Z'

      @validation_regexp = Regexp.new(pattern_list.join(''))
    end

    ##
    # Is the passed in string valid against this template?
    # Also validates the check digit, if the template has one
    def valid?(str)
      match = validation_regexp.match(str)
      return false if match.nil?
      if checkdigit?
        return checkdigit(match[1]) == match[3]
      end
      true
    end

    ##
    # identifier prefix string
    def prefix
      @prefix
    end

    ##
    # identifier mask string
    def mask
      @mask
    end

    ##
    # generator type to use: r, s, z
    def generator
      @generator
    end

    ##
    # sequence pattern: e (extended), d (digit)
    def characters
      @characters
    end

    ##
    # should generated identifiers have a checkdigit?
    def checkdigit?
      @checkdigit
    end

    ##
    # calculate a checkdigit for the str
    # @param [String] str
    # @return [String] checkdigit
    def checkdigit str
      Noid::XDIGIT[str.split('').map { |x| Noid::XDIGIT.index(x).to_i }.each_with_index.map { |n, idx| n*(idx+1) }.inject { |sum, n| sum += n }  % Noid::XDIGIT.length ]
    end

    ##
    # minimum sequence value
    def min
      @min ||= 0
    end

    ##
    # maximum sequence value for the template
    def max
      @max ||= case generator
               when 'z' then nil
               else size_list.inject(1) { |total, x| total * x }
               end
    end


    protected
    ##
    # parse @template and put the results into class variables
    # raise an exception if there is a parse error
    #
    def parse_template
      match = /\A(.*)\.([rsz])([ed]+)(k?)\Z/.match(@template)
      if match.nil?
        raise "Malformed Noid template '#{@template}'"
      end
      @prefix = match[1]
      @generator = match[2]
      @characters = match[3]
      @character_list = @characters.split('')
      @mask = @generator + @characters
      @checkdigit = (match[4] == 'k')
    end

    def xdigit_pattern
      @xdigit_pattern ||= "[" + Noid::XDIGIT.join('') + "]"
    end

    def character_to_pattern(c)
      case c
      when 'e' then xdigit_pattern
      when 'd' then '\d'
      else ''
      end
    end

    ##
    # Return a list giving the number of possible characters at each position
    #
    def size_list
      @size_list ||= @character_list.map { |c| character_space(c) }
    end

    ##
    # total size of a given template character value
    # @param [String] c
    def character_space c
      case c
        when 'e'
          Noid::XDIGIT.length
        when 'd'
          10
      end
    end

    ##
    # convert a minter position to a noid string under this template
    # @param [Integer] n
    # @return [String]
    def n2xdig(n)
      xdig = size_list.reverse.map do |size|
        value = n % size
        n = n / size
        Noid::XDIGIT[value]
      end.compact.join('')

      if generator == 'z'
        size = size_list.last
        while n > 0
          value = n % size
          n = n / size
          xdig += Noid::XDIGIT[value]
        end
      end

      raise Exception if n > 0

      xdig.reverse
    end

  end
end
