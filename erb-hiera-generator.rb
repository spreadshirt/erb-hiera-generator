#!/usr/bin/env ruby

# Working with facter + hiera + erb without puppet

require "erb"
require "facter"
require "hiera"

if ARGV.length < 3
  puts "Usage: #{$0} <path-to-hiera.yaml> <path-to-template> <output file>"
	exit 1
end

hiera_config_path = ARGV[0]
template_path = ARGV[1]
output_path = ARGV[2]

# very simple text coloring: https://stackoverflow.com/questions/2070010/how-to-output-my-ruby-commandline-text-in-different-colours
def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def red(text); colorize(text, 31); end

# imitate "string escaping" in puppet
class Psych::Visitors::YAMLTree
  old_visit_String = instance_method(:visit_String)

  define_method(:visit_String) do |o|
    if o.start_with?('-', '/')
      # see https://ruby-doc.org/stdlib-1.9.3/libdoc/psych/rdoc/Psych/Visitors/YAMLTree.html#method-i-visit_String
      @emitter.scalar(o, nil, nil, true, true, Psych::Nodes::Scalar::DOUBLE_QUOTED)
    else
      old_visit_String.bind(self).(o)
    end
  end
end

class FacterScope
  def [](name)
    Facter.value(unglobalize(name))
  end

  def include?(name)
    not Facter.value(unglobalize(name)).nil?
  end

  def unglobalize(name)
    name.sub(/^::/, "")
  end
end

class FakeHieraScope
  def initialize(hiera, scope)
    @hiera = hiera
    @scope = scope
  end

  def scope()
    self
  end

  # This emulates select functions from https://puppet.com/docs/puppet/5.3/function.html.
  #
  # In the templates this is called via syntax like the following:
  #
  #     <%= scope.call_function('hiera', ['my_project::my_variable', 'optional fallback']) %>
  def call_function(fn_name, args)
    case fn_name
    when 'hiera'
      val = @hiera.lookup(args[0], args[1], @scope)
      if val.nil?
        val = @scope[args[0]]
      end
      if val.nil? && !(args.length >= 2)
        # TODO: display exception coloured in output
        raise Exception, "undefined variable '#{args[0]}' and no default"
      end
      val
    when 'hiera_hash'
      @hiera.lookup(args[0], args[1], @scope, resolution_type = :hash)
    when 'template'
      erb, _ = make_erb(args[0])
      erb.result(self.get_binding())
    when 'warning'
      puts red("[WARNING]: #{args[0]}")
    when 'fail'
      raise RuntimeError, args[0]
    else
      raise Exception, "call_function: unknown function '#{fn_name}'" if fn_name != 'hiera'
    end
  end

  def get_binding(need_facter = false)
    if need_facter
      # NOTE: This might be cause for slowness, reenable this in case
      #       sockpuppet is slow in the future.
      #STDERR.puts "[WARNING] needs all facts, possible performance impact"
      Facter.to_hash.each do |k, v|
        instance_variable_set "@#{k}", v
      end
    end

    binding
  end
end

def make_erb(filename)
  src = File.read(filename)
  need_facter = !src.match(/@/).nil?
  erb = ERB.new(src, nil, "%-")
  erb.filename = filename
  [erb, need_facter]
end

scope = FacterScope.new
hiera = Hiera.new(:config => hiera_config_path)
hiera_scope = FakeHieraScope.new(hiera, scope)

erb, need_facter = make_erb(template_path)
File.write(output_path, erb.result(hiera_scope.get_binding(need_facter)))