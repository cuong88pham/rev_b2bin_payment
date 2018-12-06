class Wallet::B2binPaymentDepositController < BaseController
  # before_action :check_b2binpay, only: [:create]
  # before_action :new_payment, only: [:new]
  # before_action :get_currency, only: [:new, :create]
  # before_action :set_b2binpay, only: [:show]
  # before_action :get_pending_payment, only: [:new]
  def index
    render json: {status: 'ok'}
    # @payments = current_user.b2bin_payments
  end

  def new
    unless @currency
      redirect_to wallet_deposit_path, flash: {error: I18n.t('helpers.messages.currency.not_supported', currency: @currency.code.upcase)}
      return
    end

    if @pending_payment
      redirect_to wallet_view_b2bin_payment_path(@currency.code), flash: {warning: I18n.t('helpers.messages.currency.pending')}
      return
    end
  end
  
  def create
    currency = Wallet::Currency.find_by(code: params[:code])
    
    @payment = current_user.b2bin_payments.create({wallet_currency_id: currency.id})
    if @payment.save
      data = {
        amount: 0.001,
        pow: @payment.pow,
        currency: @payment.wallet_currency.code.downcase,
        lifetime: @payment.lifetime,
        tracking_id: @payment.id
      }

      res = B2binpayService.new(data)
      @res = res.create_payment_order
      
      if @res["code"].present? && @res["code"].to_i < 0
        text = <<-EOC
《#{Settings.operator_title}》
Error when attempt to submit data to B2bInPayment System for request No. #{@payment.id} of User #{current_user.nickname}
----------------------
Content: #{@res["error"]}
----------------------
        EOC
        Slack.chat_postMessage text: text, username: "Revollet", channel: "#wc_error"

        @payment.destroy
        flash[:error] = t('helpers.messages.failed')+@res["error"]
        render :new
      else
        flash[:success] = I18n.t('helpers.messages.currency.send_to_address')
        @payment.update(
          b2b_address: @res["data"]["address"],
          b2b_created_at: @res["data"]["created"],
          b2b_expired_at: @res["data"]["expired"],
          b2b_status: @res["data"]["status"],
          b2b_payment_id: @res["data"]["id"],
          b2b_payment_url: @res["data"]["url"],
          b2b_payment_memo: @res["data"]["message"].to_s
        )
        redirect_to wallet_view_b2bin_payment_path(@payment.wallet_currency.code)
      end
    else
      flash[:error] = t('helpers.messages.failed')
      redirect_to wallet_deposit_path
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_b2binpay
      currency = Wallet::Currency.find_by(code: params[:code].upcase) if Settings.b2binpay.currencies.keys.include? params[:code].downcase.to_sym
      @payment = current_user.b2bin_payments.joins(:wallet_currency).unpaid(currency.id, :deposit)
      if @payment.present?
        @payment = @payment.first
        @payments = current_user.b2bin_payments.paid(currency.id, :deposit).where("id != ?", @payment.id).order(id: :desc).page(params[:page]).per(5)
      else
        redirect_to wallet_create_b2bin_payment_path(params[:code])
      end
    end

    def check_b2binpay
      currency = Wallet::Currency.find_by(code: params[:code])
      b = current_user.b2bin_payments.where.not(b2b_address: nil, b2b_status: [Wallet::B2binPayment.b2b_statuses[:payment_is_paid], Wallet::B2binPayment.b2b_statuses[:account_validity_period_has_expired]]).where( wallet_currency_id: currency.id)
      if b.present?
        redirect_to wallet_view_b2bin_payment_path(currency.code)
      end
    end

    def new_payment
      @payment = Wallet::B2binPayment.new
    end
    def get_currency
      @currency = Wallet::Currency.find_by(code: params[:code].upcase) if Settings.b2binpay.currencies.keys.include? params[:code].downcase.to_sym
    end
    def get_pending_payment
      if @currency
        @get_pending_payment = current_user.b2bin_payments.where( wallet_currency_id: @currency.id).where.not(b2b_status: Wallet::B2binPayment.b2b_statuses[:payment_is_paid]).order(id: :desc).first
      end
    end

    def payment_params
      params.require(:wallet_b2bin_payment).permit(:wallet_currency_id)
    end
end