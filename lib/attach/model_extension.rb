require 'attach/attachment'
require 'attach/processor'

module Attach
  module ModelExtension

    def self.included(base)
      base.extend ClassMethods
      base.after_save do
        if @pending_attachment_deletions
          self.attachments.where(:role => @pending_attachment_deletions).destroy_all
        end

        if @pending_attachments
          @pending_attachments.each do |pa|
            attachment = self.attachments.build(:uploaded_file => pa[:file], :role => pa[:role])
            if pa[:options]
              pa[:options].each do |key, value|
                attachment.send("#{key}=", value)
              end
            end
            attachment.save!
          end
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
            else
              options = options.each_with_object({}) do |role, hash|
                hash[role.to_sym] = []
              end
            end

            options.keys.each do |key|
              if options[key].is_a?(Symbol)
                options[key] = [options[key]]
              end
            end

            root_attachments = {}
            Attachment.where(:owner_id => records.map(&:id), :owner_type => records.first.class.to_s, :role => options.keys).each do |attachment|
              root_attachments[[attachment.owner_id, attachment.role]] = attachment
            end


            child_roles = options.values.flatten
            unless child_roles.empty?
              child_attachments = {}
              Attachment.where(:parent_id => root_attachments.values.map(&:id), :role => child_roles).each do |attachment|
                child_attachments[[attachment.id, attachment.role]] = attachment
              end

              root_attachments.values.each do |attachment|
                options[attachment.role.to_sym].each do |role|
                  attachment.instance_variable_set("@cached_children", {}) if attachment.instance_variable_get("@cached_children").nil?
                  attachment.instance_variable_get("@cached_children")[role.to_sym] = attachment
                end
              end
            end

            records.each do |record|
              options.keys.each do |role|
                if a = root_attachments[[record.id, role.to_s]]
                  record.instance_variable_set("@#{role}", a)
                end
              end
            end
          end
        end
      end

      def attachment(name, options = {}, &block)
        unless self.reflect_on_all_associations(:has_many).map(&:name).include?(:attachments)
          has_many :attachments, :as => :owner, :dependent => :destroy, :class_name => 'Attach::Attachment'
        end

        if block_given?
          Processor.register(self, name, &block)
        end

        define_method name do
          instance_variable_get("@#{name}") || begin
            attachment = self.attachments.where(:role => name, :parent_id => nil).first
            instance_variable_set("@#{name}", attachment)
          end
        end

        define_method "#{name}_file" do
          instance_variable_get("@#{name}_file")
        end

        define_method "#{name}_file=" do |file|
          instance_variable_set("@#{name}_file", file)
          if file.is_a?(ActionDispatch::Http::UploadedFile)
            @pending_attachments ||= []
            @pending_attachments << {:role => name, :file => file, :options => options}
          else
            nil
          end
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
