require "open-uri"

module CabooseRets
  class OpenHousesController < ApplicationController
    
    # get /open-houses
    def index
      @open_houses = OpenHouse.where("open_house_type = 'PUB' and open_house_date >= '#{DateTime.now.strftime("%F")}'").reorder("open_house_date, start_time").all
    end
    
    # get /open-houses/:mls_number
    def details
      @open_houses = OpenHouse.find(params[:mls_number])
    end
    
    # @route GET /admin/open-houses
    def admin_index
      return unless (user_is_allowed_to 'view', 'rets_open_houses')     
      render :layout => 'caboose/admin'       
    end

    # @route GET /admin/open-houses/json
    def admin_json 
      render :json => false and return if !user_is_allowed_to 'view', 'rets_open_houses'
      where = "(listing_mui in (select mls_number from rets_properties where list_office_mls_id = '#{@site.rets_office_id}'))" # '#{@site.rets_office_id}')"
      pager = Caboose::Pager.new(params, {
        'listing_mui' => ''
      }, {
        'model' => 'CabooseRets::OpenHouse',
        'sort'  => 'start_time',
        'desc'  => 'true',
        'base_url' => '/admin/open-houses',
        'items_per_page' => 50,
        'additional_where' => [ where ]
      })
      render :json => {
        :pager => pager,
        :models => pager.items
      } 
    end

    # @route GET /admin/open-houses/:id/json
    def admin_json_single
      render :json => false and return if !user_is_allowed_to 'edit', 'rets_open_houses'
      prop = OpenHouse.find(params[:id])
      render :json => prop
    end

    # @route GET /admin/open-houses/refresh
    def admin_refresh                  
      RetsImporter.delay(:priority => 10, :queue => 'rets').update_helper('OpenHouse', DateTime.parse(7.days.ago.strftime('%F %T')))
      resp = Caboose::StdClass.new
      resp.success = "New open houses are being imported!"
      render :json => resp
    end

    # @route GET /admin/open-houses/:id
    def admin_edit
      return unless (user_is_allowed_to 'edit', 'rets_open_houses')
      @openhouse = OpenHouse.find(params[:id])
      render :layout => 'caboose/admin'       
    end

    # @route PUT /admin/open-houses/:id
    def admin_update
      return unless (user_is_allowed_to 'edit', 'rets_open_houses')
      resp = Caboose::StdClass.new
      openhouse = OpenHouse.find(params[:id])
      params.each do |k,v|
        case k
          when "hide" then openhouse.hide = v
        end
      end
      openhouse.save
      resp.success = true
      render :json => resp
    end

  end
end
