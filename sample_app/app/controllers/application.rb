# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  layout 'default'

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '9169b23d9e56ae529c8bf411f05601e8'

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  # filter_parameter_logging :password

  def render_to_pdf(options = nil)
    pdf = PDF::HTMLDoc.new
    pdf.set_option :bodycolor, :white
    pdf.set_option :bodyfont, :helvetica # arial helvetica sans serif
    pdf.set_option :footer, '.'
    pdf.set_option :header, '...'
    pdf.set_option :size, :universal
    pdf.set_option :toc, false
    pdf.set_option :portrait, true
    pdf.set_option :links, false
    pdf.set_option :webpage, true
    pdf.set_option :left, '1cm'
    pdf.set_option :right, '1cm'
    pdf.set_option :bottom, '1cm'
    pdf << render_to_string(options)
    pdf.generate
  end

end
