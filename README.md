# Attach

Attach allow you to attach files/images/documents to Active Record models with ease. Just define which attachments you wish to add and you can easily upload them to your server (either file system or database).

## Installation

In order to get started, add the gem to your Gemfile:

```ruby
gem 'attach', '~> 2.0'
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

You'll have a reader and a writer for the attachment that you've created which allows you to set the file to be uploaded. For example:

```ruby
person = Person.new

# Set the photo from some data you have
person.cover_photo = some_binary_data
person.cover_photo.file_name = "cover-photo.jpg"
person.cover_photo.file_type = "image/jpg"

# Or you can pass in an ActionDispatch::Http::UploadedFile
person.cover_photo = params[:person][:cover_photo]

# You can also pass a pre-constructed `Attach::File` object
file = Attach::File.new(binary)
file.name = "some-name.pdf"
file.type = "application/pdf"
person.cover_photo = file
```

It's worth noting that calling your reader will always return an `Attach::Attachment` object regardless of what you pass in. If you pass in an uploaded file it will be converted to the `Attach::Attachment` object at the point it is set.


### Uploading from a form

```erb
<% form_for @person, :html => {:multipart => true} do |f| %>
  <%= f.file_field :profile_picture %>
  <%= f.file_field :cover_photo %>
  <%= f.submit "Upload Attachments" %>
<% end %>
```

## Accessing attachments

You can access any of your attachments easily through the methods as shown below.

```ruby
# Accessing attachments
person = Person.find(person.id)
person.cover_photo              #=> Attach::Attachment
person.cover_photo.url          #=> "/attachment/145d17ed-d5e3-4b55-8c89-ecad9521ad73/snom-mm2.jpg"
person.cover_photo.file_name    #=> "snom-mm2.jpg"
person.cover_photo.digest       #=> "c4de7fd75a7e2ec37bde3a5ef9fa53a1ce9228c0"
person.cover_photo.blob.read    #=> <Binary data>
```

To download the stored asset, you can use the value of the `url`. Attach has a middleware that will render these files for you automatically. By default, the middleware will serve all attachments as long as the user has the UUID of the attachment. If you wish to disable the serving of certain attachments (i.e. secure files that should be authenticated first), you should set the `serve` option to false.

```ruby
attachment :passport_scan, :serve => false
```

### Preloading attachments

If you're obtaining an array of objects and wish to have attachment information ready to go, you can include it as follows:

```ruby
# This will include the details about the attachment (not including the binary)
people = Person.includes_attachments(:cover_photo)
```

## Deleting images

If you wish to remove an image you can simply call `destroy`. If you want to do this from a form, you can add a checkbox with the name `{name}_delete`.

## Backends

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
    unless Lizard::Image.is_image?(attachment.blob.read)
      errors << "must be an image"
    end
  end
end
```

## Custom Data

Attachments have a `custom` attribute which allows you to store data with an attachment. You might use this to store the width/height of an image in a processor.

```ruby
attachment :image do
  processor do |attachment|
    image = Lizard::Image.new(attachment.blob.read)
    attachment.custom['width'] = image.width
    attachment.custom['height'] = image.height
  end
end
```

## Children

Attachments can have child attachments which are associated with the first one. This is useful if you're uploading images and wish to generate different thumbnails for it automatically. It works like this:

### Creating children

The easiest place to create children is in the processing block for an attachment. You should call the `add_child` method with the role for the new item. This should be unique across all children in the parent image. If you upload a new child with the same name later, the original will be removed.

```ruby
attachment :cover_photo do
  processor do |attachment|
    image = Lizard::Image.new(attachment.blob.read)
    attachment.add_child(:thumb500) do |c|
      c.blob = Attach::BlobTypes::Raw.new(image.resize(500, 500).data)
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

## CDNs

If you have an origin pull CDN and would like the `url` attribute for your attachments to include the appropriate CDN host, you can set it.

```ruby
Attach.asset_host = "https://cdn.exampleapp.com"
```
