
module CabooseRets
  class LandController < ApplicationController  
     
    # GET /land
    def index
      @gen = Caboose::PageBarGenerator.new(params, {          
          'acreage'                     => '',
          'acreage_gte'                 => '',
          'acreage_lte'                 => '',
          'acreage_source'              => '',
          'adjoining_land_use'          => '',
          'agent_notes_like'            => '',
          'area'                        => '',
          'bom_date'                    => '',                    
          'city'                        => '',
          'city_code'                   => '',
          'co_la_code'                  => '',
          'co_lo_code'                  => '',
          'co_sa_code'                  => '',
          'co_so_code'                  => '',          
          'converted'                   => '',
          'county'                      => '',
          'current_price_gte'           => '',
          'current_price_lte'           => '',
          'date_created_gte'            => '',
          'date_created_lte'            => '',
          'date_modified_gte'           => '',
          'date_modified_lte'           => '',          
          'elem_school'                 => '',          
          'ftr_access_like'             => '',          
          'ftr_lotdesc_like'            => '',
          'ftr_mineralrights'           => '',                    
          'ftr_zoning'                  => '',          
          'high_school'                 => '',
          'internet_yn'                 => '',
          'la_code'                     => '',          
          'list_date_gte'               => '',
          'list_date_lte'               => '',
          'list_price_gte'              => '',
          'list_price_lte'              => '',          
          'lo_code'                     => '',
          'middle_school'               => '',
          'mls_acct'                    => '',
          'municipality'                => '',
          'parcel_id'                   => '',
          'prop_type'                   => '',
          'remarks_like'                => '',          
          'sa_code'                     => '',                    
          'so_code'                     => '',          
          'state'                       => '',
          'status'                      => 'Active',
          'street_name_like'            => '',
          'street_num_like'             => '',          
          'subdivision'                 => '',          
          'unit_num'                    => '',          
          'waterfront'                  => '',
          'waterfront_yn'               => '',
          'zip'                         => ''    
        },{
          'model'           => 'CabooseRets::LandProperty',
          'sort'            => 'current_price DESC, mls_acct',          
          'desc'            => false,
          'skip'            => ['status'],
          'base_url'        => '/land/search',          
          'items_per_page'  => 10
      })
      
      @properties = @gen.items
      if params[:waterfront].present? then @properties.reject!{|p| p.waterfront.blank?} end
    end
    
    # GET /land/:mls_acct/details
    def details
      @property = CabooseRets::LandProperty.where(:mls_acct => params[:mls_acct]).first
      @saved = logged_in? && SavedProperty.where(:user_id => logged_in_user.id, :mls_acct => params[:mls_acct]).exists?
      if @property.nil?
        @mls_acct = params[:mls_acct]
        render 'land/not_exists'
        return
      end    
    end
    
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # GET /admin/land
    def admin_index
      return if !user_is_allowed('properties', 'view')
        
      @gen = Caboose::PageBarGenerator.new(params, {
          'name'       => ''
      },{
          'model'       => 'CabooseRets::LandProperty',
          'sort'        => 'mls_acct',
          'desc'        => false,
          'base_url'    => '/admin/land'
      })
      @properties = @gen.items    
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/land/:mls_acct/edit
    def admin_edit
      return if !user_is_allowed('properties', 'edit')    
      @property = LandProperty.where(:mls_acct => params[:mls_acct]).first
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/land/:mls_acct/refresh
    def admin_refresh
      p = LandProperty.find(params[:mls_acct])        
      RetsImporter.import("(MLS_ACCT=#{p.mls_acct})", 'Property', 'LND')
      RetsImporter.download_property_images(p)
      render :json => Caboose::StdClass.new({ 'success' => "The property's info has been updated from MLS." })
    end
   
  end
end