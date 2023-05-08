class CabooseRets::Schema < Caboose::Utilities::Schema

  # Tables (in order) that were renamed in the development of the gem.
  def self.renamed_tables
    {
      :property              => :rets_properties
    }
  end

  def self.removed_columns
    {
      CabooseRets::SavedProperty => [:mls_acct]
    }
  end

  # The schema of the database
  # { Model => [[name, data_type, options]] }
  def self.schema
    {
      CabooseRets::Agent => [
        [ :agent_number                 , :text    ],
        [ :cell_phone                   , :text    ],
        [ :direct_work_phone            , :text    ],
        [ :email                        , :text    ],
        [ :fax_phone                    , :text    ],
        [ :first_name                   , :text    ],
        [ :full_name                    , :text    ],
        [ :generational_name            , :text    ],
        [ :last_name                    , :text    ],
        [ :matrix_unique_id             , :text    ],
        [ :matrix_modified_dt           , :text    ],
        [ :middle_name                  , :text    ],
        [ :mls                          , :text    ],
        [ :mls_id                       , :text    ],
        [ :office_mui                   , :text    ],
        [ :office_mls_id                , :text    ],
        [ :office_phone                 , :text    ],
        [ :other_phone                  , :text    ],
        [ :phone_toll_free              , :text    ],
        [ :phone_voice_mail             , :text    ],
        [ :photo_count                  , :text    ],
        [ :photo_modification_timestamp , :text    ],
        [ :sort_order                   , :integer ],
        [ :slug                         , :text     ],
        [ :last_updated                 , :datetime ]
      ],
      CabooseRets::AgentMeta => [
        [ :la_code             , :string     ],
        [ :hide                , :boolean     , { :default => false }],
        [ :bio                 , :text       ],
        [ :contact_info        , :text       ],
        [ :assistant_to        , :string     ],
        [ :designation         , :string     ],
        [ :image_location      , :string     ],
        [ :image               , :attachment ],
        [ :accepts_listings             , :boolean     , { :default => true }],
        [ :weight              , :float       , { :default => 1 } ]
      ], 
      CabooseRets::Office => [
        [ :lo_addr1                     , :text ],
        [ :lo_addr2                     , :text ],
        [ :lo_city                      , :text ],
        [ :lo_email                     , :text ],
        [ :lo_fax_phone                 , :text ],
        [ :lo_mail_addr                 , :text ],
        [ :lo_mail_care_of              , :text ],
        [ :lo_mail_city                 , :text ],        
        [ :lo_mail_postal_code          , :text ],
        [ :lo_mail_postal_code_plus4    , :text ],
        [ :lo_mail_state_or_province    , :text ],
        [ :matrix_unique_id             , :text ],
        [ :lo_matrix_modified_dt        , :text ],
        [ :lo_mls                       , :text ],
        [ :lo_mls_id                    , :text ],
        [ :lo_office_contact_mui        , :text ],
        [ :lo_office_contact_mls_id     , :text ],        
        [ :lo_office_long_name          , :text ],
        [ :lo_office_name               , :text ],
        [ :lo_phone                     , :text ],
        [ :lo_photo_count               , :text ],
        [ :photo_modification_timestamp , :text ],        
        [ :state                        , :text ],
        [ :street_address               , :text ],
        [ :street_city                  , :text ],
        [ :street_postal_code           , :text ],
        [ :street_postal_code_plus4     , :text ],
        [ :street_state_or_province     , :text ],
        [ :web_facebook                 , :text ],
        [ :web_linked_in                , :text ],
        [ :web_page_address             , :text ],
        [ :web_twitter                  , :text ],
        [ :zip                          , :text ]
      ],
      CabooseRets::OpenHouse => [
        [ :active_yn          , :text ],
        [ :description        , :text ],
        [ :end_time           , :text ],
        [ :entry_order        , :text ],
        [ :listing_mui        , :text ],
        [ :matrix_unique_id   , :text ],
        [ :matrix_modified_dt , :text ],
        [ :open_house_date    , :text ],
        [ :open_house_type    , :text ],
        [ :provider_key       , :text ],
        [ :refreshments       , :text ],
        [ :start_time         , :text ],
        [ :hide, :boolean     , { :default => false }]
      ],
      CabooseRets::Property => [
        [ :alternate_link                       , :string],
        [ :access                               , :text],
        [ :acreage                              , :decimal],
        [ :acreage_source                       , :text],
        [ :active_open_house_count              , :text],
        [ :adjoining_land_use                   , :text],
        [ :age                                  , :text],
        [ :annual_taxes                         , :text],
        [ :appliances                           , :text],
        [ :area                                 , :text],
        [ :attic                                , :text],
        [ :available_date                       , :text],
        [ :basement                             , :text],
        [ :basement_yn                          , :text],
        [ :baths_full                           , :integer],
        [ :baths_half                           , :integer],
        [ :baths_total                          , :decimal],
        [ :beds_total                           , :integer],
        [ :book_number                          , :text],
        [ :book_page                            , :text],
        [ :book_type                            , :text],
        [ :building_type                        , :text],
        [ :business_included_yn                 , :text],
        [ :buyer_name                           , :text],
        [ :city                                 , :text],
        [ :city_community                       , :text],
        [ :closing                              , :text],
        [ :co_list_agent_mui                    , :text],
        [ :co_list_agent_direct_work_phone      , :text],
        [ :co_list_agent_full_name              , :text],
        [ :co_list_agent_email                  , :text],
        [ :co_list_agent_mls_id                 , :text],
        [ :co_list_office_mui                   , :text],
        [ :co_list_office_mls_id                , :text],
        [ :co_list_office_name                  , :text],
        [ :co_list_office_phone                 , :text],
        [ :completion_date                      , :text],
        [ :comp_tenant_rep                      , :text],
        [ :construction                         , :text],
        [ :construction_status                  , :text],
        [ :cooling                              , :text],
        [ :county_or_parish                     , :text],
        [ :current_price                        , :text],
        [ :date_created                         , :text],
        [ :date_leased                          , :text],
        [ :date_modified                        , :text],
        [ :deposit                              , :text],
        [ :dining_room                          , :text],
        [ :directions                           , :text],
        [ :display_address_on_internet_yn       , :text],
        [ :dom                                  , :text],
        [ :driveway                             , :text],
        [ :elementary_school                    , :text],
        [ :exists_struct                        , :text],
        [ :expenses_association                 , :text],
        [ :expenses_insurance                   , :text],
        [ :expenses_maintenance                 , :text],
        [ :expenses_management                  , :text],
        [ :expenses_other                       , :text],
        [ :expenses_tax                         , :text],
        [ :expenses_utility                     , :text],
        [ :exterior_features                    , :text],
        [ :fireplace                            , :text],
        [ :fireplace_features                   , :string ],
        [ :flood_plain                          , :text],
        [ :flooring                             , :text],
        [ :foreclosure_sale_date                , :text],
        [ :foreclosure_yn                       , :text],
        [ :fsboyn                               , :text],
        [ :garage                               , :text],
        [ :garage_spaces                        , :string ],
        [ :heating                              , :text],
        [ :high_school                          , :text],
        [ :hoa_amenities                        , :text],
        [ :hoa_fee                              , :text],
        [ :hoa_included_in_rent_yn              , :text],
        [ :hoa_term                             , :text],
        [ :hoa_term_mandatory_yn                , :text],
        [ :homestead_yn                         , :text],
        [ :idx_opt_in_yn                        , :text],
        [ :income_other                         , :text],
        [ :income_rental                        , :text],
        [ :interior_features                    , :text],
        [ :land_features_extras                 , :text],
        [ :landscaping                          , :text],
        [ :latitude                             , :float],
        [ :laundry                              , :text],
        [ :legal_description                    , :text],
        [ :legal_lot                            , :text],
        [ :legal_section                        , :text],
        [ :levels                               , :text],
        [ :list_agent_mui                       , :text],
        [ :list_agent_direct_work_phone         , :text],
        [ :list_agent_email                     , :text],
        [ :list_agent_full_name                 , :text],
        [ :list_agent_mls_id                    , :text],
        [ :listing_contract_date                , :text],
        [ :list_office_mui                      , :text],
        [ :list_office_mls_id                   , :text],
        [ :list_office_name                     , :text],
        [ :list_office_phone                    , :text],
        [ :list_price                           , :decimal],
        [ :longitude                            , :float],
        [ :lot_description                      , :text],
        [ :lot_dimensions                       , :text],
        [ :lot_dim_source                       , :text],
        [ :management                           , :text],
        [ :master_bed_level                     , :text],
        [ :matrix_unique_id                     , :text],
        [ :matrix_modified_dt                   , :text],
        [ :max_sqft                             , :text],
        [ :middle_school                        , :text],
        [ :mineral_rights                       , :text],
        [ :min_sqft                             , :text],
        [ :misc_indoor_featuresa                , :text],
        [ :mls                                  , :text],
        [ :mls_number                           , :text],
        [ :municipality                         , :text],
        [ :net_op_inc                           , :text],
        [ :open_house_count                     , :text],
        [ :open_house_public_count              , :text],
        [ :open_house_public_upcoming           , :text],
        [ :open_house_upcoming                  , :text],
        [ :original_entry_timestamp             , :text],
        [ :parcel_number                        , :text],
        [ :pending_date                         , :text],
        [ :pets_allowed_yn                      , :text],
        [ :photo_count                          , :text],
        [ :photo_modification_timestamp         , :text],
        [ :pool                                 , :text],
        [ :porch_patio                          , :text],
        [ :possession                           , :text],
        [ :possible_uses                        , :text],
        [ :postal_code                          , :text],
        [ :postal_code_plus4                    , :text],
        [ :price_per_acre                       , :text],
        [ :price_sqft                           , :text],
        [ :property_name                        , :text],
        [ :property_subtype                     , :text],
        [ :property_type                        , :text],
        [ :property_use                         , :text],
        [ :prop_mgmt_comp                       , :text],
        [ :public_remarks                       , :text],
        [ :refrigerator_included_yn             , :text],
        [ :rental_rate_type                     , :text],
        [ :rent_incl                            , :text],
        [ :representative_agent_mui             , :text],
        [ :res_style                            , :text],
        [ :restrictions                         , :text],
        [ :road_frontage                        , :text],
        [ :roof                                 , :text],
        [ :roofage                              , :text],
        [ :room_count                           , :text],
        [ :security_features                    , :text],
        [ :service_type                         , :text],
        [ :sewer                                , :text],
        [ :sold_terms                           , :text],
        [ :sprinkler                            , :text],
        [ :sqft_source                          , :text],
        [ :sqft_total                           , :decimal],
        [ :state_or_province                    , :text],
        [ :status                               , :text],
        [ :status_contractual_search_date       , :text],
        [ :street_dir_prefix                    , :text],
        [ :street_dir_suffix                    , :text],
        [ :street_name                          , :text],
        [ :street_number                        , :text],
        [ :street_number_numeric                , :text],
        [ :street_suffix                        , :text],
        [ :street_view_param                    , :text],
        [ :style                                , :text],
        [ :subdivision                          , :text],
        [ :topography                           , :text],
        [ :total_num_units                      , :text],
        [ :total_num_units_occupied             , :text],
        [ :transaction_type                     , :text],
        [ :unit_count                           , :text],
        [ :unit_number                          , :text],
        [ :utilities                            , :text],
        [ :virtual_tour1                        , :text],
        [ :vow_allowed_avmyn                    , :text],
        [ :vow_allowed_third_party_comm_yn      , :text],
        [ :washer_dryer_included                , :text],
        [ :water                                , :text],
        [ :waterfronts                          , :text],
        [ :waterfront_yn                        , :text],
        [ :water_heater                         , :text],
        [ :windows                              , :text],
        [ :window_treatments                    , :text],
        [ :year_built                           , :text],
        [ :yr_blt_source                        , :text],
        [ :zoning                               , :text],
        [ :zoning_northport                     , :text],
        [ :zoning_tusc                          , :text],
        [ :street_address                          , :text]
      ], 
      CabooseRets::Log => [
        [ :class_name, :string ],
        [ :object_id, :string ],
        [ :text, :text ],
        [ :timestamp, :datetime ]
      ],
      CabooseRets::Media => [
        [ :photo_modification_timestamp      , :string     ],
        [ :file_name                         , :string     ],
        [ :media_mui                         , :string     ],
        [ :media_order                       , :integer     , { :default => 0 }],
        [ :media_remarks                     , :text       ],
        [ :media_type                        , :text       ],
        [ :url                               , :text       ],
        [ :image                             , :attachment ],
        [ :file                              , :attachment ],
        [ :media                             , :bytea      ]
      ],
      CabooseRets::SavedProperty => [
        [ :user_id         , :integer ],
        [ :mls_number      , :string ],
        [ :date_saved,     :datetime ]
      ],
      CabooseRets::SavedSearch => [
        [ :user_id       , :integer   ],
        [ :params        , :text      ],
        [ :date_created  , :timestamp ],
        [ :date_last     , :timestamp ],
        [ :interval      , :integer   ],
        [ :property_type , :string    ],
        [ :uri           , :text      ],
        [ :notify        , :boolean   ]
      ],
      CabooseRets::SearchOption => [
        [ :name            , :string ],
        [ :field           , :string ],
        [ :value           , :string ],
        [ :flag_for_delete , :boolean , { :default => false }]
      ],
      Caboose::Site => [
        [ :use_rets , :boolean, { :default => false }]
      ],
      Caboose::User => [
        [ :rets_agent_mls_id , :string ]
      ],
      CabooseRets::Notification => [
        [ :user_id, :integer ],
        [ :date_sent, :datetime ],
        [ :site_id, :integer ],
        [ :kind, :string ],
        [ :sent_to, :string ],
        [ :object_kind, :string ],
        [ :object_id, :string ],
        [ :old_value, :string ],
        [ :new_value, :string ],
        [ :message, :text ]
      ],
      CabooseRets::RetsConfig => [
        [ :site_id, :integer ],
        [ :office_mls, :string ],
        [ :office_mui, :string ],
        [ :agent_mls, :string ],
        [ :agent_mui, :string ],
        [ :rets_url, :string ],
        [ :rets_username, :string ],
        [ :rets_password, :string ],
        [ :default_sort, :string ]
      ]
  }
end

  def self.load_data

    # bt = Caboose::BlockType.where(:name => 'layout_rets').first
    # if bt.nil?
    #     cat = Caboose::BlockTypeCategory.where(:name => 'Layouts').first
    #     bt = Caboose::BlockType.create(:name => 'layout_rets', :description => 'RETS Layout', :block_type_category_id => cat.id, :allow_child_blocks => false, :field_type => 'block')
    # end

    # Caboose::Site.where(:use_rets => true).reorder(:id).all.each do |site|
    #   home_page = Caboose::Page.index_page(site.id)

    #   # Check that the rets layout is applied to the site
    #   bt.add_to_site(site.id)

    #   # Verify that the site has all the rets pages created and each page has the rets layout
    #   rets_page = Caboose::Page.where(:site_id => site.id, :alias => 'rets').first
    #   rets_page = Caboose::Page.create(:site_id => site.id, :alias => 'rets', :slug => 'rets', :uri => 'rets', :title => 'RETS', :parent_id => home_page.id) if rets_page.nil?

    #   pages = []
    #   if !Caboose::Page.where(:site_id => site.id, :alias => 'property').exists?
    #     then pages << Caboose::Page.create(:site_id => site.id, :slug => 'properties'       , :alias => 'property'         , :uri => 'property'         , :title => 'Properties'              , :parent_id => rets_page.id)
    #   end    
    #   if !Caboose::Page.where(:site_id => site.id, :alias => 'open-houses'      ).exists?
    #     then pages << Caboose::Page.create(:site_id => site.id, :slug => 'open-houses'      , :alias => 'open-houses'      , :uri => 'open-houses'      , :title => 'Open Houses'             , :parent_id => rets_page.id)
    #   end
    #   if !Caboose::Page.where(:site_id => site.id, :alias => 'agents'           ).exists?
    #     then pages << Caboose::Page.create(:site_id => site.id, :slug => 'agents'           , :alias => 'agents'           , :uri => 'agents'           , :title => 'Agents'                  , :parent_id => rets_page.id)
    #   end
    #   if !Caboose::Page.where(:site_id => site.id, :alias => 'saved-searches'   ).exists?
    #     then pages << Caboose::Page.create(:site_id => site.id, :slug => 'saved-searches'   , :alias => 'saved-searches'   , :uri => 'saved-searches'   , :title => 'Saved Searches'          , :parent_id => rets_page.id)
    #   end
    #   if !Caboose::Page.where(:site_id => site.id, :alias => 'saved-properties' ).exists?
    #     then pages << Caboose::Page.create(:site_id => site.id, :slug => 'saved-properties' , :alias => 'saved-properties' , :uri => 'saved-properties' , :title => 'Saved Properties'        , :parent_id => rets_page.id)
    #   end

    #     pages.each do |p|
    #       Caboose::Block.where(:page_id =>  p.id).destroy_all
    #       Caboose::Block.create(:page_id => p.id, :block_type_id => bt.id, :name => bt.name)

    #       viewers = Caboose::PagePermission.where(:page_id => home_page.id, :action => 'view').pluck(:role_id)
    #       editors = Caboose::PagePermission.where(:page_id => home_page.id, :action => 'edit').pluck(:role_id)
    #       Caboose::Page.update_authorized_for_action(p.id, 'view', viewers)
    #       Caboose::Page.update_authorized_for_action(p.id, 'edit', editors)
    #     end
    #   end
  end


end
