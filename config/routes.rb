RevB2binPayment::Engine.add_routes do
		get 'deposit1' => 'b2bin_payment_deposit#index'
		get 'deposit/:code' => 'b2bin_payment_deposit#create', as: 'create_b2bin_payment'
    get 'deposit/:code/address' => 'b2bin_payment_deposit#show', as: 'view_b2bin_payment'
end

RevB2binPayment::Engine.draw_routes
