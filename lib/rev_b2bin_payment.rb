require "rev_b2bin_payment/version"
require "rev_b2bin_payment/b2b_api"

module RevB2binPayment
  class Error < StandardError; end
  
  class AutoWithDraws
  	
  	def initialize


  		# CREATE AUTOWITHDRAW
  		# create
  	end

  	def create

  	end
  end

  class Deposit 
  	attr_accessor :currency, :order, :current_user, :data, :limited_withdraw_with_kyc, :wallet, :key, :secret,
	  	:limited_withdraw_without_kyc, :uri_api, :gateway_url, :callback_url, :callback_withdraw_url, :table_currency
  	def initialize(data, order, currency, current_user, limited_withdraw_with_kyc, wallet, key, secret,
	  	limited_withdraw_without_kyc, uri_api, gateway_url, callback_url = nil, callback_withdraw_url = nil, table_currency = nil)
  		@currency = currency
  		@order = order
  		@data = data
  		@current_user = current_user
  		@limited_withdraw_without_kyc = limited_withdraw_without_kyc
	    @limited_withdraw_with_kyc = limited_withdraw_with_kyc
	    @uri_api = uri_api
	    @gateway_url = gateway_url
	    @callback_url = callback_url
	    @callback_withdraw_url = callback_withdraw_url
	    @wallet = wallet
	    @key = key 
	    @secret = secret
	    @table_currency = table_currency

	    # CREATE DEPOSIT
	    create

  	end

  	def create
  		res = RevB2binPayment::B2bApi.new(@data, @current_user, @wallet, @key, @secret, 
  			@limited_withdraw_with_kyc, @limited_withdraw_without_kyc, 
  			@uri_api, @gateway_url, @callback_url, @callback_withdraw_url, @table_currency).create_payment_order
      if res["code"].present? && res["code"].to_i < 0
      	return {"code": res["code"].to_i}
      else
        return {"code": 10}
      end
  	end


  end

end
