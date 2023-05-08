module CabooseRets
  class PropertiesController < ApplicationController

    # @route GET /properties/search-options
    def search_options
      count = params[:count_per_name] ? params[:count_per_name] : 10
      arr = SearchOption.results(params[:q], count)
      render :json => arr
    end

    # @route GET /tuscaloosa-condos-for-sale
    # @route GET /properties
    def index
      base_url = '/properties'
      base_url = request.original_fullpath =~ /^\/tuscaloosa-condos-for-sale(.*?)$/ ? '/tuscaloosa-condos-for-sale' : base_url
    	params[:street_number_like] = params[:street_name_like].tr('A-z', '').tr(' ', '') unless params[:street_name_like].nil?
    	unless params[:street_name_like].nil?
    		params[:street_name_like] = params[:street_name_like].tr('0-9', "")
    		until params[:street_name_like][0] != " " || params[:street_name_like] == ''
    			params[:street_name_like][0] = '' if params[:street_name_like][0].to_i == 0
    		end
    	end
      where = "(id is not null)"
      search_options = []
      searched_address = false

      if (@site && @site.id == 558) || request.original_fullpath =~ /^\/tuscaloosa-condos-for-sale(.*?)$/
        where = "(style ILIKE '%condo%' OR public_remarks ILIKE '%condo%' OR legal_description ILIKE '%unit%' OR res_style ILIKE '%condo%' OR property_subtype ILIKE '%condo%' OR property_subtype ILIKE '%townhouse%')"
      end

      if params[:location_query] && !params[:location_query].blank?
        lc = params[:location_query]
        if lc && lc.count > 0
          lc.each do |lcid|
            so = CabooseRets::SearchOption.where(:id => lcid).first
            if so && so.name == "Street Address"
              search_options << "( CONCAT(CONCAT(CONCAT(CONCAT(street_number, ' '),street_name),' '),street_suffix) ILIKE '%#{so.value}%' )"
              searched_address = true
            elsif so && so.name == "Street Name"
              search_options << "( CONCAT(CONCAT(street_name,' '),street_suffix) ILIKE '%#{so.value}%' )"
            elsif so
              search_options << "(#{so.field} = '#{so.value}')"
              searched_address = true if so.name == 'MLS Number'
            end
          end
        end
      end

      filtered_address = params[:street_address_like].blank? ? nil : params[:street_address_like].downcase.strip.gsub(".","").gsub(/ blvd$/," boulevard").gsub(/ pkwy$/,"parkway").gsub(/ st$/,"street").gsub(/ dr$/,"drive").gsub(/ ave$/,"avenue").gsub(/ ct$/,"court").gsub(/ cir$/,"circle").gsub(/ rd$/,"road")

      params[:street_address_like] = filtered_address

      where2 = search_options.blank? ? "(id is not null)" : ("(" + search_options.join(' OR ') + ")")

      sortby = @site && @site.id == 558 ? "original_entry_timestamp" : CabooseRets::default_property_sort
      @saved_properties = CabooseRets::SavedProperty.where(:user_id => logged_in_user.id).pluck(:mls_number)
      @pager = Caboose::PageBarGenerator.new(params, {
        'area'                     => '',
        'area_like'                => '',      
        'acreage_gte'              => '',
        'acreage_lte'              => '',
        'city'                     => '',
        'city_like'                => '',
        'county_or_parish'         => '',
        'county_or_parishy_like'   => '',
        'list_price_gte'           => '',
        'list_price_lte'           => '',
        'beds_total_gte'           => '',
        'beds_total_lte'           => '',
        'baths_total_gte'          => '',
        'baths_total_lte'          => '',
        'property_type'            => '',
        'property_subtype'         => '',
        'sqft_total_gte'           => '',
        'sqft_total_gte_lte'       => '',
        'neighborhood'             => '',
        'elementary_school'        => '',
        'middle_school'            => '',
        'high_school'              => '',
        'list_agent_mls_id'        => '',
        'list_office_mls_id'       => '',  
        'public_remarks_like'      => '',
        'waterfronts'              => '',
        'waterfronts_not_null'     => '',
        'lot_desc_like'            => '',
        'mls_number'               => '',
        'subdivision'              => '',
        'style'                    => '',
        'foreclosure_yn'           => '',
        'address_like'             => '',
        'street_name_like'         => '',
        'street_number_like'       => '',
        'postal_code'              => '',
        'postal_code_like'         => '',
        'street_address_like'      => '',
        'status'                   => 'Active'
      },{
        'model'           => 'CabooseRets::Property',
        'sort'            => sortby,
        'desc'            => true,
        'abbreviations'   => {
          'address_like'    => 'street_number_concat_street_dir_prefix_concat_street_name_concat_street_suffix_concat_street_dir_suffix_like'
        },
        'skip'            => ['status'],
        'additional_params' => ['location_query'],
        'base_url'        => base_url,
        'items_per_page'  => 10,
        'additional_where' => [ where, where2 ]
      })

      @pager.original_params[:test] == "hey"

      @properties = @pager.items
      if params[:waterfronts].present?   then @properties = @properties.reject{|p| p.waterfronts.blank?} end
      # if params[:ftr_lotdesc] == 'golf' then @properties.reject!{|p| p.ftr_lotdesc != 'golf'} end 
      if params[:foreclosure_yn] then @properties = @properties.reject{|p| p.foreclosure_yn != "Y"} end

      # @saved_search = nil
      # if CabooseRets::SavedSearch.exists?(:uri => request.fullpath)
      #   @saved_search = CabooseRets::SavedSearch.where(:uri => request.fullpath).first
      # end

      @block_options = {
        :properties   => @properties,
        :saved_search => @saved_search,
        :pager        => @pager
      }

      if @properties && @properties.count == 1 && searched_address
        only_property = @properties.first
        redirect_to only_property.url and return
      end


    end

    # @route GET /properties/:mls_number/details
    def details
      @property = Property.where(:mls_number => params[:mls_number], :status => 'Active').first
      @agent = Agent.where(:matrix_unique_id => @property.list_agent_mui).where("office_mls_id ILIKE ?", @site.rets_office_id).first if @property
      @saved = logged_in? && SavedProperty.where(:user_id => logged_in_user.id, :mls_number => params[:mls_number]).exists?
      price_where = "list_price is not null and (list_price >= ? AND list_price <= ?)"
      beds_where = "beds_total is not null and (beds_total >= ? AND beds_total <= ?)"
      price_min = @property.list_price * 0.8 if @property && @property.list_price
      price_max = @property.list_price * 1.2 if @property && @property.list_price
      beds_min = @property.beds_total - 2 if @property && @property.beds_total
      beds_max = @property.beds_total + 2 if @property && @property.beds_total

      @related = Property.near("#{@property.latitude}, #{@property.longitude}", 50).where(:property_type => @property.property_type, :status => 'Active', :property_subtype => @property.property_subtype).where(price_where,price_min,price_max).where(beds_where,beds_min,beds_max).where("mls_number != ?",@property.mls_number).order('distance asc').limit(3) if @property

      render :file => "caboose/extras/error404", :layout => "caboose/application", :status => 404 and return if @property.nil?

      @block_options = {
        :mls_number => params[:mls_number],
        :property => @property,
        :saved    => @saved,
        :form_authenticity_token => form_authenticity_token
      }

      @page.title = @property.full_address
      @page.meta_description = @property.meta_description(@site)
      @page.uri = "properties/#{@property.mls_number}/details"

    end

    #=============================================================================
    # Admin actions
    #=============================================================================


    # @route GET /admin/properties
    def admin_index
      return unless (user_is_allowed_to 'view', 'rets_properties')     
      render :layout => 'caboose/admin'       
    end

    # @route GET /admin/properties/json
    def admin_json 
      render :json => false and return if !user_is_allowed_to 'view', 'rets_properties'
      desc = params[:desc].blank? && !params[:sort].blank? ? 'false' : 'true'
      pager = Caboose::Pager.new(params, {
        'mls_number' => ''
      }, {
        'model' => 'CabooseRets::Property',
        'sort'  => 'mls_number',
        'desc'  => desc,
        'base_url' => '/admin/properties',
        'items_per_page' => 50
      })
      render :json => {
        :pager => pager,
        :models => pager.items
      } 
    end

    # @route GET /admin/properties/:id/json
    def admin_json_single
      render :json => false and return if !user_is_allowed_to 'edit', 'rets_properties'
      prop = Property.find(params[:id])
      render :json => prop
    end

    # @route GET /admin/properties/:id
    def admin_edit
      return unless (user_is_allowed_to 'edit', 'rets_properties')
      @property = Property.find(params[:id])
      render :layout => 'caboose/admin'
    end

    # @route PUT /admin/properties/:id
    def admin_update
      return unless (user_is_allowed_to 'edit', 'rets_properties')
      resp = Caboose::StdClass.new
      prop = Property.find(params[:id])
      params.each do |k,v|
        case k
          when "alternate_link" then prop.alternate_link = v
        end
      end
      prop.save
      resp.success = true
      render :json => resp
    end

    # @route GET /api/rets-properties/:mls/photo
    def dynamic_photo_url
      render :json => false and return if !@site || !@site.use_rets
      p = Property.where(:mls_number => params[:mls]).first
      if p
        redirect_to p.featured_photo_url, :status => 307 and return
      else
        redirect_to "https://cabooseit.s3.amazonaws.com/assets/pmre/house.png", :status => 307 and return
      end
    end

    # @route GET /admin/properties/:id/refresh
    def admin_refresh
      return unless (user_is_allowed_to 'edit', 'rets_properties')
      p = Property.find(params[:id])
      CabooseRets::RetsImporter.delay(:priority => 10, :queue => 'rets').import_properties(p.mls_number, true)
      resp = Caboose::StdClass.new 
      resp.success = "The property's info is being updated from MLS. This may take a few minutes depending on how many images it has."
      render :json => resp
    end

    # @route GET /rets/products-feed/:fieldtype
    def facebook_products_feed
      rc = CabooseRets::RetsConfig.where(:site_id => @site.id).first
      if params[:fieldtype] == 'agent' && rc && !rc.agent_mls.blank?
        @properties = CabooseRets::Property.where("list_agent_mls_id = ?", rc.agent_mls).order("original_entry_timestamp DESC").take(100)
      elsif params[:fieldtype] == 'office' && rc && !rc.office_mls.blank?
        @properties = CabooseRets::Property.where("list_office_mls_id = ?", rc.office_mls).order("original_entry_timestamp DESC").take(100)
      else
        @properties = CabooseRets::Property.order("original_entry_timestamp DESC").take(100)
      end
      respond_to do |format|
        format.rss { render :layout => false }
      end
    end

    # @route GET /rets/listings-feed/:fieldtype
    def facebook_listings_feed
      @use_alternate_link = false
      @fieldtype = params[:fieldtype]
      rc = CabooseRets::RetsConfig.where(:site_id => @site.id).first
      if params[:fieldtype] == 'agent' && rc && !rc.agent_mls.blank?
        if @site.id == 558
          # Gray Group listings
          @use_alternate_link = true
          @properties = CabooseRets::Property.where(:status => 'Active').where("list_agent_mls_id in (?)", ['118593705','118511951','118598750','SCHMANDTT','118599999','118509093','118518704','118515504']).order("original_entry_timestamp DESC").take(100)
        else
          @properties = CabooseRets::Property.where("list_agent_mls_id = ?", rc.agent_mls).where(:status => 'Active').order("original_entry_timestamp DESC").take(100)
        end
      elsif params[:fieldtype] == 'office' && rc && !rc.office_mls.blank?
        @properties = CabooseRets::Property.where("list_office_mls_id = ?", rc.office_mls).where(:status => 'Active').order("original_entry_timestamp DESC").take(100)
      elsif params[:fieldtype] == 'condo'
        @properties = CabooseRets::Property.where("(style ILIKE '%condo%' OR res_style ILIKE '%condo%' OR property_subtype ILIKE '%condo%')").where(:status => 'Active').order("original_entry_timestamp DESC").take(100)
      else
        @properties = CabooseRets::Property.order("original_entry_timestamp DESC").take(100)
      end
      respond_to do |format|
        format.rss { render :layout => false }
      end
    end

  end
end
