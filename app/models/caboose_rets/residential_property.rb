      
class CabooseRets::ResidentialProperty < ActiveRecord::Base
  self.table_name = "rets_residential"
  attr_accessible :id, :mls_acct
  
  def url()     return "/residential/#{self.id}" end
  def agent()   return CabooseRets::Agent.where(:la_code => self.la_code).first end  
  def office()  return CabooseRets::Office.where(:lo_code => self.lo_code).first end  
  def images()  return CabooseRets::Media.where(:mls_acct => self.mls_acct, :media_type => 'Photo').reorder(:media_order).all end
  def files()   return CabooseRets::Media.where(:mls_acct => self.mls_acct, :media_type => 'File' ).reorder(:media_order).all end  
  def virtual_tour    
    return nil if !CabooseRets::Media.where(:mls_acct => self.mls_acct.to_s).where(:media_type => 'Virtual Tour').exists?
    media = CabooseRets::Media.where(:mls_acct => self.mls_acct.to_s, :media_type => 'Virtual Tour').first
    return media.url    
  end
  def self.geolocatable() all(conditions: "latitude IS NOT NULL AND longitude IS NOT NULL") end

  def refresh_from_mls        
    CabooseRets::RetsImporter.import("(MLS_ACCT=#{self.mls_acct})", 'Property', 'RES')
    CabooseRets::RetsImporter.download_property_images(self)
  end
  
  def self.import_from_mls(mls_acct)
    CabooseRets::RetsImporter.import_property(mls_acct)          
  end
  
  #=============================================================================
  
  # Assume this is running in a worker dyno
  def self.update_rets
    
    cri = CabooseRets::RetsImporter
      
    return if cri.task_is_locked
    task_started = cri.lock_task
    
    begin      
      cri.update_after(cri.last_updated)		  
		  cri.save_last_updated(task_started)
		  cri.unlock_task
		rescue
		  raise
		ensure
		  cri.unlock_task_if_last_updated(task_started)
		end
		
		# Start the same update process in five minutes
		self.delay(:run_at => 1.minutes.from_now).update_rets		
	end
	
	#=============================================================================
  
  def parse(data)
    self.bedrooms                        = data['BEDROOMS']
	  self.dom                             = data['DOM']
	  self.ftr_pool                        = data['FTR_POOL']
	  self.rm_other3_desc                  = data['RM_OTHER3_DESC']
	  self.baths_full                      = data['BATHS_FULL']
	  self.ftr_diningroom                  = data['FTR_DININGROOM']
	  self.ftr_porchpatio                  = data['FTR_PORCHPATIO']
	  self.rm_other3_name                  = data['RM_OTHER3_NAME']
	  self.baths_half                      = data['BATHS_HALF']
	  self.directions                      = data['DIRECTIONS']
	  self.ftr_possession                  = data['FTR_POSSESSION']
	  self.rm_other4                       = data['RM_OTHER4']
	  self.baths                           = data['BATHS']
	  self.display_address_yn              = data['DISPLAY_ADDRESS_YN']
	  self.current_price                   = data['CURRENT_PRICE']
	  self.rm_other4_desc                  = data['RM_OTHER4_DESC']
	  self.avm_automated_sales_disabled    = data['AVM_AUTOMATED_SALES_DISABLED']
	  self.ftr_drive                       = data['FTR_DRIVE']
	  self.price_change_date               = data['PRICE_CHANGE_DATE']
	  self.rm_other4_name                  = data['RM_OTHER4_NAME']
	  self.avm_instant_valuation_disabled  = data['AVM_INSTANT_VALUATION_DISABLED']
	  self.elem_school                     = data['ELEM_SCHOOL']
	  self.price_sqft                      = data['PRICE_SQFT']
	  self.rm_recrm                        = data['RM_RECRM']
	  self.acreage                         = data['ACREAGE']
	  self.expire_date                     = data['EXPIRE_DATE']
	  self.prop_type                       = data['PROP_TYPE']
	  self.rm_recrm_desc                   = data['RM_RECRM_DESC']
	  self.ftr_age                         = data['FTR_AGE']
	  self.ftr_exterior                    = data['FTR_EXTERIOR']
	  self.rm_bath1                        = data['RM_BATH1']
	  self.rm_study                        = data['RM_STUDY']
	  self.agent_notes                     = data['AGENT_NOTES']
	  self.ftr_citycommunit                = data['FTR_CITYCOMMUNIT']
	  self.rm_bath1_desc                   = data['RM_BATH1_DESC']
	  self.rm_study_desc                   = data['RM_STUDY_DESC']
	  self.agent_other_contact_desc        = data['AGENT_OTHER_CONTACT_DESC']
	  self.ftr_fireplace                   = data['FTR_FIREPLACE']
	  self.rm_bath2                        = data['RM_BATH2']
	  self.rm_sun                          = data['RM_SUN']
	  self.agent_other_contact_phone       = data['AGENT_OTHER_CONTACT_PHONE']
	  self.flood_plain                     = data['FLOOD_PLAIN']
	  self.rm_bath2_desc                   = data['RM_BATH2_DESC']
	  self.rm_sun_desc                     = data['RM_SUN_DESC']
	  self.annual_taxes                    = data['ANNUAL_TAXES']
	  self.foreclosure_yn                  = data['FORECLOSURE_YN']
	  self.rm_bath3                        = data['RM_BATH3']
	  self.remarks                         = data['REMARKS']
	  self.internet_yn                     = data['INTERNET_YN']
	  self.georesult                       = data['GEORESULT']
	  self.rm_bath3_desc                   = data['RM_BATH3_DESC']
	  self.right_red_date                  = data['RIGHT_RED_DATE']
	  self.ftr_appliances                  = data['FTR_APPLIANCES']
	  self.ftr_garage                      = data['FTR_GARAGE']
	  self.rm_br1                          = data['RM_BR1']
	  self.ftr_roof                        = data['FTR_ROOF']
	  self.tot_heat_sqft                   = data['TOT_HEAT_SQFT']
	  self.geo_precision                   = data['GEO_PRECISION']
	  self.rm_br1_desc                     = data['RM_BR1_DESC']
	  self.status_flag                     = data['STATUS_FLAG']
	  self.area                            = data['AREA']
	  self.ftr_hoaamenities                = data['FTR_HOAAMENITIES']
	  self.rm_br2                          = data['RM_BR2']
	  self.hoa_fee                         = data['HOA_FEE']
	  self.ftr_hoaincludes                 = data['FTR_HOAINCLUDES']
	  self.rm_br2_desc                     = data['RM_BR2_DESC']
	  self.sale_notes                      = data['SALE_NOTES']
	  self.hoa_term                        = data['HOA_TERM']
	  self.hoa_fee_yn                      = data['HOA_FEE_YN']
	  self.rm_br3                          = data['RM_BR3']
	  self.ftr_terms                       = data['FTR_TERMS']
	  self.ftr_attic                       = data['FTR_ATTIC']
	  self.ftr_heating                     = data['FTR_HEATING']
	  self.rm_br3_desc                     = data['RM_BR3_DESC']
	  self.sale_lease                      = data['SALE_LEASE']
	  self.ftr_docs_on_file                = data['FTR_DOCS_ON_FILE']
	  self.high_school                     = data['HIGH_SCHOOL']
	  self.rm_br4                          = data['RM_BR4']
	  self.owner_name                      = data['OWNER_NAME']
	  self.bom_date                        = data['BOM_DATE']
	  self.homestead_yn                    = data['HOMESTEAD_YN']
	  self.rm_br4_desc                     = data['RM_BR4_DESC']
	  self.owner_phone                     = data['OWNER_PHONE']
	  self.basement_yn                     = data['BASEMENT_YN']
	  self.ftr_interior                    = data['FTR_INTERIOR']
	  self.rm_br5                          = data['RM_BR5']
	  self.sa_code                         = data['SA_CODE']
	  self.ftr_basement                    = data['FTR_BASEMENT']
	  self.lease_exp_date                  = data['LEASE_EXP_DATE']
	  self.rm_br5_desc                     = data['RM_BR5_DESC']
	  self.so_code                         = data['SO_CODE']
	  self.book_number                     = data['BOOK_NUMBER']
	  self.ftr_landscaping                 = data['FTR_LANDSCAPING']
	  self.rm_brkfst                       = data['RM_BRKFST']
	  self.ftr_sewer                       = data['FTR_SEWER']
	  self.book_page                       = data['BOOK_PAGE']
	  self.ftr_laundry                     = data['FTR_LAUNDRY']
	  self.rm_brkfst_desc                  = data['RM_BRKFST_DESC']
	  self.ftr_showing                     = data['FTR_SHOWING']
	  self.book_type                       = data['BOOK_TYPE']
	  self.legals                          = data['LEGALS']
	  self.rm_den                          = data['RM_DEN']
	  self.sold_date                       = data['SOLD_DATE']
	  self.buyer_name                      = data['BUYER_NAME']
	  self.levels                          = data['LEVELS']
	  self.rm_den_desc                     = data['RM_DEN_DESC']
	  self.sold_price                      = data['SOLD_PRICE']
	  self.city_code                       = data['CITY_CODE']
	  self.list_price                      = data['LIST_PRICE']
	  self.rm_dining                       = data['RM_DINING']
	  self.sold_terms                      = data['SOLD_TERMS']
	  self.converted                       = data['CONVERTED']
	  self.list_date                       = data['LIST_DATE']
	  self.rm_dining_desc                  = data['RM_DINING_DESC']
	  self.sqft_source                     = data['SQFT_SOURCE']
	  self.currentlease_yn                 = data['CURRENTLEASE_YN']
	  self.status                          = data['STATUS']
	  self.rm_family                       = data['RM_FAMILY']
	  self.state                           = data['STATE']
	  self.category                        = data['CATEGORY']
	  self.listing_type                    = data['LISTING_TYPE']
	  self.rm_family_desc                  = data['RM_FAMILY_DESC']
	  self.street_dir                      = data['STREET_DIR']
	  self.city                            = data['CITY']
	  self.la_code                         = data['LA_CODE']
	  self.rm_foyer                        = data['RM_FOYER']
	  self.street_name                     = data['STREET_NAME']
	  self.co_la_code                      = data['CO_LA_CODE']
	  self.lo_code                         = data['LO_CODE']
	  self.rm_foyer_desc                   = data['RM_FOYER_DESC']
	  self.street_num                      = data['STREET_NUM']
	  self.co_lo_code                      = data['CO_LO_CODE']
	  self.ftr_lotdesc                     = data['FTR_LOTDESC']
	  self.rm_great                        = data['RM_GREAT']
	  self.style                           = data['STYLE']
	  self.co_so_code                      = data['CO_SO_CODE']
	  self.lot_dimensions                  = data['LOT_DIMENSIONS']
	  self.rm_great_desc                   = data['RM_GREAT_DESC']
	  self.subdivision                     = data['SUBDIVISION']
	  self.co_sa_code                      = data['CO_SA_CODE']
	  self.mls_acct                        = data['MLS_ACCT']
	  self.rm_kitchen                      = data['RM_KITCHEN']
	  self.take_photo_yn                   = data['TAKE_PHOTO_YN']
	  self.buyer_broker                    = data['BUYER_BROKER']
	  self.master_bed_lvl                  = data['MASTER_BED_LVL']
	  self.rm_kitchen2                     = data['RM_KITCHEN2']
	  self.upload_source                   = data['UPLOAD_SOURCE']
	  self.buyer_broker_type               = data['BUYER_BROKER_TYPE']
	  self.middle_school                   = data['MIDDLE_SCHOOL']
	  self.rm_kitchen2_desc                = data['RM_KITCHEN2_DESC']
	  self.unit_num                        = data['UNIT_NUM']
	  self.sub_agent                       = data['SUB_AGENT']
	  self.ftr_miscellaneous               = data['FTR_MISCELLANEOUS']
	  self.rm_kitchen_desc                 = data['RM_KITCHEN_DESC']
	  self.valuation_yn                    = data['VALUATION_YN']
	  self.sub_agent_type                  = data['SUB_AGENT_TYPE']
	  self.other_fee                       = data['OTHER_FEE']
	  self.rm_laundry                      = data['RM_LAUNDRY']
	  self.third_party_comm_yn             = data['THIRD_PARTY_COMM_YN']
	  self.contr_broker                    = data['CONTR_BROKER']
	  self.off_mkt_date                    = data['OFF_MKT_DATE']
	  self.rm_laundry_desc                 = data['RM_LAUNDRY_DESC']
	  self.vt_yn                           = data['VT_YN']
	  self.contr_broker_type               = data['CONTR_BROKER_TYPE']
	  self.off_mkt_days                    = data['OFF_MKT_DAYS']
	  self.rm_living                       = data['RM_LIVING']
	  self.ftr_warrantyprogrm              = data['FTR_WARRANTYPROGRM']
	  self.construction_date_comp          = data['CONSTRUCTION_DATE_COMP']
	  self.outlier_yn                      = data['OUTLIER_YN']
	  self.rm_living_desc                  = data['RM_LIVING_DESC']
	  self.wf_feet                         = data['WF_FEET']
	  self.ftr_construction                = data['FTR_CONSTRUCTION']
	  self.office_notes                    = data['OFFICE_NOTES']
	  self.rm_lrdr                         = data['RM_LRDR']
	  self.ftr_waterheater                 = data['FTR_WATERHEATER']
	  self.construction_status             = data['CONSTRUCTION_STATUS']
	  self.onsite_yn                       = data['ONSITE_YN']
	  self.rm_lrdr_desc                    = data['RM_LRDR_DESC']
	  self.ftr_watersupply                 = data['FTR_WATERSUPPLY']
	  self.contacts                        = data['CONTACTS']
	  self.onsite_days_hours               = data['ONSITE_DAYS_HOURS']
	  self.rm_master                       = data['RM_MASTER']
	  self.waterfront                      = data['WATERFRONT']
	  self.ftr_cooling                     = data['FTR_COOLING']
	  self.orig_lp                         = data['ORIG_LP']
	  self.rm_master_desc                  = data['RM_MASTER_DESC']
	  self.ftr_window_treat                = data['FTR_WINDOW_TREAT']
	  self.county                          = data['COUNTY']
	  self.other_fee_type                  = data['OTHER_FEE_TYPE']
	  self.rm_other1                       = data['RM_OTHER1']
	  self.ftr_windows                     = data['FTR_WINDOWS']
	  self.df_yn                           = data['DF_YN']
	  self.photo_count                     = data['PHOTO_COUNT']
	  self.rm_other1_desc                  = data['RM_OTHER1_DESC']
	  self.year_built                      = data['YEAR_BUILT']
	  self.date_modified                   = data['DATE_MODIFIED']
	  self.photo_date_modified             = data['PHOTO_DATE_MODIFIED']
	  self.rm_other1_name                  = data['RM_OTHER1_NAME']
	  self.year_built_source               = data['YEAR_BUILT_SOURCE']
	  self.status_date                     = data['STATUS_DATE']
	  self.prop_id                         = data['PROP_ID']
	  self.rm_other2                       = data['RM_OTHER2']
	  self.zip                             = data['ZIP']
	  self.date_created                    = data['DATE_CREATED']
	  self.parcel_id                       = data['PARCEL_ID']
	  self.rm_other2_desc                  = data['RM_OTHER2_DESC']
	  self.proj_close_date                 = data['PROJ_CLOSE_DATE']
	  self.pending_date                    = data['PENDING_DATE']
	  self.rm_other2_name                  = data['RM_OTHER2_NAME']
	  self.withdrawn_date                  = data['WITHDRAWN_DATE']
	  self.media_flag                      = data['MEDIA_FLAG']
	  self.rm_other3                       = data['RM_OTHER3']	  
	end
end
