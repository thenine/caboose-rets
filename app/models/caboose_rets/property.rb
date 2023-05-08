class CabooseRets::Property <ActiveRecord::Base
    self.table_name = "rets_properties"
    # attr_accessible :id, :matrix_unique_id, :mls_number, :alternate_link

    geocoded_by :full_address

    def url()     return "/properties/#{self.mls_number}/details" end
    def images()  return CabooseRets::Media.where(:media_mui => self.matrix_unique_id, :media_type => 'Photo').reorder(:media_order).all end
    def files()   return CabooseRets::Media.where(:media_mui => self.matrix_unique_id, :media_type => 'File' ).reorder(:media_order).all end
    def virtual_tour
        return nil if !CabooseRets::Media.where(:mls => self.mls.to_s).where(:media_type => 'Virtual Tour').exists?
        media = CabooseRets::Media.where(:mls => self.mls.to_s, :media_type => 'Virtual Tour').first
        return media.url
    end
    def self.geolocatable() all(conditions: "latitude IS NOT NULL AND longitude IS NOT NULL") end

    def refresh_from_mls
        CabooseRets::RetsImporter.import_properties(self.mls_number, true)
    end

    def featured_photo_url
        img_url = "https://cabooseit.s3.amazonaws.com/assets/pmre/house.png" 
        self.images.each do |img|
            m = Caboose::Media.where(:id => img.media_id).first
            if m && m.image && m.image.url(:large)
                img_url = m.image.url(:large)
                img_url = "https:#{img_url}" if !img_url.include?('http')
                return img_url
                break
            end
        end
        img_url = "https:#{img_url}" if !img_url.include?('http')
        return img_url
    end

    def dynamic_photo_url(site)
        domain = site.primary_domain.domain
        return "http://dev.pmre.com:3000/api/rets-properties/#{self.mls_number}/photo.jpg" if Rails.env.development?
        return "https://#{domain}/api/rets-properties/#{self.mls_number}/photo.jpg"
    end

    def agent
        CabooseRets::Agent.where(:mls_id => self.list_agent_mls_id).first
    end

    def office
        CabooseRets::Office.where(:lo_mls_id => self.list_office_mls_id).first
    end

    def full_address
        address = "#{self.unit_number.blank? ? '' : 'Unit ' + self.unit_number + ', '}#{self.street_number} #{self.street_dir_prefix.blank? ? '' : self.street_dir_prefix + ' '}#{self.street_name.blank? ? '' : self.street_name.titleize}#{self.street_suffix.blank? ? '' : ' ' + self.street_suffix.titleize}#{self.street_dir_suffix.blank? ? '' : ' ' + self.street_dir_suffix}"
        return address.blank? ? '' : address.gsub('Mc ','Mc').gsub('Mlk',"MLK").gsub(" Us ", " US ").gsub(" Th ", "th ").gsub("Mcfarland","McFarland")
    end

    def full_address_city
        address = "#{self.unit_number.blank? ? '' : 'Unit ' + self.unit_number + ', '}#{self.street_number} #{self.street_dir_prefix.blank? ? '' : self.street_dir_prefix + ' '}#{self.street_name.blank? ? '' : self.street_name.titleize}#{self.street_suffix.blank? ? '' : ' ' + self.street_suffix.titleize}#{self.street_dir_suffix.blank? ? '' : ' ' + self.street_dir_suffix}#{self.city.blank? ? '' : '<br />' + self.city.titleize + ', ' + self.state_or_province + ' ' + self.postal_code}"
        return address.blank? ? '' : address.gsub('Mc ','Mc').gsub('Mlk',"MLK").gsub(" Us ", " US ").gsub(" Th ", "th ").gsub("Mcfarland","McFarland")
    end

    def meta_description(site)
        fa = self.full_address_city.blank? ? nil : self.full_address_city.gsub("<br />",", ")
        return "View the property listed for sale at #{fa}. #{site.description}"
    end

    def parse(data)

        old_price = self.list_price
        old_status = self.status

    #    puts(data.to_s)
     #   self.access                           = nil
        self.acreage                          = data['LotSizeAcres'].blank? ? nil : data['LotSizeAcres'].to_f
        self.acreage_source                   = data['LotSizeSource']
     #   self.active_open_house_count          = data['ActiveOpenHouseCount']
     #   self.adjoining_land_use               = data['AdjoiningLandUse']
     #   self.age                              = data['Age']
        self.annual_taxes                     = data['TaxAnnualAmount']
        self.appliances                       = data['Appliances']
        self.area                             = data['MLSAreaMajor']
     #   self.attic                            = data['Attic']
        self.available_date                   = data['AvailabilityDate']
        self.basement                         = data['Basement']
    #    self.basement_yn                      = data['BasementYN']
        self.baths_full                       = data['BathroomsFull'].blank? ? nil : data['BathroomsFull'].to_i
        self.baths_half                       = data['BathroomsHalf'].blank? ? nil : data['BathroomsHalf'].to_i
        self.baths_total                      = data['BathroomsTotalInteger'].blank? ? nil : data['BathroomsTotalInteger'].to_f
        self.beds_total                       = data['BedroomsTotal'].blank? ? nil : data['BedroomsTotal'].to_i
        self.book_number                      = data['TaxBookNumber']
    #    self.book_page                        = data['BookPage']
    #    self.book_type                        = data['BookType']
    #    self.building_type                    = data['BuildingType']
        self.business_included_yn             = data['BusinessName']
        self.buyer_name                       = data['BuyerAgentFullName']
        self.city                             = data['City']
        self.city_community                   = data['CityRegion']
        self.closing                          = data['CloseDate']
        self.co_list_agent_mui                = data['CoListAgentMlsId']
        self.co_list_agent_direct_work_phone  = data['CoListAgentDirectPhone']
        self.co_list_agent_email              = data['CoListAgentEmail']
        self.co_list_agent_full_name          = data['CoListAgentFullName']
        self.co_list_agent_mls_id             = data['CoListAgentMlsId']
        self.co_list_office_mui               = data['CoListOfficeMlsId']
        self.co_list_office_mls_id            = data['CoListOfficeMlsId']
        self.co_list_office_name              = data['CoListOfficeName']
        self.co_list_office_phone             = data['CoListOfficePhone']
    #    self.completion_date                  = data['CompletionDate']
    #    self.comp_tenant_rep                  = data['CompTenantRep']
        self.construction                     = data['ConstructionMaterials']
        self.construction_status              = data['DevelopmentStatus']
        self.cooling                          = data['Cooling']
        self.county_or_parish                 = data['CountyOrParish']
     #   self.deposit                          = data['Deposit']
     #   self.dining_room                      = data['DiningRoom']
        self.directions                       = data['Directions']
        self.display_address_on_internet_yn   = data['InternetAddressDisplayYN']
     #   self.dom                              = data['DOM']
     #   self.driveway                         = data['Driveway']
        self.elementary_school                = data['ElementarySchool']
        self.exists_struct                    = data['StructureType']
        # self.expenses_association             = data['ExpensesAssociation'] 
        self.expenses_insurance               = data['InsuranceExpense']
        self.expenses_maintenance             = data['MaintenanceExpense']
        self.expenses_management              = data['ProfessionalManagementExpense']
        self.expenses_other                   = data['OtherExpense']
        self.expenses_tax                     = data['NewTaxesExpense']
        # self.expenses_utility                 = data['ExpensesUtility']
        self.exterior_features                = data['ExteriorFeatures']
        self.fireplace                        = data['FireplaceYN']
        self.fireplace_features               = data['FireplaceFeatures']
     #   self.flood_plain                      = data['FloodPlain']
        self.flooring                         = data['Flooring']
       # self.foreclosure_sale_date            = data['ForeclosureSaleDate']
      #  self.foreclosure_yn                   = data['ForeclosureYN']
      #  self.fsboyn                           = data['FSBOYN']
        self.garage                           = data['GarageYN']
        self.garage_spaces                    = data['GarageSpaces']
        self.heating                          = data['Heating']
        self.high_school                      = data['HighSchool']
        self.hoa_amenities                    = data['AssociationAmenities']
        self.hoa_fee                          = data['AssociationFee']
        self.hoa_included_in_rent_yn          = data['AssociationFeeIncludes']
        self.hoa_term                         = data['AssociationFeeFrequency']
        self.hoa_term_mandatory_yn            = data['AssociationYN']
     #   self.homestead_yn                     = data['HomesteadYN']
     #   self.idx_opt_in_yn                    = data['IDXOptInYN']
        self.income_other                     = data['GrossIncome']
     #   self.income_rental                    = data['GrossIncome']
        self.interior_features                = data['InteriorFeatures']
        self.land_features_extras             = data['LotFeatures']
        self.latitude                         = self.latitude.blank? ? nil : self.latitude
        self.longitude                        = self.longitude.blank? ? nil : self.longitude
        if self.latitude == 0.0 || self.latitude == '0.0' || self.longitude == 0.0 || self.longitude == '0.0' || (self.street_number != data['StreetNumber']) || (self.street_name != data['StreetName']) || (self.city != data['City']) || (self.postal_code != data['PostalCode'])
            self.latitude = nil
            self.longitude = nil
        end
        self.laundry                          = data['LaundryFeatures']
        self.legal_description                = data['TaxLegalDescription']
        self.legal_lot                        = data['TaxLot']
        self.legal_section                    = data['PublicSurveySection']
        self.levels                           = data['Levels']
        self.list_agent_mui                   = data['ListAgentMlsId']
        self.list_agent_direct_work_phone     = data['ListAgentOfficePhone']
        self.list_agent_email                 = data['ListAgentEmail']
        self.list_agent_full_name             = data['ListAgentFullName']
        self.list_agent_mls_id                = data['ListAgentMlsId']
        self.listing_contract_date            = data['ListingContractDate']
        self.list_office_mui                  = data['ListOfficeMlsId']
        self.list_office_mls_id               = data['ListOfficeMlsId']
        self.list_office_name                 = data['ListOfficeName']
        self.list_office_phone                = data['ListOfficePhone']
        self.list_price                       = data['ListPrice'].blank? ? self.list_price : data['ListPrice'].to_i
        
        self.lot_description                  = data['LotFeatures']
        self.lot_dimensions                   = data['LotSizeDimensions']
        self.lot_dim_source                   = data['LotDimensionsSource']
     #   self.management                       = data['Management']
     #   self.master_bed_level                 = data['MasterBedLevel']
        self.matrix_unique_id                 = data['ListingKey']
        self.matrix_modified_dt               = data['ModificationTimestamp']
        self.max_sqft                         = data['LivingArea']
        self.middle_school                    = data['MiddleOrJuniorSchool']
    #    self.mineral_rights                   = data['MineralRights']
        self.min_sqft                         = data['LivingArea']
        self.misc_indoor_featuresa            = data['BuildingFeatures']
        self.mls                              = data['ListingService']
        self.mls_number                       = data['ListingId']
     #   self.municipality                     = data['Municipality']
        self.net_op_inc                       = data['NetOperatingIncome']
        # self.open_house_count                 = data['OpenHouseCount']
        # self.open_house_public_count          = data['OpenHousePublicCount']
        # self.open_house_public_upcoming       = data['OpenHousePublicUpcoming']
        # self.open_house_upcoming              = data['OpenHouseUpcoming']
        self.original_entry_timestamp         = data['OriginalEntryTimestamp'].blank? ? data['OnMarketDate'] : data['OriginalEntryTimestamp']
        self.parcel_number                    = data['ParcelNumber']
        self.pending_date                     = data['PendingTimestamp']
        self.pets_allowed_yn                  = data['PetsAllowed']
        self.photo_count                      = data['PhotosCount']
        self.photo_modification_timestamp     = data['PhotosChangeTimestamp']
        self.pool                             = data['PoolFeatures']
        self.porch_patio                      = data['PatioAndPorchFeatures']
        self.possession                       = data['Possession']
        self.possible_uses                    = data['PossibleUse']
        self.postal_code                      = data['PostalCode']
        self.postal_code_plus4                = data['PostalCodePlus4']
     #   self.price_per_acre                   = data['PricePerAcre']
     #   self.price_sqft                       = data['PriceSqft']
    #    self.property_name                    = data['PropertyName']
        self.property_subtype                 = data['PropertySubType']
        self.property_type                    = data['PropertyType'].blank? ? nil : data['PropertyType'].gsub(" ","")
        self.property_use                     = data['CurrentUse']
        self.prop_mgmt_comp                   = data['ParkManagerName']
        self.public_remarks                   = data['PublicRemarks']
   #     self.refrigerator_included_yn         = data['RefrigeratorIncludedYN']
        self.rental_rate_type                 = data['RentControlYN']
        self.rent_incl                        = data['RentIncludes']
        self.res_style                        = data['ArchitecturalStyle']
    #    self.restrictions                     = data['Restrictions']
        self.road_frontage                    = data['RoadFrontageType']
        self.roof                             = data['Roof']
   #     self.roofage                          = data['Roofage']
        self.room_count                       = data['RoomsTotal'] 
   #     self.service_type                     = data['ServiceType'] 
        self.security_features                = data['SecurityFeatures']
        self.sewer                            = data['Sewer']
        self.sold_terms                       = data['ListingTerms']
     #   self.sprinkler                        = data['Sprinkler']
     
        self.sqft_source                      = data['LivingAreaSource']
        self.sqft_total                       = data['LivingArea'].blank? ? nil : data['LivingArea'].to_f
        self.state_or_province                = data['StateOrProvince']
        self.status                           = data['MlsStatus']
        self.status_contractual_search_date   = data['ContractStatusChangeDate']
        self.street_dir_prefix                = data['StreetDirPrefix']
        self.street_dir_suffix                = data['StreetDirSuffix']
        self.street_name                      = data['StreetName']
        self.street_number                    = data['StreetNumber']
        self.street_number_numeric            = data['StreetNumberNumeric']
        self.street_suffix                    = data['StreetSuffix']
   #     self.street_view_param                = data['StreetViewParam']
        self.style                            = data['BodyType']
        self.subdivision                      = data['SubdivisionName']
        self.topography                       = data['Topography']
        self.total_num_units                  = data['NumberOfUnitsTotal']
        self.total_num_units_occupied         = data['NumberOfUnitsLeased']
        self.transaction_type                 = data['TransactionBrokerCompensationType']
        self.unit_count                       = data['NumberOfUnitsInCommunity']
        self.unit_number                      = data['UnitNumber']
        self.utilities                        = data['Utilities']
        self.virtual_tour1                    = data['VirtualTourURLBranded'].blank? ? data['VirtualTourURLUnbranded'] : data['VirtualTourURLBranded']
   #     self.vow_allowed_avmyn                = data['VOWAllowAVMYN']
   #     self.vow_allowed_third_party_comm_yn  = data['VOWAllowThirdPartyCommYN']
   #     self.washer_dryer_included            = data['WasherDryerIncludedYN']
        self.water                            = data['WaterSource']
        self.waterfronts                      = data['WaterBodyName']
        self.waterfront_yn                    = data['WaterfrontYN']
    #    self.water_heater                     = data['WaterHeater']
        self.windows                          = data['WindowFeatures']
    #    self.window_treatments                = data['WindowTreatments']
        self.year_built                       = data['YearBuilt']
        self.yr_blt_source                    = data['YearBuiltSource']
        self.zoning                           = data['Zoning']
        # self.zoning_northport                 = data['ZoningNorthPort']
        # self.zoning_tusc                      = data['ZoningTusc']

        self.street_address = self.full_address


        if !old_status.blank? && old_status != self.status # status was changed
            CabooseRets::Notification.delay(:queue => "rets").property_status_changed(self, old_status)
        elsif !old_price.blank? && old_price != self.list_price && self.status == 'Active' # price was changed
            CabooseRets::Notification.delay(:queue => "rets").property_price_changed(self, old_price)
        end


    end
end
