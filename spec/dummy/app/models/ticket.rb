class Ticket < ActiveRecord::Base
  include PuntoPagosRails::ResourceExtension

  set_callback :payment_success, :after do
    confirm_payment
  end

  set_callback :payment_error, :after do
    release_tickets
  end

  def confirm_payment
    self.message = "successful payment! #{self.id}"
    save!
  end

  def release_tickets
    self.message = "error paying ticket #{self.id}"
    save!
  end
end
