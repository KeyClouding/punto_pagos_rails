class PuntoPagosRails::PaymentFlowGenerator < Rails::Generators::Base
  source_root File.expand_path("../templates", __FILE__)

  argument(:payable_model_name, type: :string, required: true, banner: "payable_model_name")
  argument(:payments_controller_name,
    banner: "payments_controller_name", type: :string, default: "transactions")
  class_option :ssl, type: :boolean, default: false

  def create_payable_model
    Rails.application.eager_load!
    models = ActiveRecord::Base.descendants.map(&:to_s)
    models.include?(payable_class) ? add_payment_attributes_to_payable : create_payable
  end

  def extend_payable_abilities
    line = "class #{payable_class} < ActiveRecord::Base"
    gsub_file "app/models/#{payable}.rb", /(#{Regexp.escape(line)})/mi do |match|
      "#{match}\n  include PuntoPagosRails::Payable\n"
    end
  end

  def add_controller
    template("transactions_controller.rb.erb", controller_path)
  end

  def copy_views
    template("success.html.erb", "app/views/#{controller_name}/success.html.erb")
    template("error.html.erb", "app/views/#{controller_name}/error.html.erb")
  end

  def add_routes
    line = "Rails.application.routes.draw do"
    gsub_file "config/routes.rb", /(#{Regexp.escape(line)})/mi do |match|
      <<-HERE.gsub(/^ {9}/, '')
         #{match}
           #{options.ssl? ? 'post' : 'get'} "#{controller_name}/notification#{options.ssl? ? '' : '/:token'}", to: "#{controller_name}#notification"
           get "#{controller_name}/error/:token", to: "#{controller_name}#error", as: :#{singular_controller_name}_error
           get "#{controller_name}/success/:token", to: "#{controller_name}#success", as: :#{singular_controller_name}_success
           post "#{controller_name}/create", to: "#{controller_name}#create", as: :#{singular_controller_name}_create
         HERE
    end
  end

  private

  def payable
    payable_table_name.singularize
  end

  def payable_table_name
    payable_model_name.tableize
  end

  def payable_class
    payable.classify
  end

  def controller_path
    "app/controllers/#{controller_name}_controller.rb"
  end

  def controller_name
    payments_controller_name.tableize.pluralize
  end

  def singular_controller_name
    controller_name.singularize
  end

  def controller_class
    "#{payments_controller_name.classify.pluralize}Controller"
  end

  def add_payment_attributes_to_payable
    generate "migration add_amount_to_#{payable_table_name} amount:integer payment_state:string"
  end

  def create_payable
    generate "model #{payable} amount:integer payment_state:string --no-fixture"
  end

  def ssl?
    options.ssl?
  end
end
