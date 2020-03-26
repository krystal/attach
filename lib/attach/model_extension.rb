require 'attach/attachment'
require 'attach/processor'
require 'attach/attachment_dsl'

module Attach
  module ModelExtension

    def self.included(base)
      base.extend ClassMethods
      base.after_save do
        if @pending_attachment_deletions
          self.attachments.where(:role => @pending_attachment_deletions).destroy_all
        end

        if @pending_attachments
          @pending_attachments.values.each(&:save!)
          @pending_attachments = nil
        end
      end
    end

    module ClassMethods

      def includes_attachments(*options)
        manipulate do |records|
          if records.empty?
            # Nothing to do
          else

            if options.first.is_a?(Hash)
              options = options.first
              binaries_to_include = options.delete(:_include_binaries) || {}
            else
              binaries_to_include = {}
              options = options.each_with_object({}) do |opt, hash|
                if opt.is_a?(Symbol) || opt.is_a?(String)
                  hash[opt.to_sym] = []
                elsif opt.is_a?(Hash)
                  opt.each do |key, value|
                    if key == :_include_binaries
                      binaries_to_include = value
                    else
                      hash[key.to_sym] = value
                    end
                  end
                end
              end

            end

            options.keys.each do |key|
              if options[key].is_a?(Symbol)
                options[key] = [options[key]]
              elsif options[key] == true
                options[key] = []
              end
            end

            attachments_for_binary_preload = []
            root_attachments = {}
            Attachment.where(:owner_id => records.map(&:id), :owner_type => records.first.class.to_s, :role => options.keys).each do |attachment|
              root_attachments[[attachment.owner_id, attachment.role]] = attachment
              if binaries_to_include[attachment.role.to_sym] && binaries_to_include[attachment.role.to_sym].include?(:_self)
                attachments_for_binary_preload << attachment
              end
            end

            child_roles = options.values.flatten
            unless child_roles.empty?
              child_attachments = {}
              Attachment.where(:parent_id => root_attachments.values.map(&:id), :role => child_roles).each do |attachment|
                child_attachments[[attachment.parent_id, attachment.role]] = attachment
              end

              root_attachments.values.each do |attachment|
                options[attachment.role.to_sym].each do |role|
                  child_attachment = child_attachments[[attachment.id, role.to_s]]

                  if child_attachment && binaries_to_include[attachment.role.to_sym] && binaries_to_include[attachment.role.to_sym].include?(role)
                    attachments_for_binary_preload << child_attachment
                  end

                  attachment.instance_variable_set("@cached_children", {}) if attachment.instance_variable_get("@cached_children").nil?
                  attachment.instance_variable_get("@cached_children")[role.to_sym] = child_attachments[[attachment.id, role.to_s]] || :nil
                end
              end
            end

            if binaries = Attach.backend.read_multi(attachments_for_binary_preload)
              attachments_for_binary_preload.each do |attachment|
                attachment.instance_variable_set("@binary", binaries[attachment.id] || :nil)
              end
            else
              # Preloading binaries isn't supported by the backend
            end

            records.each do |record|
              options.keys.each do |role|
                record.instance_variable_set("@#{role}", root_attachments[[record.id, role.to_s]] || :nil)
              end
            end
          end
        end
      end

      def attachment(name, options = {}, &block)
        unless self.reflect_on_all_associations(:has_many).map(&:name).include?(:attachments)
          has_many :attachments, :as => :owner, :dependent => :destroy, :class_name => 'Attach::Attachment'
        end

        dsl = AttachmentDSL.new(&block)

        dsl.processors.each do |processor|
          Processor.register(self, name, &processor)
        end

        if dsl.validators.size > 0
          validate do
            attachment = @pending_attachments && @pending_attachments[name] ? @pending_attachments[name] : send(name)
            file_errors = []
            dsl.validators.each do |validator|
              validator.call(attachment, file_errors)
            end
            file_errors.each { |e| errors.add("#{name}_file", e) }
          end
        end

        define_method name do
          var = instance_variable_get("@#{name}")
          if var
            var == :nil ? nil : var
          else
            if attachment = self.attachments.where(:role => name, :parent_id => nil).first
              instance_variable_set("@#{name}", attachment)
            else
              instance_variable_set("@#{name}", :nil)
              nil
            end
          end
        end

        define_method "#{name}=" do |file|
          if file.is_a?(Attach::Attachment)
            self.try(name)&.destroy
            attachment = file
            attachment.owner = self
            attachment.role = name
            attachment.processed = false
          elsif file
            attachment = Attachment.new({:owner => self, :role => name}.merge(options))
            case file
            when ActionDispatch::Http::UploadedFile
              attachment.binary = file.tempfile.read
              attachment.file_name = file.original_filename
              attachment.file_type = file.content_type
            when Attach::File
              attachment.binary = file.data
              attachment.file_name = file.name
              attachment.file_type = file.type
            else
              attachment.binary = file
              attachment.file_name = "untitled"
              attachment.file_type = "application/octet-stream"
            end
          end

          if attachment
            @pending_attachments ||= {}
            @pending_attachments[name] = attachment
          end
          instance_variable_set("@#{name}", attachment)
        end

        define_method "#{name}_delete" do
          instance_variable_get("@#{name}_delete")
        end

        define_method "#{name}_delete=" do |delete|
          delete = delete.to_i
          instance_variable_set("@#{name}_delete", delete)
          if delete == 1
            @pending_attachment_deletions ||= []
            @pending_attachment_deletions << name
          end
        end
      end

    end

  end
end
