module RevB2binPayment
  class Engine < ::Rails::Engine
  	namespace :wallet do
  		get 'deposit/:code' => 'b2bin_payment_deposit#create', as: 'create_b2bin_payment'
      get 'deposit/:code/address' => 'b2bin_payment_deposit#show', as: 'view_b2bin_payment'
  	end
  end
end