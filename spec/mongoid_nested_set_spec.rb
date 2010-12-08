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



  context "that acts as a nested set" do


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

    end
  end
end
