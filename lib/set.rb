#!/usr/bin/env ruby
#
# set - defines the Set class
#
# Copyright (c) 2002 Akinori MUSHA <knu@iDaemons.org>
#
# All rights reserved.
#
# You can redistribute and/or modify it under the same terms as Ruby.
#
# $Id$
# 
# This library provides the Set class that deals with a collection of
# unordered values with no duplicates.  It is a hybrid of Array's
# intuitive inter-operation facilities and Hash's fast lookup.
#
#== Example
#
#  require 'set'
#
#  set1 = Set.new ["foo", "bar", "baz"]
#
#  p set1			#=> #<Set: {"baz", "foo", "bar"}>
#
#  p set1.include?("bar")	#=> true
#
#  set1.add("heh")
#  set1.delete("foo")
#
#  p set1			#=> #<Set: {"heh", "baz", "bar"}>

# Set implements a collection of unordered values with no duplicates.
# This is a hybrid of Array's intuitive inter-operation facilities and
# Hash's fast lookup.
#
# The equality of each couple of elements is determined according to
# Object#eql? and Object#hash, since Set uses Hash as storage.
class Set
  include Enumerable

  # Creates a new set containing the given objects.
  def self.[](*ary)
    new(ary)
  end

  # Creates a new set containing the elements of the given enumerable
  # object.
  #
  # If a block is given, the elements of enum are preprocessed by the
  # given block.
  def initialize(enum = nil, &block) # :yields: o
    @hash ||= Hash.new

    enum.nil? and return

    if block
      enum.each { |o| add(block[o]) }
    else
      merge(enum)
    end
  end

  # Duplicates the set.
  def dup
    myhash = @hash
    self.class.new.instance_eval {
      @hash.replace(myhash)
      self
    }
  end

  # Returns the number of elements.
  def size
    @hash.size
  end
  alias length size

  # Returns true if the set contains no elements.
  def empty?
    @hash.empty?
  end

  # Removes all elements and returns self.
  def clear
    @hash.clear
    self
  end

  # Replaces the contents of the set with the contents of the given
  # enumerable object and returns self.
  def replace(enum)
    if enum.class == self.class
      @hash.replace(enum.instance_eval { @hash })
    else
      enum.is_a?(Enumerable) or raise ArgumentError, "value must be enumerable"
      clear
      enum.each { |o| add(o) }
    end

    self
  end

  # Converts the set to an array.  The order of elements is uncertain.
  def to_a
    @hash.keys
  end

  def flatten_merge(set, seen = Set.new)
    set.each { |e|
      if e.is_a?(Set)
	if seen.include?(e_id = e.object_id)
	  raise ArgumentError, "tried to flatten recursive Set"
	end

	seen.add(e_id)
	flatten_merge(e, seen)
	seen.delete(e_id)
      else
	add(e)
      end
    }

    self
  end
  protected :flatten_merge

  # Returns a new set that is a copy of the set, flattening each
  # containing set recursively.
  def flatten
    self.class.new.flatten_merge(self)
  end

  # Equivalent to Set#flatten, but replaces the receiver with the
  # result in place.  Returns nil if no modifications were made.
  def flatten!
    if detect { |e| e.is_a?(Set) }
      replace(flatten())
    else
      nil
    end
  end

  # Returns true if the set contains the given object.
  def include?(o)
    @hash.include?(o)
  end
  alias member? include?

  # Returns true if the set is a superset of the given set.
  def superset?(set)
    set.is_a?(Set) or raise ArgumentError, "value must be a set"
    return false if size < set.size
    set.all? { |o| include?(o) }
  end

  # Returns true if the set is a proper superset of the given set.
  def proper_superset?(set)
    set.is_a?(Set) or raise ArgumentError, "value must be a set"
    return false if size <= set.size
    set.all? { |o| include?(o) }
  end

  # Returns true if the set is a subset of the given set.
  def subset?(set)
    set.is_a?(Set) or raise ArgumentError, "value must be a set"
    return false if set.size < size
    all? { |o| set.include?(o) }
  end

  # Returns true if the set is a proper subset of the given set.
  def proper_subset?(set)
    set.is_a?(Set) or raise ArgumentError, "value must be a set"
    return false if set.size <= size
    all? { |o| set.include?(o) }
  end

  # Calls the given block once for each element in the set, passing
  # the element as parameter.
  def each
    @hash.each_key { |o| yield(o) }
  end

  # Adds the given object to the set and returns self.
  def add(o)
    @hash[o] = true
    self
  end
  alias << add

  # Adds the given object to the set and returns self.  If it the
  # object is already in the set, returns nil.
  def add?(o)
    if include?(o)
      nil
    else
      add(o)
    end
  end

  # Deletes the given object from the set and returns self.
  def delete(o)
    @hash.delete(o)
    self
  end

  # Deletes the given object from the set and returns self.  If the
  # object is not in the set, returns nil.
  def delete?(o)
    if include?(o)
      delete(o)
    else
      nil
    end
  end

  # Deletes every element of the set for which block evaluates to
  # true, and returns self.
  def delete_if
    @hash.delete_if { |o,| yield(o) }
    self
  end

  # Do collect() destructively.
  def collect!
    set = self.class.new
    each { |o| set << yield(o) }
    replace(set)
  end
  alias map! collect!

  # Equivalent to Set#delete_if, but returns nil if no changes were
  # made.
  def reject!
    n = size
    delete_if { |o| yield(o) }
    size == n ? nil : self
  end

  # Merges the elements of the given enumerable object to the set and
  # returns self.
  def merge(enum)
    if enum.class == self.class
      @hash.update(enum.instance_eval { @hash })
    else
      enum.is_a?(Enumerable) or raise ArgumentError, "value must be enumerable"
      enum.each { |o| add(o) }
    end

    self
  end

  # Deletes every element that appears in the given enumerable object
  # and returns self.
  def subtract(enum)
    enum.is_a?(Enumerable) or raise ArgumentError, "value must be enumerable"
    enum.each { |o| delete(o) }
    self
  end

  # Returns a new set built by merging the set and the elements of the
  # given enumerable object.
  def |(enum)
    enum.is_a?(Enumerable) or raise ArgumentError, "value must be enumerable"
    dup.merge(enum)
  end
  alias + |		##
  alias union |		##

  # Returns a new set built by duplicating the set, removing every
  # element that appear in the given enumerable object.
  def -(enum)
    enum.is_a?(Enumerable) or raise ArgumentError, "value must be enumerable"
    dup.subtract(enum)
  end
  alias difference -	##

  # Returns a new array containing elements common to the set and the
  # given enumerable object.
  def &(enum)
    enum.is_a?(Enumerable) or raise ArgumentError, "value must be enumerable"
    n = self.class.new
    enum.each { |o| include?(o) and n.add(o) }
    n
  end
  alias intersection &	##

  # Returns a new array containing elements exclusive between the set
  # and the given enumerable object.  (set ^ enum) is equivalent to
  # ((set | enum) - (set & enum)).
  def ^(enum)
    enum.is_a?(Enumerable) or raise ArgumentError, "value must be enumerable"
    n = dup
    enum.each { |o| if n.include?(o) then n.delete(o) else n.add(o) end }
    n
  end

  # Returns true if two sets are equal.  The equality of each couple
  # of elements is defined according to Object#eql?.
  def ==(set)
    equal?(set) and return true

    set.is_a?(Set) && size == set.size or return false

    set.all? { |o| include?(o) }
  end

  def hash	# :nodoc:
    @hash.hash
  end

  def eql?(o)	# :nodoc:
    @hash.hash == o.hash
  end

  # Classifies the set by the return value of the given block and
  # returns a hash of {value => set of elements} pairs.  The block is
  # called once for each element of the set, passing the element as
  # parameter.
  #
  # e.g.:
  #
  #   require 'set'
  #   files = Set.new(Dir.glob("*.rb"))
  #   hash = files.classify { |f| File.mtime(f).year }
  #   p hash    # => {2000=>#<Set: {"a.rb", "b.rb"}>,
  #             #     2001=>#<Set: {"c.rb", "d.rb", "e.rb"}>,
  #             #     2002=>#<Set: {"f.rb"}>}
  def classify # :yields: o
    h = {}

    each { |i|
      x = yield(i)
      (h[x] ||= self.class.new).add(i)
    }

    h
  end

  # Divides the set into a set of subsets according to the commonality
  # defined by the given block.
  #
  # If the arity of the block is 2, elements o1 and o2 are in common
  # if block.call(o1, o2) is true.  Otherwise, elements o1 and o2 are
  # in common if block.call(o1) == block.call(o2).
  #
  # e.g.:
  #
  #   require 'set'
  #   numbers = Set[1, 3, 4, 6, 9, 10, 11]
  #   set = numbers.divide { |i,j| (i - j).abs == 1 }
  #   p set     # => #<Set: {#<Set: {1}>,
  #             #            #<Set: {11, 9, 10}>,
  #             #            #<Set: {3, 4}>,
  #             #            #<Set: {6}>}>
  def divide(&func)
    if func.arity == 2
      require 'tsort'

      class << dig = {}		# :nodoc:
	include TSort

	alias tsort_each_node each_key
	def tsort_each_child(node, &block)
	  fetch(node).each(&block)
	end
      end

      each { |u|
	dig[u] = a = []
	each{ |v| func.call(u, v) and a << v }
      }

      set = Set.new()
      dig.each_strongly_connected_component { |css|
	set.add(self.class.new(css))
      }
      set
    else
      Set.new(classify(&func).values)
    end
  end

  InspectKey = :__inspect_key__

  # Returns a string containing a human-readable representation of the
  # set. ("#<Set: {element1, element2, ...}>")
  def inspect
    ids = (Thread.current[InspectKey] ||= [])

    if ids.include?(object_id)
      return sprintf('#<%s: {...}>', self.class.name)
    end

    begin
      ids << object_id
      return sprintf('#<%s: {%s}>', self.class, to_a.inspect[1..-2])
    ensure
      ids.pop
    end
  end

  def pretty_print(pp)	# :nodoc:
    pp.text sprintf('#<%s: {', self.class.name)
    pp.nest(1) {
      first = true
      each { |o|
	if first
	  first = false
	else
	  pp.text ","
	  pp.breakable
	end
	pp.pp o
      }
    }
    pp.text "}>"
  end

  def pretty_print_cycle(pp)	# :nodoc:
    pp.text sprintf('#<%s: {%s}>', self.class.name, empty? ? '' : '...')
  end
end

# SortedSet implements a set which elements are sorted in order.
class SortedSet < Set
  @@setup = false

  class << self
    def [](*ary)	# :nodoc:
      new(ary)
    end

    def setup	# :nodoc:
      @@setup and return

      begin
	require 'rbtree'

	module_eval %{
	  def initialize(*args, &block)
	    @hash = RBTree.new
	    super
	  end
	}
      rescue LoadError
	module_eval %{
	  def initialize(*args, &block)
	    @keys = nil
	    super
	  end

	  def clear
	    @keys = nil
	    super
	  end

	  def replace(enum)
	    @keys = nil
	    super
	  end

	  def add(o)
	    @keys = nil
	    @hash[o] = true
	    self
	  end
	  alias << add

	  def delete(o)
	    @keys = nil
	    @hash.delete(o)
	    self
	  end

	  def delete_if
	    n = @hash.size
	    @hash.delete_if { |o,| yield(o) }
	    @keys = nil if @hash.size != n
	    self
	  end

	  def merge(enum)
	    @keys = nil
	    super
	  end

	  def each
	    to_a.each { |o| yield(o) }
	  end

	  def to_a
	    (@keys = @hash.keys).sort! unless @keys
	    @keys
	  end
	}
      end

      @@setup = true
    end
  end

  def initialize(*args, &block)	# :nodoc:
    SortedSet.setup
    initialize(*args, &block)
  end
end

module Enumerable
  # Makes a set from the enumerable object with given arguments.
  def to_set(klass = Set, *args, &block)
    klass.new(self, *args, &block)
  end
end

# =begin
# == RestricedSet class
# RestricedSet implements a set with restrictions defined by a given
# block.
# 
# === Super class
#     Set
# 
# === Class Methods
# --- RestricedSet::new(enum = nil) { |o| ... }
# --- RestricedSet::new(enum = nil) { |rset, o| ... }
#     Creates a new restricted set containing the elements of the given
#     enumerable object.  Restrictions are defined by the given block.
# 
#     If the block's arity is 2, it is called with the RestrictedSet
#     itself and an object to see if the object is allowed to be put in
#     the set.
# 
#     Otherwise, the block is called with an object to see if the object
#     is allowed to be put in the set.
# 
# === Instance Methods
# --- restriction_proc
#     Returns the restriction procedure of the set.
# 
# =end
# 
# class RestricedSet < Set
#   def initialize(*args, &block)
#     @proc = block or raise ArgumentError, "missing a block"
# 
#     if @proc.arity == 2
#       instance_eval %{
# 	def add(o)
# 	  @hash[o] = true if @proc.call(self, o)
# 	  self
# 	end
# 	alias << add
# 
# 	def add?(o)
# 	  if include?(o) || !@proc.call(self, o)
# 	    nil
# 	  else
# 	    @hash[o] = true
# 	    self
# 	  end
# 	end
# 
# 	def replace(enum)
# 	  enum.is_a?(Enumerable) or raise ArgumentError, "value must be enumerable"
# 	  clear
# 	  enum.each { |o| add(o) }
# 
# 	  self
# 	end
# 
# 	def merge(enum)
# 	  enum.is_a?(Enumerable) or raise ArgumentError, "value must be enumerable"
# 	  enum.each { |o| add(o) }
# 
# 	  self
# 	end
#       }
#     else
#       instance_eval %{
# 	def add(o)
# 	  @hash[o] = true if @proc.call(o)
# 	  self
# 	end
# 	alias << add
# 
# 	def add?(o)
# 	  if include?(o) || !@proc.call(o)
# 	    nil
# 	  else
# 	    @hash[o] = true
# 	    self
# 	  end
# 	end
#       }
#     end
# 
#     super(*args)
#   end
# 
#   def restriction_proc
#     @proc
#   end
# end

if $0 == __FILE__
  eval DATA.read, nil, $0, __LINE__+4
end

__END__

require 'test/unit'
require 'test/unit/ui/console/testrunner'

class TC_Set < Test::Unit::TestCase
  def test_aref
    assert_nothing_raised {
      Set[]
      Set[nil]
      Set[1,2,3]
    }

    assert_equal(0, Set[].size)
    assert_equal(1, Set[nil].size)
    assert_equal(1, Set[[]].size)
    assert_equal(1, Set[[nil]].size)

    set = Set[2,4,6,4]
    assert_equal(Set.new([2,4,6]), set)
  end

  def test_s_new
    assert_nothing_raised {
      Set.new()
      Set.new(nil)
      Set.new([])
      Set.new([1,2])
      Set.new('a'..'c')
      Set.new('XYZ')
    }
    assert_raises(ArgumentError) {
      Set.new(false)
    }
    assert_raises(ArgumentError) {
      Set.new(1)
    }
    assert_raises(ArgumentError) {
      Set.new(1,2)
    }

    assert_equal(0, Set.new().size)
    assert_equal(0, Set.new(nil).size)
    assert_equal(0, Set.new([]).size)
    assert_equal(1, Set.new([nil]).size)

    ary = [2,4,6,4]
    set = Set.new(ary)
    ary.clear
    assert_equal(false, set.empty?)
    assert_equal(3, set.size)

    ary = [1,2,3]

    s = Set.new(ary) { |o| o * 2 }
    assert_equal([2,4,6], s.sort)
  end

  def test_dup
    set1 = Set[1,2]
    set2 = set1.dup

    assert_not_same(set1, set2)

    assert_equal(set1, set2)

    set1.add(3)

    assert_not_equal(set1, set2)
  end

  def test_size
    assert_equal(0, Set[].size)
    assert_equal(2, Set[1,2].size)
    assert_equal(2, Set[1,2,1].size)
  end

  def test_empty?
    assert_equal(true, Set[].empty?)
    assert_equal(false, Set[1, 2].empty?)
  end

  def test_clear
    set = Set[1,2]
    ret = set.clear

    assert_same(set, ret)
    assert_equal(true, set.empty?)
  end

  def test_replace
    set = Set[1,2]
    ret = set.replace('a'..'c')

    assert_same(set, ret)
    assert_equal(Set['a','b','c'], set)
  end

  def test_to_a
    set = Set[1,2,3,2]
    ary = set.to_a

    assert_equal([1,2,3], ary.sort)
  end

  def test_flatten
    # test1
    set1 = Set[
      1,
      Set[
	5,
	Set[7,
	  Set[0]
	],
	Set[6,2],
	1
      ],
      3,
      Set[3,4]
    ]

    set2 = set1.flatten
    set3 = Set.new(0..7)

    assert_not_same(set2, set1)
    assert_equal(set3, set2)

    # test2; destructive
    orig_set1 = set1
    set1.flatten!

    assert_same(orig_set1, set1)
    assert_equal(set3, set1)

    # test3; multiple occurences of a set in an set
    set1 = Set[1, 2]
    set2 = Set[set1, Set[set1, 4], 3]

    assert_nothing_raised {
      set2.flatten!
    }

    assert_equal(Set.new(1..4), set2)

    # test4; recursion
    set2 = Set[]
    set1 = Set[1, set2]
    set2.add(set1)

    assert_raises(ArgumentError) {
      set1.flatten!
    }

    # test5; miscellaneus
    empty = Set[]
    set =  Set[Set[empty, "a"],Set[empty, "b"]]

    assert_nothing_raised {
      set.flatten
    }

    set1 = empty.merge(Set["no_more", set])

    assert_nil(Set.new(0..31).flatten!)

    x = Set[Set[],Set[1,2]].flatten!
    y = Set[1,2]

    assert_equal(x, y)
  end

  def test_include?
    set = Set[1,2,3]

    assert_equal(true, set.include?(1))
    assert_equal(true, set.include?(2))
    assert_equal(true, set.include?(3))
    assert_equal(false, set.include?(0))
    assert_equal(false, set.include?(nil))

    set = Set["1",nil,"2",nil,"0","1",false]
    assert_equal(true, set.include?(nil))
    assert_equal(true, set.include?(false))
    assert_equal(true, set.include?("1"))
    assert_equal(false, set.include?(0))
    assert_equal(false, set.include?(true))
  end

  def test_superset?
    set = Set[1,2,3]

    assert_raises(ArgumentError) {
      set.superset?()
    }

    assert_raises(ArgumentError) {
      set.superset?(2)
    }

    assert_raises(ArgumentError) {
      set.superset?([2])
    }

    assert_equal(true, set.superset?(Set[]))
    assert_equal(true, set.superset?(Set[1,2]))
    assert_equal(true, set.superset?(Set[1,2,3]))
    assert_equal(false, set.superset?(Set[1,2,3,4]))
    assert_equal(false, set.superset?(Set[1,4]))

    assert_equal(true, Set[].superset?(Set[]))
  end

  def test_proper_superset?
    set = Set[1,2,3]

    assert_raises(ArgumentError) {
      set.proper_superset?()
    }

    assert_raises(ArgumentError) {
      set.proper_superset?(2)
    }

    assert_raises(ArgumentError) {
      set.proper_superset?([2])
    }

    assert_equal(true, set.proper_superset?(Set[]))
    assert_equal(true, set.proper_superset?(Set[1,2]))
    assert_equal(false, set.proper_superset?(Set[1,2,3]))
    assert_equal(false, set.proper_superset?(Set[1,2,3,4]))
    assert_equal(false, set.proper_superset?(Set[1,4]))

    assert_equal(false, Set[].proper_superset?(Set[]))
  end

  def test_subset?
    set = Set[1,2,3]

    assert_raises(ArgumentError) {
      set.subset?()
    }

    assert_raises(ArgumentError) {
      set.subset?(2)
    }

    assert_raises(ArgumentError) {
      set.subset?([2])
    }

    assert_equal(true, set.subset?(Set[1,2,3,4]))
    assert_equal(true, set.subset?(Set[1,2,3]))
    assert_equal(false, set.subset?(Set[1,2]))
    assert_equal(false, set.subset?(Set[]))

    assert_equal(true, Set[].subset?(Set[1]))
    assert_equal(true, Set[].subset?(Set[]))
  end

  def test_proper_subset?
    set = Set[1,2,3]

    assert_raises(ArgumentError) {
      set.proper_subset?()
    }

    assert_raises(ArgumentError) {
      set.proper_subset?(2)
    }

    assert_raises(ArgumentError) {
      set.proper_subset?([2])
    }

    assert_equal(true, set.proper_subset?(Set[1,2,3,4]))
    assert_equal(false, set.proper_subset?(Set[1,2,3]))
    assert_equal(false, set.proper_subset?(Set[1,2]))
    assert_equal(false, set.proper_subset?(Set[]))

    assert_equal(false, Set[].proper_subset?(Set[]))
  end

  def test_each
    ary = [1,3,5,7,10,20]
    set = Set.new(ary)

    assert_raises(LocalJumpError) {
      set.each
    }

    assert_nothing_raised {
      set.each { |o|
	ary.delete(o) or raise "unexpected element: #{o}"
      }

      ary.empty? or raise "forgotten elements: #{ary.join(', ')}"
    }
  end

  def test_add
    set = Set[1,2,3]

    ret = set.add(2)
    assert_same(set, ret)
    assert_equal(Set[1,2,3], set)

    ret = set.add?(2)
    assert_nil(ret)
    assert_equal(Set[1,2,3], set)

    ret = set.add(4)
    assert_same(set, ret)
    assert_equal(Set[1,2,3,4], set)

    ret = set.add?(5)
    assert_same(set, ret)
    assert_equal(Set[1,2,3,4,5], set)
  end

  def test_delete
    set = Set[1,2,3]

    ret = set.delete(4)
    assert_same(set, ret)
    assert_equal(Set[1,2,3], set)

    ret = set.delete?(4)
    assert_nil(ret)
    assert_equal(Set[1,2,3], set)

    ret = set.delete(2)
    assert_equal(set, ret)
    assert_equal(Set[1,3], set)

    ret = set.delete?(1)
    assert_equal(set, ret)
    assert_equal(Set[3], set)
  end

  def test_delete_if
    set = Set.new(1..10)
    ret = set.delete_if { |i| i > 10 }
    assert_same(set, ret)
    assert_equal(Set.new(1..10), set)

    set = Set.new(1..10)
    ret = set.delete_if { |i| i % 3 == 0 }
    assert_same(set, ret)
    assert_equal(Set[1,2,4,5,7,8,10], set)
  end

  def test_collect!
    set = Set[1,2,3,'a','b','c',-1..1,2..4]

    ret = set.collect! { |i|
      case i
      when Numeric
	i * 2
      when String
	i.upcase
      else
	nil
      end
    }

    assert_same(set, ret)
    assert_equal(Set[2,4,6,'A','B','C',nil], set)
  end

  def test_reject!
    set = Set.new(1..10)

    ret = set.reject! { |i| i > 10 }
    assert_nil(ret)
    assert_equal(Set.new(1..10), set)

    ret = set.reject! { |i| i % 3 == 0 }
    assert_same(set, ret)
    assert_equal(Set[1,2,4,5,7,8,10], set)
  end

  def test_merge
    set = Set[1,2,3]

    ret = set.merge([2,4,6])
    assert_same(set, ret)
    assert_equal(Set[1,2,3,4,6], set)
  end

  def test_subtract
    set = Set[1,2,3]

    ret = set.subtract([2,4,6])
    assert_same(set, ret)
    assert_equal(Set[1,3], set)
  end

  def test_plus
    set = Set[1,2,3]

    ret = set + [2,4,6]
    assert_not_same(set, ret)
    assert_equal(Set[1,2,3,4,6], ret)
  end

  def test_minus
    set = Set[1,2,3]

    ret = set - [2,4,6]
    assert_not_same(set, ret)
    assert_equal(Set[1,3], ret)
  end

  def test_and
    set = Set[1,2,3,4]

    ret = set & [2,4,6]
    assert_not_same(set, ret)
    assert_equal(Set[2,4], ret)
  end

  def test_eq
    set1 = Set[2,3,1]
    set2 = Set[1,2,3]

    assert_equal(set1, set1)
    assert_equal(set1, set2)
    assert_not_equal(Set[1], [1])

    set1 = Class.new(Set)["a", "b"]
    set2 = Set["a", "b", set1]
    set1 = set1.add(set1.clone)

    assert_equal(set1, set2)
    assert_equal(set2, set1)
    assert_equal(set2, set2.clone)
    assert_equal(set1.clone, set1)
  end

  # def test_hash
  # end

  # def test_eql?
  # end

  def test_classify
    set = Set.new(1..10)
    ret = set.classify { |i| i % 3 }

    assert_equal(3, ret.size)
    assert_instance_of(Hash, ret)
    ret.each_value { |value| assert_instance_of(Set, value) }
    assert_equal(Set[3,6,9], ret[0])
    assert_equal(Set[1,4,7,10], ret[1])
    assert_equal(Set[2,5,8], ret[2])
  end

  def test_divide
    set = Set.new(1..10)
    ret = set.divide { |i| i % 3 }

    assert_equal(3, ret.size)
    n = 0
    ret.each { |s| n += s.size }
    assert_equal(set.size, n)
    assert_equal(set, ret.flatten)

    set = Set[7,10,5,11,1,3,4,9,0]
    ret = set.divide { |a,b| (a - b).abs == 1 }

    assert_equal(4, ret.size)
    n = 0
    ret.each { |s| n += s.size }
    assert_equal(set.size, n)
    assert_equal(set, ret.flatten)
    ret.each { |s|
      if s.include?(0)
	assert_equal(Set[0,1], s)
      elsif s.include?(3)
	assert_equal(Set[3,4,5], s)
      elsif s.include?(7)
	assert_equal(Set[7], s)
      elsif s.include?(9)
	assert_equal(Set[9,10,11], s)
      else
	raise "unexpected group: #{s.inspect}"
      end
    }
  end

  def test_inspect
    set1 = Set[1]

    assert_equal('#<Set: {1}>', set1.inspect)

    set2 = Set[Set[0], 1, 2, set1]
    assert_equal(false, set2.inspect.include?('#<Set: {...}>'))

    set1.add(set2)
    assert_equal(true, set1.inspect.include?('#<Set: {...}>'))
  end

  # def test_pretty_print
  # end

  # def test_pretty_print_cycle
  # end
end

class TC_SortedSet < Test::Unit::TestCase
  def test_sortedset
    s = SortedSet[4,5,3,1,2]

    assert_equal([1,2,3,4,5], s.to_a)

    prev = nil
    s.each { |o| assert(prev < o) if prev; prev = o }
    assert_not_nil(prev)

    s.map! { |o| -2 * o }

    assert_equal([-10,-8,-6,-4,-2], s.to_a)

    prev = nil
    s.each { |o| assert(prev < o) if prev; prev = o }
    assert_not_nil(prev)

    s = SortedSet.new([2,1,3]) { |o| o * -2 }
    assert_equal([-6,-4,-2], s.to_a)
  end
end

class TC_Enumerable < Test::Unit::TestCase
  def test_to_set
    ary = [2,5,4,3,2,1,3]

    set = ary.to_set
    assert_instance_of(Set, set)
    assert_equal([1,2,3,4,5], set.sort)

    set = ary.to_set { |o| o * -2 }
    assert_instance_of(Set, set)
    assert_equal([-10,-8,-6,-4,-2], set.sort)

    set = ary.to_set(SortedSet)
    assert_instance_of(SortedSet, set)
    assert_equal([1,2,3,4,5], set.to_a)

    set = ary.to_set(SortedSet) { |o| o * -2 }
    assert_instance_of(SortedSet, set)
    assert_equal([-10,-8,-6,-4,-2], set.sort)
  end
end

# class TC_RestricedSet < Test::Unit::TestCase
#   def test_s_new
#     assert_raises(ArgumentError) { RestricedSet.new }
# 
#     s = RestricedSet.new([-1,2,3]) { |o| o > 0 }
#     assert_equal([2,3], s.sort)
#   end
# 
#   def test_restriction_proc
#     s = RestricedSet.new([-1,2,3]) { |o| o > 0 }
# 
#     f = s.restriction_proc
#     assert_instance_of(Proc, f)
#     assert(f[1])
#     assert(!f[0])
#   end
# 
#   def test_replace
#     s = RestricedSet.new(-3..3) { |o| o > 0 }
#     assert_equal([1,2,3], s.sort)
# 
#     s.replace([-2,0,3,4,5])
#     assert_equal([3,4,5], s.sort)
#   end
# 
#   def test_merge
#     s = RestricedSet.new { |o| o > 0 }
#     s.merge(-5..5)
#     assert_equal([1,2,3,4,5], s.sort)
# 
#     s.merge([10,-10,-8,8])
#     assert_equal([1,2,3,4,5,8,10], s.sort)
#   end
# end
