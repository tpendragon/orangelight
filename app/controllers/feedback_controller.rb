class FeedbackController < ApplicationController
  include ApplicationHelper

  before_action :current_user_email
  before_action :build_feedback_form, only: [:create]

  def new
    unless !@feedback_form.nil?
      @feedback_form = FeedbackForm.new()
    end
    @feedback_form.current_url = request.referer
  end

  def create
    respond_to do |format|
      if @feedback_form.valid?
        @feedback_form.deliver
        format.js { flash.now[:notice] =  I18n.t('blacklight.feedback.success') }
        if @feedback_form.current_url.nil?
          redirect_to @feedback_form.current_url
        end
      else
        format.js { flash.now[:error] = @feedback_form.error_message }
      end
    end
  end

  protected
  def build_feedback_form
    @feedback_form = FeedbackForm.new(feedback_form_params)
    @feedback_form.request = request
    @feedback_form
  end

  def feedback_form_params
    params.require(:feedback_form).permit(:name, :email, :message, :current_url)
  end

  def current_user_email
    unless current_user.nil?
      unless current_user.provider != 'cas'
        @user_email = "#{current_user.uid}@princeton.edu"
        @user_email
      end
    end
  end
end