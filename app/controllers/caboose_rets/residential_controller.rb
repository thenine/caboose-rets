
module CabooseRets
  class ResidentialController < ApplicationController  
     
    # GET /residential/search-options?q=rock quary
    def search_options      
      count = params[:count_per_name] ? params[:count_per_name] : 10
      arr = SearchOption.results(params[:q], count)
      render :json => arr      
    end
    
    # GET /residential
    def index
    	params[:street_num_like] = params[:street_name_like].tr('A-z', '').tr(' ', '') unless params[:street_name_like].nil?
    	unless params[:street_name_like].nil?
    		params[:street_name_like] = params[:street_name_like].tr('0-9', "") 
    		until params[:street_name_like][0] != " " || params[:street_name_like] == ''
    			params[:street_name_like][0] = '' if params[:street_name_like][0].to_i == 0
    		end
    	end
    	
      @pager = Caboose::PageBarGenerator.new(params, {           
        'area'                => '',
        'area_like'           => '',
        'name'                => '',
        'acreage_gte'         => '',
        'acreage_lte'         => '',
        'city'                => '',
        'city_like'           => '',
        'county'              => '',
        'county_like'         => '',
        'current_price_gte'   => '',
        'current_price_lte'   => '',
        'bedrooms_gte'        => '',
        'bedrooms_lte'        => '',
        'prop_type'           => '',
        'tot_heat_sqft_gte'   => '',
        'tot_heat_sqft_lte'   => '',
        'neighborhood'        => '',
        'elem_school'         => '',
        'middle_school'       => '',
        'high_school'         => '',
        'la_code'             => '',
        'lo_code'             => '',
        'remarks_like'        => '',
        'waterfront'          => '',
        'waterfront_not_null' => '',
        'ftr_lotdesc_like'    => '',
        'mls_acct'            => '',
        'subdivision'         => '',
        'style'               => '',
        'foreclosure_yn'      => '',
        'address_like'        => '',        
        'street_name_like'    => '',
        'street_num_like'     => '',
        'zip'                 => '',
        'zip_like'            => '',        
        'date_created_gte'    => '',
        'date_created_lte'    => '',
        'date_modified_gte'   => '',
        'date_modified_lte'   => '',        
        'status'              => 'Active'
      },{
        'model'           => 'CabooseRets::ResidentialProperty',
        'sort'            => CabooseRets::default_property_sort,
        'desc'            => false,
        'abbreviations'   => { 
          'address_like' => 'street_num_concat_street_name_like'  
        },
        'skip'            => ['status'],
        'base_url'        => '/residential/search',
        'items_per_page'  => 10        
      })
      
      @properties = @pager.items                      
      if params[:waterfront].present?   then @properties.reject!{|p| p.waterfront.blank?} end
      if params[:ftr_lotdesc] == 'golf' then @properties.reject!{|p| p.ftr_lotdesc != 'golf'} end
      #if params[:foreclosure] then @properties.reject!{|p| p.foreclosure_yn != "Y"} end
      
      @saved_search = nil
      if CabooseRets::SavedSearch.exists?(:uri => request.fullpath)
        @saved_search = CabooseRets::SavedSearch.where(:uri => request.fullpath).first
      end
      
      @block_options = {
        :properties   => @properties,
        :saved_search => @saved_search,
        :pager => @pager 
      }
    end
    
    # GET /residential/:mls_acct/details
    def details
      @property = ResidentialProperty.where(:mls_acct => params[:mls_acct]).first
      @saved = logged_in? && SavedProperty.where(:user_id => logged_in_user.id, :mls_acct => params[:mls_acct]).exists? 
      if @property && @property.lo_code == '46'
        @agent = Agent.where(:la_code => @property.la_code).first
      end
      if @property.nil?
        @mls_acct = params[:mls_acct]        
        CabooseRets::RetsImporter.delay(:queue => 'rets').import_property(@mls_acct.to_i)      
        render 'residential/residential_not_exists'
        return
      end
      
      @block_options = {
        :mls_acct => params[:mls_acct],
        :property => @property,
        :saved    => @saved,
        :agent    => @property ? Agent.where(:la_code => @property.la_code).first : nil,
        :form_authenticity_token => form_authenticity_token        
      }
      
      #if @property.nil?
      #  @mls_acct = params[:mls_acct]        
      #  CabooseRets::RetsImporter.delay(:queue => 'rets').import_property(@mls_acct.to_i)      
      #  render 'residential/residential_not_exists'
      #  return
      #end
    end
    
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # GET /admin/residential
    def admin_index
      return if !user_is_allowed('properties', 'view')
        
      @gen = Caboose::PageBarGenerator.new(params, {
          'mls_acct'     => ''
      },{
          'model'    => 'CabooseRets::ResidentialProperty',
          'sort'     => 'mls_acct',
          'desc'     => false,
          'base_url' => '/admin/residential',
          'use_url_params'  => false
      })
      @properties = @gen.items    
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/residential/:mls_acct/edit
    def admin_edit
      return if !user_is_allowed('properties', 'edit')    
      @property = ResidentialProperty.where(:mls_acct => params[:mls_acct]).first
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/residential/:mls_acct/refresh
    def admin_refresh
      return if !user_is_allowed('properties', 'edit')

      p = ResidentialProperty.find(params[:mls_acct])
      p.delay(:queue => 'rets').refresh_from_mls
      
      resp = Caboose::StdClass.new
      resp.success = "The property's info is being updated from MLS. This may take a few minutes depending on how many images it has."
      render :json => resp
    end
   
  end
end
