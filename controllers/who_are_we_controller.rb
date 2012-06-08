require 'pp'

class WhoAreWeController < ApplicationController
  def index
  end

  def nonajax
  end

  def saywho
    raddr = request.env['REMOTE_ADDR']
    hhost = request.env['HTTP_HOST']
    ruser = request.env['REMOTE_USER']
    if (ruser == nil)
      ruser = 'Unknown'
    end
    text = "You are #{ruser}@#{raddr} and I am #{hhost}<br/>"
    text += "<table"
    request.env.keys.each do |key|
        text += "<tr><td>Key #{key}</td><td>\"#{request.env[key]}\"</td></tr>"
    end
    render_text text
  end
end
