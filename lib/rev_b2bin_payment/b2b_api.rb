module RevB2binPayment
	require 'uri'
	require "base64"
	require 'net/http'

	class B2bApi
	  attr_accessor :params, :current_user, :limited_withdraw_with_kyc, :wallet, :key, :secret,
	  	:limited_withdraw_without_kyc, :uri_api, :gateway_url, :callback_url, :callback_withdraw_url, :table_currency
	  
	  def initialize(params = {}, current_user, wallet, key, secret, limited_withdraw_with_kyc, 
	  	limited_withdraw_without_kyc, uri_api, gateway_url, callback_url, callback_withdraw_url, 
	  	table_currency)
	    @params = params
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
	  end
	  
	  def get_header(data = {})
	    hashed = Base64.encode64("#{@key}:#{@secret}")
	    return "Basic #{hashed}"
	  end

	  def general_access_token
	    begin
	      res = HTTParty.get("#{@uri_api}/api/login", {
	        headers: {
	          Authorization: get_header()
	        }
	      })
	      return JSON.parse(res.body)
	    rescue Exception => e
	      return {
	      	"code": -1,
	      	"message": e
	      }
	    end
	  end

	  def create_payment_order
	    begin
	      @params[:wallet] = @wallet
	      auth = general_access_token
	      
	      if auth[:error].blank?
	        @params[:callback_url] = @callback_url

	        res = HTTParty.post("#{@uri_api}/api/v1/pay/bills", {
	          headers: {
	            Authorization: "#{auth['token_type']} #{auth['access_token']}"
	          },
	          body: @params
	        })
	        return JSON.parse(res.body)
	      end
	    rescue Exception => e
	      return {
	      	"code": -1,
	      	"message": e
	      }
	    end
	  end

	  def deposit
	    begin
	      auth = general_access_token
	      if auth[:error].blank?

	        res = HTTParty.get("#{Settings.b2binpay.currencies["#{@params[:currency].downcase}"]}/api/v1/rate/deposit/#{@params[:currency]}", {
	          headers: {
	            Authorization: "#{auth[:token_type]} #{auth[:access_token]}"
	          }
	        })
	        return JSON.parse(res.body)
	      end
	    rescue Exception => e
	      return {
	      	"code": -1,
	      	"message": e
	      }
	    end
	  end
	  
	  def convert_coin_to_btc(amount, coin)
	    if coin == 'USDT'
	      rate = @table_currency.constantize.find_by!(name: "B2B_BTC#{coin}").rate
	    elsif coin == 'BTC'
	      rate = 1
	    else
	      rate = @table_currency.constantize.find_by!(name: "B2B_BID_#{coin}BTC").rate
	    end
	    return (rate * amount).to_r
	  end

	  def get_transactions_withdraw_today
	    trans = Wallet::B2binPayment.get_withdraws_today(@current_user.id)
	    total_amount = 0
	    trans.each do |tran|
	      amount = convert_coin_to_btc(tran.amount.to_r, tran.wallet_currency.code.upcase)
	      total_amount += amount
	    end
	    return total_amount
	  end

	  def auto_withdraw
	    begin
	      auth = general_access_token
	      limited_amount = @current_user.kyc_paper.present? ? @limited_withdraw_with_kyc : @limited_withdraw_without_kyc
	      total_withdraw_amount = get_transactions_withdraw_today(@current_user)
	      
	      if total_withdraw_amount.to_r <= limited_amount
	        if auth[:error].blank?
	          @params[:callback_url] = Settings.b2binpay.callback_withdraw_url
	          res = HTTParty.post("#{@gateway_url}/api/v1/virtualwallets/withdraws", {
	            headers: {
	              Authorization: "#{auth['token_type']} #{auth['access_token']}"
	            },
	            body: @params
	          })
	          return JSON.parse(res.body)
	        end
	      else
	        return {"code": -1, "message": 'withdraw_limited'}
	      end
	    rescue Exception => e
	      return {
	      	"code": -1,
	      	"message": e
	      }
	    end
	  end

	end
end
