module Noid
  class Template
    attr_reader :template

    # @param [String] template A Template is a coded string of the form Prefix.Mask that governs how identifiers will be minted. 
    def initialize template
      @template = template  
    end

    def mint n
      str = prefix
      str += n2xdig(n)
      str += checkdigit(str) if checkdigit?

      str
    end

    def valid? str
      return false unless str[0..prefix.length] == prefix

      if generator == 'z'
        str[prefix.length..-1].length > 2
      else
        str[prefix.length..-1].length == characters.length
      end

      characters.split('').each_with_index do |c, i|
        case c
          when 'e'
            return false unless Noid::XDIGIT.include? str[prefix.length + i]
          when 'd'
            return false unless str[prefix.length + i] =~ /\d/
        end
      end 

      return false unless checkdigit(str[0..-2]) == str.split('').last if checkdigit?

      true
    end

    ##
    # identifier prefix string
    def prefix
      @prefix ||= @template.split('.').first
    end

    ##
    # identifier mask string
    def mask
      @mask ||= @template.split('.').last
    end

    ##
    # generator type to use: r, s, z
    def generator
      @generator ||= mask[0..0]  
    end

    ##
    # sequence pattern: e (extended), d (digit)
    def characters
      @characters ||= begin
        if checkdigit?
          mask[1..-2]
        else
          mask[1..-1]
        end
                      end
    end

    ##
    # should generated identifiers have a checkdigit?
    def checkdigit?
      mask.split('').last == 'k'
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
      @max ||= begin
        case generator
          when 'z'
            nil
          else
            characters.split('').map { |x| character_space(x) }.compact.inject(1) { |total, x| total *= x }
        end
      end
    end


    protected
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
    def n2xdig n
      xdig = characters.reverse.split('').map do |c|
        value = n % character_space(c)
        n = n / character_space(c)  
        Noid::XDIGIT[value]
      end.compact.join('')

      if generator == 'z'
        c = characters.split('').last
        while n > 0
          value = n % character_space(c)
          n = n / character_space(c)  
          xdig += Noid::XDIGIT[value]
        end
      end

      raise Exception if n > 0

      xdig.reverse
    end

  end
end
