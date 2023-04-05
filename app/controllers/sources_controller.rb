# frozen_string_literal: true

class SourcesController < ApplicationController
  respond_to :js, :json, :xml

  def show
    @source = Source::Extractor.find(params[:url], params[:ref])

    respond_with(@source.to_h) do |format|
      format.xml { render xml: @source.to_h.to_xml(root: "source") }
      format.json { render json: @source.to_h.to_json }
    end
  end
end
