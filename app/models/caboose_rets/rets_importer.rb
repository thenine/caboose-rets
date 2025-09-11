require 'oauth2'

class CabooseRets::RetsImporter # < ActiveRecord::Base

  @@rets_client = nil   
  @@rets_access = nil
  @@config = nil

  def self.config
    return @@config
  end

  def self.get_config
    @@config = {
      'endpoint'                 => nil,
      'token_endpoint'                 => nil,
      'client_id'            => nil,
      'client_secret'            => nil,
      'temp_path'           => nil,
      'log_file'            => nil
    }
    config = YAML::load(File.open("#{Rails.root}/config/rets_importer.yml"))    
    config = config[Rails.env]
    config.each { |key,val| @@config[key] = val }
  end

  def self.client
    self.get_config if @@config.nil? || @@config['url'].nil?
    if @@rets_client.nil?
      @@rets_client = ::OAuth2::Client.new(
        @@config['client_id'],
        @@config['client_secret'],
        site: @@config['endpoint'],
        token_url: @@config['token_endpoint'],
        connection_opts: {
          request: {
            open_timeout: 3,
            timeout: 5
          },
        },
      )
    end
    return @@rets_client
  end

  def self.access
    @@rets_access = self.client.client_credentials.get_token
  end

  def self.resource(resource_name, query, per_page = 100, count = false, select_column = nil, page_number = 1)

    params = {
      "$filter" => query,
      "$top" => per_page
    }

    extra_path = ""

    if count
      extra_path = "/$count"
    end

    if !select_column.blank?
      params["$select"] = select_column
    end

    if page_number > 1
      params["$skip"] = ((page_number - 1) * per_page)
    end

    url_path = "/trestle/odata/#{resource_name}#{extra_path}"

   # self.log3(resource_name, nil, "Making request to URL #{url_path} with params #{params}")

    response = self.access.get(url_path, params: params )

    if response && response.body
      if response.parsed['@odata.count']
        return response.parsed['@odata.count']
      else
        return response.parsed['value']
      end
    else
      return nil
    end
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError
    nil
  end

  def self.meta(class_type)
    case class_type
      when 'Office'    then Caboose::StdClass.new({ :search_type => 'Office'    , :remote_key_field => 'OfficeMlsId' , :local_key_field => 'lo_mls_id'    , :local_table => 'rets_offices'      , :date_modified_field => 'ModificationTimestamp'})
      when 'Member'    then Caboose::StdClass.new({ :search_type => 'Member'    , :remote_key_field => 'MemberMlsId' , :local_key_field => 'mls_id'    , :local_table => 'rets_agents'       , :date_modified_field => 'ModificationTimestamp'})
      when 'OpenHouse' then Caboose::StdClass.new({ :search_type => 'OpenHouse' , :remote_key_field => 'OpenHouseKey' , :local_key_field => 'matrix_unique_id'    , :local_table => 'rets_open_houses'  , :date_modified_field => 'ModificationTimestamp'})
      when 'Property'  then Caboose::StdClass.new({ :search_type => 'Property'  , :remote_key_field => 'ListingId' , :local_key_field => 'mls_number'    , :local_table => 'rets_properties'   , :date_modified_field => 'ModificationTimestamp'})
      when 'Media'     then Caboose::StdClass.new({ :search_type => 'Media'     , :remote_key_field => 'MediaObjectID'         , :local_key_field => 'media_id'            , :local_table => 'rets_media'        , :date_modified_field => 'ModificationTimestamp'   })
      end
  end

  #=============================================================================
  # Import method
  #=============================================================================

  def self.import_one_property(mls_number)
    response = self.resource('Property', "ListingId eq '#{mls_number}'")
    data = response ? response[0] : nil
   # self.log3('Property',nil,"WE GOT THE PROPERTY: #{data['ListingId']}") if data
    obj = data ? self.get_instance_with_id('Property', data) : nil
    if obj.nil?
      self.log3(class_type,nil,"Error: object is nil")
      self.log3(class_type,nil,data.inspect)
    else
      obj.parse(data)
      obj.save
    end
  end

  def self.import(class_type, query)
    m = self.meta(class_type)
    self.log3(class_type,nil,"Importing #{m.search_type}:#{class_type} with query #{query}...") 
    self.get_config if @@config.nil? || @@config['url'].nil?

    obj = nil

    begin
      results = self.resource(m.search_type, query)
      if results && results.count > 0
        results.each do |data|
          obj = self.get_instance_with_id(class_type, data)
          if obj.nil?
            self.log3(class_type,nil,"Error: object is nil")
            self.log3(class_type,nil,data.inspect)
            next
          end
          obj.parse(data)
          obj.save
        end
      end
    rescue
      self.log3(class_type,nil,"Import error for #{class_type}: #{query}")
      #self.log3(class_type,nil,err.message)
    end
  end

  def self.get_instance_with_id(class_type, data)
    obj = nil
    self.log "Getting instance of #{class_type}..."
    m = case class_type
      when 'Property'  then CabooseRets::Property
      when 'OpenHouse' then CabooseRets::OpenHouse
      when 'Member'    then CabooseRets::Agent
      when 'Office'    then CabooseRets::Office
      when 'Media'     then CabooseRets::Media
    end  
    obj  = case class_type
      when 'Property'  then m.where(:mls_number => data['ListingId']).exists? ? m.where(:mls_number => data['ListingId']).first : m.create(:mls_number => data['ListingId'])
      when 'OpenHouse' then m.where(:matrix_unique_id => data['OpenHouseKey']).exists? ? m.where(:matrix_unique_id => data['OpenHouseKey']).first : m.create(:matrix_unique_id => data['OpenHouseKey'])
      when 'Member'    then m.where(:mls_id => data['MemberMlsId']).exists? ? m.where(:mls_id => data['MemberMlsId']).first : m.create(:mls_id => data['MemberMlsId'])
      when 'Office'    then m.where(:lo_mls_id => data['OfficeMlsId']).exists? ? m.where(:lo_mls_id => data['OfficeMlsId']).first : m.create(:lo_mls_id => data['OfficeMlsId'])
      when 'Media'     then m.where(:media_id => data['MediaObjectID']      ).exists? ? m.where(:media_id => data['MediaObjectID']      ).first : m.create(:media_id => data['MediaObjectID']      )
    end
    self.log "Found matching object ID #{obj.id}"
    return obj
  end

  #=============================================================================
  # Main updater
  #=============================================================================

  def self.update_after(date_modified, save_images = true)
    si = save_images ? 'saving images' : 'not saving images'
    self.log3(nil,nil,"Updating everything after #{date_modified} and #{si}")
    self.delay(:priority => 10, :queue => 'rets').update_helper('Property' , date_modified, save_images)
    self.delay(:priority => 10, :queue => 'rets').update_helper('Office'   , date_modified, false)
    self.delay(:priority => 10, :queue => 'rets').update_helper('Member'   , date_modified, false)
    self.delay(:priority => 10, :queue => 'rets').update_helper('OpenHouse', date_modified, false)
  end

  def self.update_helper(class_type, date_modified, save_images = true)
    si = save_images ? 'saving images' : 'not saving images'
    self.log3(class_type,nil,"Updating #{class_type} modified after #{date_modified} and #{si}")
    m = self.meta(class_type)
    k = m.remote_key_field
    d = date_modified.in_time_zone(CabooseRets::timezone).strftime("%FT%TZ")

    statusquery = ""
    case class_type
      when 'Property'  then statusquery = "OriginatingSystemName eq 'WESTAL'"
      when 'Office'    then statusquery = "OfficeStatus eq 'Active'"
      when 'Member'    then statusquery = "MemberStatus eq 'Active'"
      when 'OpenHouse' then statusquery = "OpenHouseKeyNumeric gt 0"
    end

    query = "#{m.date_modified_field} gt #{d} and #{statusquery}"

    self.log3(class_type,nil,"Searching with query: " + query)

    results = self.resource(m.search_type, query, 1000)

    if results && results.count > 0
      results.each do |data|
       # self.log3(class_type,nil,"Resulting data: " + data.to_s)
        case class_type
          when 'Property'  then self.delay(:priority => 10, :queue => 'rets').import_properties(data[k], save_images)
          when 'Office'    then self.delay(:priority => 10, :queue => 'rets').import_office(    data[k], false)
          when 'Member'    then self.delay(:priority => 10, :queue => 'rets').import_agent(     data[k], false)
          when 'OpenHouse' then self.delay(:priority => 10, :queue => 'rets').import_open_house(data[k], false)
        end
      end
    end

    # Check for changed images
    if class_type == 'Property' && Rails.env.production?
      self.log3("Property",nil,"Checking for modified images on Properties...")
      d1 = (self.last_updated - 1.hours).in_time_zone(CabooseRets::timezone).strftime("%FT%TZ")

      query = "PhotosChangeTimestamp gt #{d1} and OriginatingSystemName eq 'WESTAL' and MlsStatus eq 'Active'"

      self.log3(class_type,nil,"Searching with query: " + query)

      results = self.resource(m.search_type, query, 1000)

      if results && results.count > 0
        results.each do |data|
         # self.log3(class_type,nil,"Resulting data: " + data.to_s)
          self.delay(:priority => 10, :queue => 'rets').import_properties(data[k], true)
        end
      end
    end

  end

  #=============================================================================
  # Single model import methods (called from a worker dyno)
  #=============================================================================

  def self.import_properties(mls_id, save_images = true)
    si = save_images ? 'saving images' : 'not saving images'
    self.log3('Property',mls_id,"Importing Property #{mls_id} and #{si}...")
    save_images = true if !CabooseRets::Property.where(:mls_number => mls_id.to_s).exists?
    self.import('Property', "ListingId eq '#{mls_id}'")
    p = CabooseRets::Property.where(:mls_number => mls_id.to_s).first
    if p != nil && p.status == 'Active'
      self.download_property_images(p) if save_images
      if p.latitude.blank? || p.latitude == '0.0' || p.longitude.blank? || p.longitude == '0.0'
        self.update_coords(p) 
      end
    else
      self.log3(nil,nil,"No Active Property associated with #{mls_id}, not downloading images")
    end
  end

  def self.import_office(mls_id, save_images = true)
    self.log3('Office',mls_id,"Importing Office #{mls_id}...")
    self.import('Office', "OfficeMlsId eq '#{mls_id}'")
    office = CabooseRets::Office.where(:matrix_unique_id => mls_id.to_s).first
  end

  def self.import_agent(mls_id, save_images = true)
    return if mls_id == "T/ISC-SA-MATRIXMONITOR"
    a = CabooseRets::Agent.where(:mls_id => mls_id.to_s).first
    if a.nil?
      self.log3('Agent',mls_id,"Importing new Agent #{mls_id}...")
      self.import('Member', "MemberMlsId eq '#{mls_id}'")
      a = CabooseRets::Agent.where(:mls_id => mls_id.to_s).first
      if a
        a.last_updated = DateTime.now
        a.save
      end
    else
      lu = a.last_updated.blank? ? 0 : a.last_updated.to_time.to_i
      now = DateTime.now.to_time.to_i
      diff = now - lu
      is_old = diff > 86400 # 24 hours
      if is_old
        self.log3('Agent',mls_id,"Updating existing Agent #{mls_id}...")
        self.import('Member', "MemberMlsId eq '#{mls_id}'")
        a.last_updated = DateTime.now
        a.save
      else
        self.log3('Agent',mls_id,"Skipping importing Agent #{mls_id} because last_updated is today...")
      end
    end
  end

  def self.import_open_house(oh_id, save_images = true)
    self.log3('OpenHouse',oh_id,"Importing Open House #{oh_id}...")
    self.import('OpenHouse', "OpenHouseKey eq '#{oh_id}'")
  end

  def self.import_media(id, save_images = true)
    self.log3('Media',id,"Importing Media #{id}...")
    self.import('Media', "MediaObjectID eq '#{id}'")
  end

  #=============================================================================
  # Images go here
  #=============================================================================

  def self.download_property_images(p)
   # return if Rails.env.development?
    self.log3('Property',p.mls_number,"Downloading images for #{p.mls_number}...")
    ids_to_keep = []
    begin

      query = "ResourceRecordKey eq '#{p.matrix_unique_id}'"
      photos = self.resource('Media',query,100)

      photos.each do |photo|
        ind = photo['Order']
        self.log3('Media',p.mls_number,"Downloading photo with order #{ind}")
        is_new = false
        m = CabooseRets::Media.where(:media_mui => photo['ResourceRecordKey'], :media_order => ind).first
        is_new = true if m.nil?
        m = CabooseRets::Media.new if m.nil?

        url = photo['MediaURL']
        m.media_mui     = photo['ResourceRecordKey']
        m.media_order   = ind
        m.media_type    = 'Photo'
        m.media_remarks = photo['ShortDescription']

        old_cm_id = is_new ? nil : m.media_id

        cm = Caboose::Media.where(:id => old_cm_id).first
        cm = Caboose::Media.create(:name => "rets_media_#{photo['ResourceRecordKey']}_#{ind}") if cm.nil?

        #cm.name          = "rets_media_#{photo['ResourceRecordKey']}_#{ind}"
        #cm.save

        m.media_id = cm ? cm.id : nil
        m.save
        ids_to_keep << m.id if m

        # Delete old caboose media if it exists
        # if !is_new
        #   old_media = Caboose::Media.where(:id => old_cm_id).first
        #   if old_media
        #     self.log3("Media",p.mls_number,"Deleting old CabooseMedia #{old_media.id}")
        #     old_media.destroy if Rails.env.production?
        #   end
        # end

        if Rails.env.production?
          cm.download_image_from_url(url)
        else
          puts "would download photo from URL #{url}"
        end

      end

    #   self.client.get_object(:resource => 'Property', :type => 'Photo', :location => false, :id => "#{p.matrix_unique_id}:*") do |headers, content|
    #     next if headers.blank?
    #     ind = headers['orderhint'] ? headers['orderhint'].to_i : 1 
    #     self.log3('Media',p.mls_number,headers.to_s)
    #     self.log3('Media',p.mls_number,"Downloading photo with content-id #{headers['content-id']}, index #{ind}")
    #     is_new = false
    #     m = CabooseRets::Media.where(:media_mui => headers['content-id'], :media_order => ind).first
    #     is_new = true if m.nil?
    #     m = CabooseRets::Media.new if m.nil?
    #     tmp_path = "#{Rails.root}/tmp/rets_media_#{headers['content-id']}_#{ind}.jpeg"
    #     File.open(tmp_path, "wb") do |f|
    #       f.write(content)
    #     end
    #     m.media_mui     = headers['content-id']
    #     m.media_order   = ind
    #     m.media_type    = 'Photo'
    #     cm = nil
    #     old_cm_id = is_new ? nil : m.media_id
    #     begin
    #       cm               = Caboose::Media.new
    #       cm.image         = File.open(tmp_path)
    #       cm.name          = "rets_media_#{headers['content-id']}_#{ind}"
    #       cm.original_name = "rets_media_#{headers['content-id']}_#{ind}.jpeg"
    #       cm.processed     = true
    #       cm.save
    #       if cm && !cm.id.blank?
    #         m.media_id = cm.id
    #         m.save
    #         ids_to_keep << m.id
    #         if is_new
    #           self.log3("Media",p.mls_number,"Created new RetsMedia object #{m.id}, media_id = #{m.media_id}")
    #         else
    #           old_media = Caboose::Media.where(:id => old_cm_id).first
    #           if old_media
    #             self.log3("Media",p.mls_number,"Deleting old CabooseMedia #{old_media.id}")
    #             old_media.destroy
    #           end
    #           self.log3("Media",p.mls_number,"RetsMedia object already existed #{m.id}, updated media_id = #{m.media_id}")
    #         end
    #         self.log3("Media",p.mls_number,"Image rets_media_#{headers['content-id']}_#{ind} saved")
    #       else
    #         self.log3("Media",p.mls_number,"CabooseMedia was not created for some reason, not saving RetsMedia")
    #       end
    #     rescue
    #       self.log3("Media",p.mls_number,"Error processing image #{ind} from RETS")
    #     end
    #     `rm #{tmp_path}`
    #   end

    rescue Exception => err
      self.log3("Media",p.mls_number,"Error downloading images for property with MLS # #{p.mls_number}: #{err}")
    end

    # If we downloaded new images, look for old images to delete. 
    if ids_to_keep.count > 0
      self.log3("Media",p.mls_number,"Keeping new RetsMedia ids: #{ids_to_keep}")
      self.log3("Media",p.mls_number,"Looking for old RetsMedia to delete")
      CabooseRets::Media.where(:media_mui => p.matrix_unique_id).where("id not in (?)",ids_to_keep).each do |med|
        self.log3("Media",p.mls_number,"Deleting old RetsMedia #{med.id} and CabooseMedia #{med.media_id}...")
        m = Caboose::Media.where(:id => med.media_id).where("name ILIKE ?","rets_media%").first
        m.destroy if m && Rails.env.production?
        med.destroy
      end
    end

  end

  def self.download_missing_images
    self.log3("Property",nil,"Downloading all missing images...")
    CabooseRets::Property.where("photo_count = ? OR photo_count is null", '').where(:status => "Active").all.each do |p|
      self.delay(:priority => 10, :queue => 'rets').import_properties(p.mls_number, true)
    end
  end

  def self.download_agent_image(agent)

  end

  def self.download_office_image(office)

  end

  #=============================================================================
  # GPS
  #=============================================================================

  def self.update_coords(p = nil)
    if p.nil?
      model = CabooseRets::Property      
      i = 0      
        self.log3('Property',nil,"Updating coords properties...")
        model.where(:latitude => nil).reorder(:mls_number).each do |p1|
          self.delay(:priority => 10, :queue => 'rets').update_coords(p1)
        end
      return
    end

    self.log3('Property',p.mls_number,"Getting coords for MLS # #{p.mls_number}...")
    coords = self.coords_from_address(CGI::escape "#{p.street_number} #{p.street_name}, #{p.city}, #{p.state_or_province} #{p.postal_code}")
    if coords.nil? || coords == false
      self.log3('Property',nil,"Can't set coords for MLS # #{p.mls_number}...")
      return
    end

    p.latitude = coords['lat'].to_f
    p.longitude = coords['lng'].to_f
    p.save
  end

  def self.coords_from_address(address)
    begin
      config = YAML::load(File.open("#{Rails.root}/config/rets_importer.yml"))    
      api_key = config[Rails.env]['google_api_key']
      uri = "https://maps.googleapis.com/maps/api/geocode/json?key=#{api_key}&address=#{address}"
      uri.gsub!(" ", "+")
      resp = HTTParty.get(uri)
      json = JSON.parse(resp.body)
      return json['results'][0]['geometry']['location']
    rescue
      self.log3("Property",nil,"Error with Geocoder API, url: #{uri}")
      sleep(2)
      return false
    end
  end

  #=============================================================================
  # Purging
  #=============================================================================

  def self.purge
    self.log3(nil,nil,'purging')
    self.purge_properties
    self.purge_offices
    self.purge_agents
    self.purge_open_houses
  end  
  
  def self.purge_properties()   self.delay(:priority => 10, :queue => 'rets').purge_helper('Property', '2012-01-01') end
  def self.purge_offices()      self.delay(:priority => 10, :queue => 'rets').purge_helper('Office', '2012-01-01') end
  def self.purge_agents()       self.delay(:priority => 10, :queue => 'rets').purge_helper('Member', '2012-01-01') end
  def self.purge_open_houses()  self.delay(:priority => 10, :queue => 'rets').purge_helper('OpenHouse', '2012-01-01') end
  

  # Adds/removes records in the database
  def self.purge_helper(class_type, date_modified)    
    m = self.meta(class_type)    
    self.log(m.search_type)

    self.log3(class_type,nil,"Purging #{class_type}...")

    # Get the total number of records
    self.log3(class_type,nil,"Getting total number of records for #{class_type}...")

    statusquery = ""

    case class_type
      when 'Property'  then statusquery = "MlsStatus eq 'Active'"
      when 'Office'    then statusquery = "OfficeStatus eq 'Active'"
      when 'Member'    then statusquery = "MemberStatus eq 'Active'"
      when 'OpenHouse' then statusquery = "OpenHouseKeyNumeric gt 0"
    end

    query = "#{m.date_modified_field} gt #{date_modified}T00:00:01Z and #{statusquery} and OriginatingSystemName eq 'WESTAL'"

    count = 0
    result = self.resource(class_type, query, 1, true, nil)
    
    count = result ? result.to_f : 0.0

    batch_count = (count.to_f/1000.0).ceil

    ids = []
    k = m.remote_key_field
    (0...batch_count).each do |i|
      self.log3(class_type,nil,"Getting ids for #{class_type} with key #{k} (batch #{i+1} of #{batch_count})...")
      results = self.resource(class_type, query, 1000, false, k, (i+1))
      results.each do |data|
        ids << data[k]
      end
    end

    # Only do stuff if we got a real response from the server 
    if ids.count > 0

      self.log3(class_type,nil,"Remote IDs found: #{ids.to_s}")

      # Delete any records in the local database that shouldn't be there
      self.log3(class_type,nil,"Finding #{class_type} records in the local database that are not in the remote database...")
      t = m.local_table
      k = m.local_key_field
      query = "select distinct #{k} from #{t}"
      rows = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql_array, query))
      local_ids = rows.collect{ |row| row[k] }
      self.log3(class_type,nil,"Local IDs found: #{local_ids.to_s}")
      ids_to_remove = local_ids - ids
      self.log3(class_type,nil,"Found #{ids_to_remove.count} #{class_type} records in the local database that are not in the remote database.")
      
      # Delete all RetsMedia and CabooseMedia for the deleted property listings (except keep the first image) 
      if class_type == 'Property' && ids_to_remove && ids_to_remove.count > 0
        self.log3(class_type,nil,"Deleting Media objects that shouldn't be there...")
        muis = CabooseRets::Property.where("#{k} in (?)", ids_to_remove).pluck(:matrix_unique_id)
        if muis && muis.count > 0 && Rails.env.production?
          CabooseRets::Media.where("media_mui in (?)", muis).where("media_order != ?", 1).each do |med|
            self.log3("Media",med.id,"Deleting old RetsMedia #{med.id} and CabooseMedia #{med.media_id}...")
            m = Caboose::Media.where(:id => med.media_id).where("name ILIKE ?","rets_media%").first
            m.destroy if m
            med.destroy
          end
        end
      end

      if class_type != 'Property' # keep all properties in the DB
        self.log3(class_type,nil,"Deleting #{class_type} records in the local database that shouldn't be there...")
        query = ["delete from #{t} where #{k} in (?)", ids_to_remove]
        ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, query))
      else # mark deleted properties as Deleted status
        self.log3(class_type,nil,"Setting deleted properties as Deleted status...")
        query = ["update #{t} set status = ? where #{k} in (?)", "Deleted", ids_to_remove]
        ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, query))
      end

      # Find any ids in the remote database that should be in the local database
      self.log3(class_type,nil,"Finding #{class_type} records in the remote database that should be in the local database...")
      query = "select distinct #{k} from #{t}"
      rows = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql_array, query))
      local_ids = rows.collect{ |row| row[k] }
      self.log3(class_type,nil,"Local IDs found: #{local_ids.to_s}")
      ids_to_add = ids - local_ids
      ids_to_add = ids_to_add.sort.reverse
      self.log3(class_type,nil,"Found #{ids_to_add.count} #{class_type} records in the remote database that we need to add to the local database.")
      ids_to_add.each do |id|
        self.log3(class_type,nil,"Importing #{id}...")
        case class_type
          when "Property"   then self.delay(:priority => 10, :queue => 'rets').import_properties(id, true)
          when "Office"    then self.delay(:priority => 10, :queue => 'rets').import_office(id, false)
          when "Member"     then self.delay(:priority => 10, :queue => 'rets').import_agent(id, false)
          when "OpenHouse" then self.delay(:priority => 10, :queue => 'rets').import_open_house(id, false)
        end
      end
    end
  end

  #=============================================================================
  # Logging
  #=============================================================================

  def self.log(msg)
    puts "[rets_importer] #{msg}"
  end

  def self.log2(msg)
    puts "======================================================================"
    puts "[rets_importer] #{msg}"
    puts "======================================================================"
  end

  def self.log3(class_name, object_id, text)
    self.log2(text)
    log = CabooseRets::Log.new
    log.class_name = class_name
    log.object_id = object_id
    log.text = text
    log.timestamp = DateTime.now
    log.save
  end

  #=============================================================================
  # Locking update task
  #=============================================================================

  def self.update_rets
    self.log3(nil,nil,"Updating rets...")
    if self.task_is_locked
      self.log2("Task is locked, aborting.")
      return
    end
    self.log2("Locking task...")
    task_started = self.lock_task
    begin
      overlap = 2.hours
      if (DateTime.now - self.last_purged).to_f >= 0.5
        self.purge
        self.save_last_purged(task_started)
        overlap = 1.week
      end
      self.update_after((self.last_updated - overlap), false)
      self.download_missing_images if Rails.env.production?
      self.log3(nil,nil,"Saving the timestamp for when we updated to #{task_started.to_s}...")
		  self.save_last_updated(task_started)
		  self.log2("Unlocking the task...")
		  self.unlock_task
		rescue Exception => err
		  puts err
		  raise
		ensure
		  self.log2("Unlocking task if last updated...")
		  self.unlock_task_if_last_updated(task_started)
    end
		# Start the same update process in 20 minutes
		self.log3(nil,nil,"Adding the update rets task for 20 minutes from now...")
		q = "handler like '%update_rets%'"
		count = Delayed::Job.where(q).count
		if count == 0 || (count == 1 && Delayed::Job.where(q).first.locked_at)
		  self.delay(:run_at => 20.minutes.from_now, :priority => 10, :queue => 'rets').update_rets
		end

    # Delete RETS logs over 7 days old
    dt = DateTime.now - 5.days
    sql = "delete from rets_logs where timestamp < '#{dt}';"
    ActiveRecord::Base.connection.select_all(sql)

    # Update search options
    CabooseRets::SearchOption.delay(:queue => "rets", :priority => 15).update_search_options
  end

  def self.last_updated
    if !Caboose::Setting.exists?(:name => 'rets_last_updated')
      Caboose::Setting.create(:name => 'rets_last_updated', :value => '2013-08-06T00:00:01')
    end
    s = Caboose::Setting.where(:name => 'rets_last_updated').first
    return DateTime.parse(s.value)
  end

  def self.last_purged
    if !Caboose::Setting.exists?(:name => 'rets_last_purged')
      Caboose::Setting.create(:name => 'rets_last_purged', :value => '2013-08-06T00:00:01')
    end
    s = Caboose::Setting.where(:name => 'rets_last_purged').first
    return DateTime.parse(s.value)
  end

  def self.save_last_updated(d)
    s = Caboose::Setting.where(:name => 'rets_last_updated').first
    s.value = d.in_time_zone(CabooseRets::timezone).strftime("%FT%T%:z")
    s.save
  end

  def self.save_last_purged(d)
    s = Caboose::Setting.where(:name => 'rets_last_purged').first
    s.value = d.in_time_zone(CabooseRets::timezone).strftime("%FT%T%:z")
    s.save
  end

  def self.task_is_locked
    return Caboose::Setting.exists?(:name => 'rets_update_running')
  end

  def self.lock_task
    d = DateTime.now.utc.in_time_zone(CabooseRets::timezone)
    Caboose::Setting.create(:name => 'rets_update_running', :value => d.strftime("%FT%T%:z"))
    return d
  end

  def self.unlock_task
    Caboose::Setting.where(:name => 'rets_update_running').first.destroy
  end

  def self.unlock_task_if_last_updated(d)
    setting = Caboose::Setting.where(:name => 'rets_update_running').first
    self.unlock_task if setting && d.in_time_zone.strftime("%FT%T%:z") == setting.value
  end

end
