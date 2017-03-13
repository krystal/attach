# Attach

Attach allow you to attach files/images/documents to Active Record models with ease. Just define which attachments you wish to add and you can easily upload them to your server (either file system or database).

## Installation

In order to get started, add the gem to your Gemfile:

```ruby
gem 'attach'
```

Once included, add the database table which will store your attachments.

```
$ rake attach:install:migrations
$ rake db:migrate
```

## Getting started

You can define the attachments which you wish to use on any of your models as such:

```ruby
class Person < ActiveRecord::Base
  attachment :cover_photo
  attachment :profile_picture
end
```

## Uploading attachments

You can upload attachments straight from forms into your models by using the `_file` accessor which is provided for each attachment that you define.

```erb
<% form_for @person, :html => {:multipart => true} do |f| %>
  <%= f.file_field :profile_picture_file %>
  <%= f.file_field :cover_photo_file %>
  <%= f.submit "Upload Attachments" %>
<% end %>
```

## Accessing attachments

You can access any of your attachments easily through the methods as shown below.

```ruby
# Accessing attachments
person = Person.find(person.id)
person.cover_photo            #=> Attach::Attachment
person.cover_photo.url        #=> "/attachment/145d17ed-d5e3-4b55-8c89-ecad9521ad73/snom-mm2.jpg"
person.cover_photo.file_name  #=> "snom-mm2.jpg"
person.cover_photo.digest     #=> "c4de7fd75a7e2ec37bde3a5ef9fa53a1ce9228c0"
person.cover_photo.binary     #=> <Binary data>


# Pre-loading attachments will only load meta data, the actual content will
# not be loaded.
people = Person.includes(:profile_picture)
```

To download the stored asset, you can use the value of the `url`. Attach has a middleware that will render these files for you automatically.

## Deleting images

If you wish to remove an image you can simply call `destroy`. If you want to do this from a form, you can add a checkbox with the name `{name}_delete`.

## Backends

You can choose between storing your images in your database or on the file system. The method you choose will depend on your environment and usage requirements. By default, files are stored in the database.

To use the file system, just use the following:

```ruby
# Stores files in an 'attachments' directory in the root of your app
Attach.use_filesystem!
# Stores files in the directory you specify
Attach.use_filesystem!(:root => 'path/to/root/dir')
```

You can also write your own backends. Check out the abstract backend for instructions. Once you've written one, just set it as the backend.

```ruby
Attach.backend = MyApp::MyCleverAttachBackend.new
```

## Caching & Disposition

When you serve assets out through the included middleware, by default they will be served with a `private, max-age=<1 year>` cache control header. This can be changed to suit the needs of each type of attachment.

```ruby
attachment :cover_photo, :cache_type => 'public', :cache_max_age => 5.days
```

The disposition of a file served by the middleware will be `attachment` by default. You can change this:

```ruby
attachment :cover_photo, :disposition => 'inline'
```

## Validation

To validate an image before persisting it to your backend you can include a validation block.

```ruby
attachment :image do
  validator do |attachment, errors|
    unless Lizard::Image.is_image?(attachment.binary)
      errors << "must be an image"
    end
  end
end
```

## Processing

If processing is required for an uploaded file, this can be acheived by passing a block to the `attachment` method.

```ruby
attachment :image do
  processor do |attachment|
    # Do your additional processing on this attachment
    # This might include making thumbnails of an image etc...
  end
end
```

By default, all processing will happen syncronously which may not be desirable if the processing will take time. To background the processing automatically, you can request the assistance of a worker. You need to use your own worker system to do this, an example is provided below.

```ruby
# Configure how jobs should be queued
Attach::Processor.background do |attachment|
  ProcessAttachmentJob.queue(:attachment_id => attachment.id)
end

# Define a job (if you don't preload your app, be sure to get the parent initialized before trying to run any processing
# otherwise the processors won't have registered),
class ProcessAttachmentJob < Jobster::Job
  def perform
    if attachment = Attach::Attachment.includes(:parent).find(params['attachment_id'])
      attachment.processor.process
    end
  end
end
```

Once you have registered a block for queueing (using `background`), all attachments for the application will be processed in the background.

## Children

Attachments can have child attachments which are associated with the first one. This is useful if you're uploading images and wish to generate different thumbnails for it automatically. It works like this:

### Creating children

The easiest place to create children is in the processing block for an attachment. You should call the `add_child` method with the role for the new item. This should be unique across all children in the parent image. If you upload a new child with the same name later, the original will be removed.

```ruby
attachment :cover_photo do
  processor do |attachment|
    image = Lizard::Image.new(attachment.binary)
    attachment.add_child(:thumb500) do |c|
      c.binary = image.resize(500, 500)
      c.file_name = "thumb500x500.jpg"
    end
  end
end
```

### Accessing children

If you have a single object you wish to find a child for, the easiest way is like such...

```ruby
post = Post.find(31)
post.cover_photo                    # => The original attachment
post.cover_photo.child(:thumb500)   # => The child attachment
```

If you're loading multiple objects though you may wish to preload the images that you desire in a single query rather than looking up each one in turn.

```ruby
Post.includes_attachments(:cover_photo => [:thumb500]).each do |post|
  post.cover_photo.child(:thumb500) # => No additional database queries
end
```
