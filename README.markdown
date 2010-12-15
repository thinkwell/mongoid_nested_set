Mongoid Nested Set
==================

Mongoid Nested Set is an implementation of the nested set pattern for Mongoid.
It is a port of [AwesomeNestedSet for ActiveRecord](https://github.com/galetahub/awesome_nested_set).
It supports Mongoid 2 and Rails 3.

Nested Set represents hierarchies of trees in MongoDB using references rather
than embedded documents.  A tree is stored as a flat list of documents in a
collection.  Nested Set allows quick, ordered queries of nodes and their
descendants.  Tree modification is more costly.  The nested set pattern is
ideal for models that are read more frequently than modified.

For more on the nested set pattern: <http://en.wikipedia.org/wiki/Nested_set_model>


## Installation

Install as Gem

    gem install mongoid_nested_set

via Gemfile

    gem 'mongoid_nested_set', '0.1.0'


## Usage

To start using Mongoid Nested Set, just declare `acts_as_nested_set` on your
model:

    class Category
        include Mongoid::Document
        acts_as_nested_set
    end

### Creating a root node

    root = Category.create(:name => 'Root Category')

### Inserting a node

    child1 = root.children.create(:name => 'Child Category #1')

    child2 = Category.create(:name => 'Child Category #2')
    root.children << child2

### Deleting a node

    child1.destroy

Descendants of a destroyed nodes will also be deleted.  By default, descendant's
`destroy` method will not be called.  To enable calling descendant's `destroy`
method:

    class Category
        include Mongoid::Document
        acts_as_nested_set :dependent => :destroy
    end

### Moving a node

Several methods exist for moving nodes:

* move\_left
* move\_right
* move\_to\_left\_of(other_node)
* move\_to\_right\_of(other_node)
* move\_to\_child\_of(other_node)
* move\_to\_root


### Scopes

Scopes restrict what is considered a list.  This is commonly used to represent multiple trees
(or multiple roots) in a single collection.

    class Category
        include Mongoid::Document
        acts_as_nested_set :scope => :root_id
    end

### Conversion from other trees

Coming from acts_as_tree or adjacency list system where you only have parent_id?
No problem.  Simply add `acts_as_nested_set` and run:

    Category.rebuild!

Your tree will be converted to a valid nested set.


### Outline Numbering

Mongoid Nested Set can manage outline numbers (e.g. 1.3.2) for your documents if
you wish.  Simply add `:outline_number_field`:

    acts_as_nested_set, :outline_number_field => 'number'

Your documents will now include a `number` field (you can call it anything you
wish) that will contain outline numbers.

Don't like the outline numbers format?  Simply override `outline_number_seperator`,
`build_outline_number`, or `outline_number_sequence` in your model classes.  For
example:

    class Category
        include Mongoid::Document
        acts_as_nested_set :scope => :root_id, :outline_number_field => 'number'

        # Use a dash instead of a dot for outline numbers
        # e.g. 1-3-2
        def outline_number_seperator
            '-'
        end

        # Use 0-based indexing instead of 1-based indexing
        # e.g. 1.0
        def outline_number_sequence(prev_siblings)
            prev_siblings.count
        end
    end


## References

You can learn more about nested sets at:

<http://en.wikipedia.org/wiki/Nested_set_model>  
<http://dev.mysql.com/tech-resources/articles/hierarchical-data.html>


## Contributing to mongoid\_nested\_set

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2010 Brandon Turner. See LICENSE.txt for
further details.
