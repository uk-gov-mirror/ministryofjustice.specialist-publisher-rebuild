class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include GDS::SSO::ControllerMethods
  include Pundit

  before_filter :require_signin_permission!

  helper_method :current_format
  helper_method :formats_user_can_access

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

private

  def user_not_authorized
    flash[:danger] = "You aren't permitted to access #{current_format.title.pluralize}. If you feel you've reached this in error, contact your SPOC."
    redirect_to manuals_path
  end


  def document_type
    params[:document_type]
  end

  def current_format
    @current_format ||= document_types.detect { |format| format.document_type == document_type }
  end

  def formats_user_can_access
    document_types.select { |format| policy(format).index? }
  end

  def document_types
    [
      AaibReport,
      CmaCase,
      CountrysideStewardshipGrant,
      DrugSafetyUpdate,
      EmploymentAppealTribunalDecision,
      EsiFund,
      EmploymentTribunalDecision,
      MaibReport,
      MedicalSafetyAlert,
      RaibReport,
      TaxTribunalDecision,
      VehicleRecallsAndFaultsAlert,
    ]
  end
end
