
module CabooseRets
  class OfficesController < ApplicationController  

    #=============================================================================
    # Admin functions
    #=============================================================================
    
    # GET /admin/offices
    def admin_index
      return if !user_is_allowed('offices', 'view')
        
      @gen = Caboose::PageBarGenerator.new(params, {
          'lo_mls_id'    => '',               
          'lo_name_like' => ''      	  
        },{
      	  'model'       => 'CabooseRets::Office',
          'sort'			  => 'lo_name',
      	  'desc'			  => false,
      	  'base_url'		=> '/admin/offices',
      	  'use_url_params'  => false
      })
      @offices = @gen.items    
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/offices/:mls_number/edit
    def admin_edit
      return if !user_is_allowed('offices', 'edit')    
      @office = Office.find(params[:id])      
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/offices/:mls_number/refresh
    def admin_refresh
      office = Office.find(params[:id])        
      RetsImporter.delay(:priority => 10, :queue => 'rets').import('Office', "(Matrix_Unique_ID=#{office.matrix_unique_id})")
      render :json => Caboose::StdClass.new({ 'success' => "The office's info has been updated from MLS." })                
    end
  
    # GET /admin/offices/options
    def admin_options
      options = [{
        'value' => '',
        'text' => '-- No Office --'
      }]
      Office.reorder('lo_name').all.each do |office|
        options << { 
          'value' => office.lo_code,
          'text'  => office.lo_name
        }
      end
      render :json => options 
    end
  
  end
end
