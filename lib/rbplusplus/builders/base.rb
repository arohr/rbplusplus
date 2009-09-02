module RbPlusPlus
  module Builders

    # Base class for all code generation nodes
    #
    # A Node is simply a handler for one complete statement or block of C++ code.
    #
    # The code generation system for Rb++ is a two step process.
    # We first, starting with an ExtensionNode, build up an internal representation
    # of the resulting code, setting up all the code nodes required for proper
    # wrapping of the library.
    #
    # Once that's in place, then we run through the tree, actually generating
    # the C++ wrapper code.
    class Base

      # List of includes for this node
      attr_accessor :includes

      # List of declaration nodes for this node
      attr_accessor :declarations

      # List of registeration nodes for this node
      attr_accessor :registrations

      # Link to the parent node of this node
      attr_accessor :parent

      # Link to the underlying rbgccxml node this node is writing code for
      attr_accessor :code

      # List of children nodes
      attr_accessor :nodes

      # The Rice variable name for this node
      attr_accessor :rice_variable

      # The type of the rice_variable
      attr_accessor :rice_variable_type

      def initialize(code, parent = nil)
        @code = code
        @parent = parent
        @includes = []
        @declarations = []
        @registrations = []
        @nodes = []
      end

      # Does this builder node have child nodes?
      def has_children?
        @nodes && !@nodes.empty?
      end

      # Trigger the construction of the internal representation of a given node.
      # All nodes must implement this.
      def build
        raise "Nodes must implement #build"
      end

      # After #build has run, this then triggers the actual generation of the C++
      # code and returns the final string.
      # All nodes must implement this.
      def write
        raise "Nodes must implement #write"
      end

      # Once building is done, the resulting node tree needs to be sorted according
      # to subclass / superclass definitions. Like anything with C++, Rice needs to
      # know about base classes before it can build sub classes. We go through
      # each node's children, sorting them according to this.
      def sort
        @nodes.each { |n| n.sort }

        # sort_by lets us build an array of numbers that Ruby then uses
        # to sort the list. Our method here is to simply specify the
        # depth a given class is in a heirarchy, as bigger numbers end
        # up sorted farther down the list
        @nodes =
          @nodes.sort_by do |a|
            a.is_a?(ClassNode) ? superclass_count(a.code) : 0
          end
      end

      protected

      # Count the heirarchy depth of a given class node
      def superclass_count(node)
        count = 0
        n = node
        while n = n.superclass
          count += 1
        end
        count
      end

      # Turn a string that contains a qualified C++ name into a
      # string that works as a C++ variable. e.g.
      #
      #   MyClass::MyEnum => MyClass_MyEnum
      #
      def as_variable(name)
        name.gsub(/::/, "_").gsub(/[<>]/, "_").gsub("*", "_ptr_")
      end

      # Should this node be wrapped as it is or has the user
      # specified something else for this node?
      def do_not_wrap?(node)
        node.ignored? || node.moved? || !node.public?
      end

      # Given a new node, build it and add it to our nodes list
      def add_child(node)
        node.build
        nodes << node
      end

    end

  end
end
