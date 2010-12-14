require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


describe Mongoid::Acts::NestedSet do

  it "provides the acts_as_nested_set method" do
    Node.should respond_to('acts_as_nested_set')
    NodeWithoutNestedSet.should respond_to('acts_as_nested_set')
  end

end


describe "A Mongoid::Document" do

  def create_clothing_nodes(klass=Node)
    nodes = {}
    # See Wikipedia for an illustration of the first tree
    # http://en.wikipedia.org/wiki/Nested_set_model#Example
    nodes[:clothing]    = klass.new.test_set_attributes('root_id' => 1, 'name' => 'Clothing',    'lft' =>  1, 'rgt' => 22, 'depth' => 0, 'parent_id' => nil)
    nodes[:mens]        = klass.new.test_set_attributes('root_id' => 1, 'name' => 'Men\'s',      'lft' =>  2, 'rgt' =>  9, 'depth' => 1, 'parent_id' => nodes[:clothing].id)
    nodes[:suits]       = klass.new.test_set_attributes('root_id' => 1, 'name' => 'Suits',       'lft' =>  3, 'rgt' =>  8, 'depth' => 2, 'parent_id' => nodes[:mens].id)
    nodes[:slacks]      = klass.new.test_set_attributes('root_id' => 1, 'name' => 'Slacks',      'lft' =>  4, 'rgt' =>  5, 'depth' => 3, 'parent_id' => nodes[:suits].id)
    nodes[:jackets]     = klass.new.test_set_attributes('root_id' => 1, 'name' => 'Jackets',     'lft' =>  6, 'rgt' =>  7, 'depth' => 3, 'parent_id' => nodes[:suits].id)
    nodes[:womens]      = klass.new.test_set_attributes('root_id' => 1, 'name' => 'Women\'s',    'lft' => 10, 'rgt' => 21, 'depth' => 1, 'parent_id' => nodes[:clothing].id)
    nodes[:dresses]     = klass.new.test_set_attributes('root_id' => 1, 'name' => 'Dresses',     'lft' => 11, 'rgt' => 16, 'depth' => 2, 'parent_id' => nodes[:womens].id)
    nodes[:skirts]      = klass.new.test_set_attributes('root_id' => 1, 'name' => 'Skirts',      'lft' => 17, 'rgt' => 18, 'depth' => 2, 'parent_id' => nodes[:womens].id)
    nodes[:blouses]     = klass.new.test_set_attributes('root_id' => 1, 'name' => 'Blouses',     'lft' => 19, 'rgt' => 20, 'depth' => 2, 'parent_id' => nodes[:womens].id)
    nodes[:gowns]       = klass.new.test_set_attributes('root_id' => 1, 'name' => 'Gowns',       'lft' => 12, 'rgt' => 13, 'depth' => 3, 'parent_id' => nodes[:dresses].id)
    nodes[:sundress]    = klass.new.test_set_attributes('root_id' => 1, 'name' => 'Sun Dresses', 'lft' => 14, 'rgt' => 15, 'depth' => 3, 'parent_id' => nodes[:dresses].id)
    nodes
  end

  def create_electronics_nodes(klass=Node)
    nodes = {}
    # See MySQL for an illustration of the second tree
    # http://dev.mysql.com/tech-resources/articles/hierarchical-data.html
    nodes[:electronics] = klass.new.test_set_attributes('root_id' => 2, 'name' => 'Electronics', 'lft' =>  1, 'rgt' => 20, 'depth' => 0, 'parent_id' => nil)
    nodes[:televisions] = klass.new.test_set_attributes('root_id' => 2, 'name' => 'Televisions', 'lft' =>  2, 'rgt' =>  9, 'depth' => 1, 'parent_id' => nodes[:electronics].id)
    nodes[:tube]        = klass.new.test_set_attributes('root_id' => 2, 'name' => 'Tube',        'lft' =>  3, 'rgt' =>  4, 'depth' => 2, 'parent_id' => nodes[:televisions].id)
    nodes[:lcd]         = klass.new.test_set_attributes('root_id' => 2, 'name' => 'LCD',         'lft' =>  5, 'rgt' =>  6, 'depth' => 2, 'parent_id' => nodes[:televisions].id)
    nodes[:plasma]      = klass.new.test_set_attributes('root_id' => 2, 'name' => 'Plasma',      'lft' =>  7, 'rgt' =>  8, 'depth' => 2, 'parent_id' => nodes[:televisions].id)
    nodes[:portable]    = klass.new.test_set_attributes('root_id' => 2, 'name' => 'Portable',    'lft' => 10, 'rgt' => 19, 'depth' => 1, 'parent_id' => nodes[:electronics].id)
    nodes[:mp3]         = klass.new.test_set_attributes('root_id' => 2, 'name' => 'MP3',         'lft' => 11, 'rgt' => 14, 'depth' => 2, 'parent_id' => nodes[:portable].id)
    nodes[:cd]          = klass.new.test_set_attributes('root_id' => 2, 'name' => 'CD',          'lft' => 15, 'rgt' => 16, 'depth' => 2, 'parent_id' => nodes[:portable].id)
    nodes[:radio]       = klass.new.test_set_attributes('root_id' => 2, 'name' => '2 Way Radio', 'lft' => 17, 'rgt' => 18, 'depth' => 2, 'parent_id' => nodes[:portable].id)
    nodes[:flash]       = klass.new.test_set_attributes('root_id' => 2, 'name' => 'Flash',       'lft' => 12, 'rgt' => 13, 'depth' => 3, 'parent_id' => nodes[:mp3].id)
    nodes
  end

  def persist_nodes(nodes, collection_name=nil)
    nodes = {:first => nodes} unless nodes.is_a? Hash
    collection_name = nodes.values.first.class.collection_name if collection_name.nil?
    coll = Mongoid.master[collection_name]

    nodes.each_value do |node|
      # Bypass the ORM (and the nested set callbacks) and save directly with the underlying driver
      coll.update({:_id => node.id}, node.attributes, {:upsert => true})
      node.new_record = false
    end
    nodes
  end




  context "that does not act as a nested set" do
    it "does not have a left field" do
      NodeWithoutNestedSet.should_not have_field('lft', :type => Integer)
    end

    it "does not have a right field" do
      NodeWithoutNestedSet.should_not have_field('rgt', :type => Integer)
    end

    it "does not include NestedSet methods" do
      NodeWithoutNestedSet.should_not respond_to('descendant_of')
      NodeWithoutNestedSet.new.should_not respond_to('left')
    end
  end


  context "that acts as an un-scoped nested set" do

    context "in a tree" do
      before(:each) do
        @nodes = persist_nodes(create_clothing_nodes(UnscopedNode))
      end

      it "can detect if roots are valid" do
        UnscopedNode.should be_all_roots_valid

        persist_nodes(UnscopedNode.new(:name => 'Test').test_set_attributes(:lft => 20, :rgt => 30, :parent_id=>nil))
        UnscopedNode.should_not be_all_roots_valid
      end

      it "can detect if left and rights are valid" do
        UnscopedNode.should be_left_and_rights_valid

        # left > right
        n = UnscopedNode.new(:name => 'Test').test_set_attributes(:root_id => 1, :lft => 6, :rgt => 5, :parent_id=>@nodes[:suits].id)
        persist_nodes(n)
        UnscopedNode.should_not be_left_and_rights_valid

        # left == right
        persist_nodes(n.test_set_attributes(:rgt => 6))
        UnscopedNode.should_not be_left_and_rights_valid

        # Overlaps parent
        persist_nodes(n.test_set_attributes(:rgt => 8))
        UnscopedNode.should_not be_left_and_rights_valid
      end

      it "can detect duplicate left and right values" do
        UnscopedNode.should be_no_duplicates_for_fields

        n = UnscopedNode.new(:name => 'Test').test_set_attributes(:root_id => 1, :lft => 6, :rgt => 25, :parent_id=>@nodes[:suits].id)
        persist_nodes(n)
        UnscopedNode.should_not be_no_duplicates_for_fields

        persist_nodes(n.test_set_attributes(:lft => 5, :rgt => 7, :parent_id=>@nodes[:suits].id))
        UnscopedNode.should_not be_no_duplicates_for_fields
      end
    end
  end


  context "that acts as a scoped nested set" do

    # Adds fields

    it "has a left field" do
      Node.should have_field('lft', :type => Integer)
      RenamedFields.should have_field('red', :type => Integer)
      RenamedFields.should_not have_field('lft', :type => Integer)
    end

    it "has a right field" do
      Node.should have_field('rgt', :type => Integer)
      RenamedFields.should have_field('red', :type => Integer)
      RenamedFields.should_not have_field('rgt', :type => Integer)
    end

    it "has a parent field" do
      Node.should have_field('parent_id', :type => String)
      RenamedFields.should have_field('mother_id', :type => String)
      RenamedFields.should_not have_field('parent_id', :type => String)
    end

    it "has a default left field name" do
      Node.acts_as_nested_set_options[:left_field].should == 'lft'
    end

    it "has a default right field name" do
      Node.acts_as_nested_set_options[:right_field].should == 'rgt'
    end

    it "has a default parent field name" do
      Node.acts_as_nested_set_options[:parent_field].should == 'parent_id'
    end

    it "returns the left field name" do
      Node.left_field_name.should == 'lft'
      Node.new.left_field_name.should == 'lft'
      RenamedFields.left_field_name.should == 'red'
      RenamedFields.new.left_field_name.should == 'red'
    end

    it "returns the right field name" do
      Node.right_field_name.should == 'rgt'
      Node.new.right_field_name.should == 'rgt'
      RenamedFields.right_field_name.should == 'black'
      RenamedFields.new.right_field_name.should == 'black'
    end

    it "returns the parent field name" do
      Node.parent_field_name.should == 'parent_id'
      Node.new.parent_field_name.should == 'parent_id'
      RenamedFields.parent_field_name.should == 'mother_id'
      RenamedFields.new.parent_field_name.should == 'mother_id'
    end

    it "does not allow assigning the left field" do
      expect { Node.new.lft = 1 }.to raise_error(NameError)
      expect { RenamedFields.new.red = 1 }.to raise_error(NameError)
    end

    it "does not allow assigning the right field" do
      expect { Node.new.rgt = 1 }.to raise_error(NameError)
      expect { RenamedFields.new.black = 1 }.to raise_error(NameError)
    end




    # No-Database Calculations

    context "with other nodes" do
      before(:each) do
        @nodes = create_clothing_nodes.merge(create_electronics_nodes)
      end

      it "determines if it is a root node" do
        @nodes[:mens].should_not be_root
        @nodes[:clothing].should be_root
      end

      it "determines if it is a leaf node" do
        @nodes[:suits].should_not be_leaf
        @nodes[:jackets].should be_leaf
      end

      it "determines if it is a child node" do
        @nodes[:mens].should be_child
        @nodes[:clothing].should_not be_child
      end

      it "determines if it is a descendant of another node" do
        @nodes[:sundress].should be_descendant_of(@nodes[:dresses])
        @nodes[:dresses].should_not be_descendant_of(@nodes[:sundress])
        @nodes[:dresses].should_not be_descendant_of(@nodes[:dresses])
        @nodes[:flash].should_not be_descendant_of(@nodes[:dresses])
      end

      it "determines if it is a descendant of or equal to another node" do
        @nodes[:sundress].should be_is_or_is_descendant_of(@nodes[:dresses])
        @nodes[:sundress].should be_is_or_is_descendant_of(@nodes[:sundress])
        @nodes[:dresses].should_not be_is_or_is_descendant_of(@nodes[:sundress])
        @nodes[:flash].should_not be_is_or_is_descendant_of(@nodes[:dresses])
        @nodes[:skirts].should_not be_is_or_is_descendant_of(@nodes[:radio])
      end

      it "determines if it is an ancestor of another node" do
        @nodes[:suits].should be_ancestor_of(@nodes[:jackets])
        @nodes[:jackets].should_not be_ancestor_of(@nodes[:suits])
        @nodes[:suits].should_not be_ancestor_of(@nodes[:suits])
        @nodes[:dresses].should_not be_ancestor_of(@nodes[:flash])
      end

      it "determines if it is an ancestor of or equal to another node" do
        @nodes[:suits].should be_is_or_is_ancestor_of(@nodes[:jackets])
        @nodes[:suits].should be_is_or_is_ancestor_of(@nodes[:suits])
        @nodes[:jackets].should_not be_is_or_is_ancestor_of(@nodes[:suits])
        @nodes[:dresses].should_not be_is_or_is_ancestor_of(@nodes[:flash])
        @nodes[:radio].should_not be_is_or_is_ancestor_of(@nodes[:skirts])
      end

    end


    context "in an empty tree" do

      it "can create a root node" do
        root = Node.create(:name => 'Root Category')
        root.should have_nestedset_pos(1, 2)
        root.depth.should == 0
      end

      it "can create a child node via children.create" do
        root = Node.create(:name => 'Root Category')
        child = root.children.create(:name => 'Child Category')
        child.should have_nestedset_pos(2, 3)
        child.parent_id.should == root.id
        child.depth.should == 1
        root.reload.should have_nestedset_pos(1, 4)
      end

      it "can create a child node via children<<" do
        root = Node.create(:name => 'Root Category')
        child = Node.create(:name => 'Child Category')
        root.children << child
        child.parent_id.should == root.id
        child.should have_nestedset_pos(2, 3)
        child.depth.should == 1
        root.reload.should have_nestedset_pos(1, 4)
      end

      it "can create a child node with parent pre-assigned" do
        root = Node.create(:name => 'Root Category')
        child = Node.create(:name => 'Child Category', :parent => root)
        child.should have_nestedset_pos(2, 3)
        child.parent_id.should == root.id
        child.depth.should == 1
        root.reload.should have_nestedset_pos(1, 4)
      end

      it "can create a child node with parent id pre-assigned" do
        root = Node.create(:name => 'Root Category')
        child = Node.create(:name => 'Child Category', :parent_id => root.id)
        child.should have_nestedset_pos(2, 3)
        child.parent_id.should == root.id
        child.depth.should == 1
        root.reload.should have_nestedset_pos(1, 4)
      end

    end


    context "in a tree" do

      before(:each) do
        @nodes = persist_nodes(create_clothing_nodes.merge(create_electronics_nodes))
      end


      # Scopes

      it "fetches all root nodes" do
        Node.roots.should have(2).entries
      end

      it "fetches all leaf nodes in order" do
        Node.leaves.where(:root_id=>1).map {|e| e.name}.should == %w[Slacks Jackets Gowns Sun\ Dresses Skirts Blouses]
      end

      it "fetches all nodes with a given depth in order" do
        Node.with_depth(1).where(:root_id=>1).map {|e| e.name}.should == %w[Men's Women's]
      end


      # Queries

      it "fetches descendants of multiple parents" do
        parents = Node.any_in(:name => %w[Men's Dresses])
        Node.where(:root_id=>1).descendants_of(parents).should have(5).entries
      end

      it "fetches self and ancestors in order" do
        @nodes[:dresses].self_and_ancestors.map {|e| e.name}.should == %w[Clothing Women's Dresses]
      end

      it "fetches ancestors in order" do
        @nodes[:dresses].ancestors.map {|e| e.name}.should == %w[Clothing Women's]
      end

      it "fetches its root" do
        @nodes[:dresses].root.name.should == 'Clothing'
      end

      it "fetches self and siblings in order" do
        @nodes[:skirts].self_and_siblings.map {|e| e.name}.should == %w[Dresses Skirts Blouses]
      end

      it "fetches siblings in order" do
        @nodes[:skirts].siblings.map {|e| e.name}.should == %w[Dresses Blouses]
      end

      it "fetches leaves in order" do
        @nodes[:womens].leaves.map {|e| e.name}.should == %w[Gowns Sun\ Dresses Skirts Blouses]
      end

      it "fetches its current level" do
        @nodes[:suits].level.should == 2
      end

      it "fetches self and descendants in order" do
        @nodes[:womens].self_and_descendants.map {|e| e.name}.should == %w[Women's Dresses Gowns Sun\ Dresses Skirts Blouses]
      end

      it "fetches descendants in order" do
        @nodes[:womens].descendants.map {|e| e.name}.should == %w[Dresses Gowns Sun\ Dresses Skirts Blouses]
      end

      it "fetches its first sibling to the left" do
        @nodes[:skirts].left_sibling.name.should == 'Dresses'
        @nodes[:slacks].left_sibling.should == nil
      end

      it "fetches its first sibling to the right" do
        @nodes[:skirts].right_sibling.name.should == 'Blouses'
        @nodes[:jackets].right_sibling.should == nil
      end

      it "can detect if roots are valid" do
        Node.should be_all_roots_valid

        persist_nodes(Node.new(:name => 'Test').test_set_attributes(:root_id => 1, :lft => 20, :rgt => 30, :parent_id=>nil))
        Node.should_not be_all_roots_valid
      end

      it "can detect if left and rights are valid" do
        Node.should be_left_and_rights_valid

        # left > right
        n = Node.new(:name => 'Test').test_set_attributes(:root_id => 1, :lft => 6, :rgt => 5, :parent_id=>@nodes[:suits].id)
        persist_nodes(n)
        Node.should_not be_left_and_rights_valid

        # left == right
        persist_nodes(n.test_set_attributes(:rgt => 6))
        Node.should_not be_left_and_rights_valid

        # Overlaps parent
        persist_nodes(n.test_set_attributes(:rgt => 8))
        Node.should_not be_left_and_rights_valid
      end

      it "can detect duplicate left and right values" do
        Node.should be_no_duplicates_for_fields

        n = Node.new(:name => 'Test').test_set_attributes(:root_id => 1, :lft => 6, :rgt => 25, :parent_id=>@nodes[:suits].id)
        persist_nodes(n)
        Node.should_not be_no_duplicates_for_fields

        persist_nodes(n.test_set_attributes(:lft => 5, :rgt => 7, :parent_id=>@nodes[:suits].id))
        Node.should_not be_no_duplicates_for_fields
      end


      # Moves

      it "cannot move a new node" do
        n = Node.new(:name => 'Test', :root_id => 1)
        expect {
          n.move_to_right_of(Node.where(:name => 'Jackets').first)
        }.to raise_error(Mongoid::Errors::MongoidError, /move.*new node/)
      end

      it "cannot move a node inside its tree" do
        n = Node.where(:name => 'Men\'s').first
        expect {
          n.move_to_right_of(Node.where(:name => 'Suits').first)
        }.to raise_error(Mongoid::Errors::MongoidError, /possible/)
      end


      it "adds newly created nodes to the end of the tree" do
        Node.create(:name => 'Vests', :root_id => 1).should have_nestedset_pos(23, 24)

        n = Node.new(:name => 'Test', :root_id => 1)
        n.save
        n.should have_nestedset_pos(25, 26)
      end

      it "can move left" do
        @nodes[:jackets].move_left
        @nodes[:jackets]      .should have_nestedset_pos( 4,  5)
        @nodes[:slacks].reload.should have_nestedset_pos( 6,  7)
        @nodes[:suits] .reload.should have_nestedset_pos( 3,  8)
        @nodes[:jackets].depth.should == 3
      end

      it "can move right" do
        @nodes[:slacks].move_right
        @nodes[:slacks]        .should have_nestedset_pos( 6,  7)
        @nodes[:jackets].reload.should have_nestedset_pos( 4,  5)
        @nodes[:suits]  .reload.should have_nestedset_pos( 3,  8)
        @nodes[:slacks].depth.should == 3
      end

      it "can move left of another node" do
        @nodes[:slacks].move_to_left_of(@nodes[:skirts])
        @nodes[:slacks]        .should have_nestedset_pos(15, 16)
        @nodes[:skirts]        .should have_nestedset_pos(17, 18)
        @nodes[:skirts] .reload.should have_nestedset_pos(17, 18)
        @nodes[:dresses].reload.should have_nestedset_pos( 9, 14)
        @nodes[:womens] .reload.should have_nestedset_pos( 8, 21)
        @nodes[:slacks].depth.should == 2
      end

      it "can move right of another node" do
        @nodes[:slacks].move_to_right_of(@nodes[:skirts])
        @nodes[:slacks]        .should have_nestedset_pos(17, 18)
        @nodes[:skirts]        .should have_nestedset_pos(15, 16)
        @nodes[:skirts] .reload.should have_nestedset_pos(15, 16)
        @nodes[:blouses].reload.should have_nestedset_pos(19, 20)
        @nodes[:womens] .reload.should have_nestedset_pos( 8, 21)
        @nodes[:slacks].depth.should == 2
      end

      it "can move as a child of another node" do
        @nodes[:slacks].move_to_child_of(@nodes[:dresses])
        @nodes[:slacks]        .should have_nestedset_pos(14, 15)
        @nodes[:dresses]       .should have_nestedset_pos( 9, 16)
        @nodes[:dresses].reload.should have_nestedset_pos( 9, 16)
        @nodes[:gowns]  .reload.should have_nestedset_pos(10, 11)
        @nodes[:mens]   .reload.should have_nestedset_pos( 2,  7)
        @nodes[:slacks].depth.should == 3
      end

      it "can move to the root position" do
        @nodes[:slacks].move_to_root.should have_nestedset_pos(1, 2)
        @nodes[:slacks].parent_id.should be_nil
        # TODO: What becomes of the existing root?
      end

      it "can move node with children" do
        @nodes[:suits].move_to_child_of(@nodes[:dresses])
        @nodes[:suits]          .should have_nestedset_pos(10, 15)
        @nodes[:dresses]        .should have_nestedset_pos( 5, 16)
        @nodes[:mens]    .reload.should have_nestedset_pos( 2,  3)
        @nodes[:womens]  .reload.should have_nestedset_pos( 4, 21)
        @nodes[:sundress].reload.should have_nestedset_pos( 8,  9)
        @nodes[:jackets] .reload.should have_nestedset_pos(13, 14)
        @nodes[:suits].depth.should == 3
        @nodes[:jackets].depth.should == 4
      end

      context "with dependent=delete_all" do
        it "deletes descendants when destroyed" do
          @nodes[:mens].destroy
          @nodes[:clothing].reload.should have_nestedset_pos( 1, 14)
          @nodes[:womens]  .reload.should have_nestedset_pos( 2, 13)
          Node.where(:name => 'Men\'s').count.should == 0
          Node.where(:name => 'Suits').count.should == 0
          Node.where(:name => 'Slacks').count.should == 0
        end
      end

      context "with dependent=destroy" do
        it "deletes descendants when destroyed" do
          Node.test_set_dependent_option :destroy
          @nodes[:mens].destroy
          @nodes[:clothing].reload.should have_nestedset_pos( 1, 14)
          @nodes[:womens]  .reload.should have_nestedset_pos( 2, 13)
          Node.where(:name => 'Men\'s').count.should == 0
          Node.where(:name => 'Suits').count.should == 0
          Node.where(:name => 'Slacks').count.should == 0
        end
      end

    end


    context "in an adjaceny list tree" do
      before(:each) do
        @nodes = create_clothing_nodes(Node)
        @nodes.each_value { |node| node.test_set_attributes(:rgt => nil) }
        persist_nodes(@nodes)
      end

      it "can rebuild nested set properties" do
        Node.rebuild!
        root = Node.root
        root.should be_a(Node)
        root.name.should == 'Clothing'

        @nodes[:clothing].reload.should have_nestedset_pos( 1, 22)
        @nodes[:mens]    .reload.should have_nestedset_pos( 2,  9)
        @nodes[:womens]  .reload.should have_nestedset_pos(10, 21)
        @nodes[:suits]   .reload.should have_nestedset_pos( 3,  8)
        @nodes[:skirts]  .reload.should have_nestedset_pos(17, 18)
      end

    end
  end


  context "that acts as a nested set with inheritance" do
    def create_shape_nodes
      nodes = {}
      nodes[:root] = SquareNode.new.test_set_attributes('name' => 'Root', 'lft' =>  1, 'rgt' => 12, 'depth' => 0, 'parent_id' => nil)
      nodes[:c1]   = SquareNode.new.test_set_attributes('name' => '1',    'lft' =>  2, 'rgt' =>  7, 'depth' => 1, 'parent_id' => nodes[:root].id)
      nodes[:c2]   = SquareNode.new.test_set_attributes('name' => '2',    'lft' =>  8, 'rgt' =>  9, 'depth' => 1, 'parent_id' => nodes[:root].id)
      nodes[:c3]   = CircleNode.new.test_set_attributes('name' => '3',    'lft' => 10, 'rgt' => 11, 'depth' => 1, 'parent_id' => nodes[:root].id)
      nodes[:c11]  = CircleNode.new.test_set_attributes('name' => '1.1',  'lft' =>  3, 'rgt' =>  4, 'depth' => 2, 'parent_id' => nodes[:c1].id)
      nodes[:c12]  = SquareNode.new.test_set_attributes('name' => '1.2',  'lft' =>  5, 'rgt' =>  6, 'depth' => 2, 'parent_id' => nodes[:c1].id)
      nodes
    end

    context "in a tree" do
      before(:each) do
        @nodes = create_shape_nodes
        persist_nodes(@nodes)
      end

      it "fetches self and descendants in order" do
        @nodes[:root].self_and_descendants.map {|e| e.name}.should == %w[Root 1 1.1 1.2 2 3]
      end
    end
  end
end
