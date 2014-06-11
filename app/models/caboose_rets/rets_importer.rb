require 'ruby-rets'
require 'httparty'
require 'json'

# http://rets.solidearth.com/ClientHome.aspx

class CabooseRets::RetsImporter # < ActiveRecord::Base
   
  @@rets_client = nil
  @@config = nil
  @@object_types = {
    'OpenHouse' => ['OPH'],
    'Media'     => ['GFX'],
    'Property'  => ['COM', 'LND', 'MUL', 'RES'],
    'Agent'     => ['AGT'],
    'Office'    => ['OFF']
  }
  @@key_fields = {
    'OpenHouse' => 'ID',
    'Media'     => 'MEDIA_ID',
    'Property'  => 'MLS_ACCT',
    'Agent'     => 'LA_LA_CODE',
    'Office'    => 'LO_LO_CODE'
  }
  @@models = {
    'OPH' => 'CabooseRets::OpenHouse',
    'GFX' => 'CabooseRets::Media',
    'COM' => 'CabooseRets::CommercialProperty',
    'LND' => 'CabooseRets::LandProperty',
    'MUL' => 'CabooseRets::MultiFamilyProperty',
    'RES' => 'CabooseRets::ResidentialProperty',
    'AGT' => 'CabooseRets::Agent',
    'OFF' => 'CabooseRets::Office'
  }
  @@date_modified_fields = {
    'OPH' => 'DATE_MODIFIED',
    'GFX' => 'DATE_MODIFIED',
    'COM' => 'DATE_MODIFIED',
    'LND' => 'DATE_MODIFIED',
    'MUL' => 'DATE_MODIFIED',
    'RES' => 'DATE_MODIFIED',
    'AGT' => 'LA_DATE_MODIFIED',
    'OFF' => 'LO_DATE_MODIFIED'
  }

  def self.config
    return @@config
  end
    
  def self.get_config
    @@config = {
      'url'                 => nil, # URL to the RETS login
      'username'            => nil,
      'password'            => nil,
      'limit'               => nil, # How many records to limit per request
      'days_per_batch'      => nil, # When performing a large property import, how many days to search on per batch 
      'temp_path'           => nil,
      'log_file'            => nil,
      'media_base_url'      => nil
    }
    config = YAML::load(File.open("#{Rails.root}/config/rets_importer.yml"))
    config = config[Rails.env]
    config.each { |key,val| @@config[key] = val }
  end
             
  def self.client
    self.get_config if @@config.nil? || @@config['url'].nil?
        
    if (@@rets_client.nil?)     
      @@rets_client = RETS::Client.login(
        :url      => @@config['url'],
        :username => @@config['username'],
        :password => @@config['password']
      )
    end
    return @@rets_client
  end
  
  #=============================================================================
  # Main updater
  #=============================================================================
  
  def self.update_after(date_modified)    
    self.update_data_after(date_modified)
    self.update_images_after(date_modified)
  end
  
  def self.update_data_after(date_modified)
    self.get_config if @@config.nil? || @@config['url'].nil?            
    self.import_modified_after(date_modified, 'Agent'     , 'AGT')
    self.import_modified_after(date_modified, 'Office'    , 'OFF')
    self.import_modified_after(date_modified, 'OpenHouse' , 'OPH')        
    #self.import_modified_after(date_modified, 'Property'  , 'COM')
    self.import_modified_after(date_modified, 'Property'  , 'LND')
    self.import_modified_after(date_modified, 'Property'  , 'MUL')
    self.import_modified_after(date_modified, 'Property'  , 'RES')
  end
  
  def self.update_images_after(date_modified)
    self.get_config if @@config.nil? || @@config['url'].nil?    
    self.download_agent_images_modified_after(date_modified)
    self.download_property_images_modified_after(date_modified)
  end
  
  #=============================================================================
  # Data
  #=============================================================================
  
  def self.import_property(mls_acct)    
    
    self.import("(MLS_ACCT=*#{mls_acct}*)", 'Property', 'RES')
    p = CabooseRets::ResidentialProperty.where(:id => mls_acct.to_i).first
    if p.nil?
      self.import("(MLS_ACCT=*#{mls_acct}*)", 'Property', 'COM')
      p = CabooseRets::CommercialProperty.where(:id => mls_acct.to_i).first      
      if p.nil?
        self.import("(MLS_ACCT=*#{mls_acct}*)", 'Property', 'LND')
        p = CabooseRets::LandProperty.where(:id => mls_acct.to_i).first
        if p.nil?
          self.import("(MLS_ACCT=*#{mls_acct}*)", 'Property', 'MUL')
          p = CabooseRets::MultiFamilyProperty.where(:id => mls_acct.to_i).first
          return if p.nil?
        end
      end
    end
    self.download_property_images(p)
  end
  
  def self.import_modified_after(date_modified, search_type = nil, class_type = nil)
    self.get_config if @@config.nil? || @@config['url'].nil?
                
    d = date_modified
    date_modified_field = @@date_modified_fields[class_type]
    
    while d.strftime('%FT%T') <= DateTime.now.strftime('%FT%T') do      
      break if d.nil?
    
      d2 = d.strftime('%FT%T')
      d2 << "-"
      d2 << (d+@@config['days_per_batch']).strftime('%FT%T')
            
      query = "(#{date_modified_field}=#{d2})"            
      self.import(query, search_type, class_type)
      
      d = d + @@config['days_per_batch']
    end
  end
  
  def self.import(query, search_type, class_type)
    # See how many records we have
    self.client.search(
      :search_type => search_type,
      :class => class_type,
      :query => query,
      :count_mode => :only,
      :timeout => -1,
    )
    # Return if no records found
    if (self.client.rets_data[:code] == "20201")
      self.log "No #{search_type}:#{class_type} records found for query: #{query}"
      return
    else
      count = self.client.rets_data[:count]            
      self.log "Importing #{count} #{search_type}:#{class_type} record" + (count == 1 ? "" : "s") + "..."
    end

    count = self.client.rets_data[:count]    
    batch_count = (count.to_f/@@config['limit'].to_f).ceil
    
    (0...batch_count).each do |i|      
      params = {
        :search_type => search_type,
        :class => class_type,
        :query => query,
        :limit => @@config['limit'],
        :offset => @@config['limit'] * i,
        :timeout => -1
      }
      obj = nil
      self.client.search(params) do |data|        
        m = @@models[class_type]
        #key_field = @@key_fields[search_type]
        #id = data[key_field].to_i
        #obj = m.exists?(id) ? m.find(id) : m.new
        obj = self.get_instance_with_id(m, data)
        if obj.nil?
          puts "Error: object is nil"
          puts m.inspect
          puts data.inspect
          next
        end
        obj.parse(data)
        #obj.id = id
        obj.save        
      end
      
      case obj
        when CabooseRets::CommercialProperty, CabooseRets::LandProperty, CabooseRets::MultiFamilyProperty, CabooseRets::ResidentialProperty
          self.update_coords(obj)
      end      
    end
  end
  
  def self.get_instance_with_id(model, data)            
    obj = nil
    m = model.constantize
    case model
      when 'CabooseRets::OpenHouse'             then obj = m.where(:id       => data['ID'].to_i       ).exists? ? m.where(:id       => data['ID'].to_i       ).first : m.new(:id       => data['ID'].to_i       )
      when 'CabooseRets::Media'                 then obj = m.where(:media_id => data['MEDIA_ID']      ).exists? ? m.where(:media_id => data['MEDIA_ID']      ).first : m.new(:media_id => data['MEDIA_ID']      )
      when 'CabooseRets::CommercialProperty'    then obj = m.where(:id       => data['MLS_ACCT'].to_i ).exists? ? m.where(:id       => data['MLS_ACCT'].to_i ).first : m.new(:id       => data['MLS_ACCT'].to_i )
      when 'CabooseRets::LandProperty'          then obj = m.where(:id       => data['MLS_ACCT'].to_i ).exists? ? m.where(:id       => data['MLS_ACCT'].to_i ).first : m.new(:id       => data['MLS_ACCT'].to_i )   
      when 'CabooseRets::MultiFamilyProperty'   then obj = m.where(:id       => data['MLS_ACCT'].to_i ).exists? ? m.where(:id       => data['MLS_ACCT'].to_i ).first : m.new(:id       => data['MLS_ACCT'].to_i )   
      when 'CabooseRets::ResidentialProperty'   then obj = m.where(:id       => data['MLS_ACCT'].to_i ).exists? ? m.where(:id       => data['MLS_ACCT'].to_i ).first : m.new(:id       => data['MLS_ACCT'].to_i )   
      when 'CabooseRets::Agent'                 then obj = m.where(:la_code  => data['LA_LA_CODE']    ).exists? ? m.where(:la_code  => data['LA_LA_CODE']    ).first : m.new(:la_code  => data['LA_LA_CODE']    )
      when 'CabooseRets::Office'                then obj = m.where(:lo_code  => data['LO_LO_CODE']    ).exists? ? m.where(:lo_code  => data['LO_LO_CODE']    ).first : m.new(:lo_code  => data['LO_LO_CODE']    )
    end
    return obj    
  end
  
  #=============================================================================
  # Agent Images
  #=============================================================================
  
  def self.download_agent_images_modified_after(date_modified, agent = nil)
    if agent.nil?
      CabooseRets::Agent.where('photo_date_modified > ?', date_modified.strftime('%FT%T')).reorder('last_name, first_name').all.each do |a|
        self.download_agent_images_modified_after(date_modified, a)
      end
      return
    end
    self.download_agent_images(agent)
  end
  
  def self.download_agent_images(agent)    
    a = agent    
    self.log "Saving image for #{a.first_name} #{a.last_name}..."
    begin
      self.client.get_object(:resource => :Agent, :type => :Photo, :location => true, :id => a.la_code) do |headers, content|
        a.image = URI.parse(headers['location'])
        a.save
      end
    rescue RETS::APIError => err
      self.log "No image for #{a.first_name} #{a.last_name}."
    end    
  end
  
  #=============================================================================
  # Property Images
  #=============================================================================
  
  def self.download_property_images_modified_after(date_modified)
    models = [CabooseRets::CommercialProperty, CabooseRets::LandProperty, CabooseRets::MultiFamilyProperty, CabooseRets::ResidentialProperty]
    names = ["commercial", "land", "multi-family", "residential"]
    i = 0
    models.each do |model|            
      count = model.where("photo_date_modified > ?", date_modified.strftime('%FT%T')).count
      j = 1      
      model.where("photo_date_modified > ?", date_modified.strftime('%FT%T')).reorder(:mls_acct).each do |p|        
        self.log("Downloading images for #{j} of #{count} #{names[i]} properties...")
        self.download_property_images(p)
        j = j + 1
      end
      i = i + 1
    end    
  end
    
  def self.download_property_images(p)
    self.refresh_property_media(p)
    
    self.log("-- Downloading images and resizing for #{p.mls_acct}")
    media = []
    self.client.get_object(:resource => :Property, :type => :Photo, :location => true, :id => p.id) do |headers, content|
      
      # Find the associated media record for the image
      filename = File.basename(headers['location'])
      m = CabooseRets::Media.where(:mls_acct => p.mls_acct, :file_name => filename).first
      
      if m.nil?
        self.log("Can't find media record for #{p.mls_acct} #{filename}.")
      else         
        m.image = URI.parse(headers['location'])
        media << m
        #m.save
      end      
    end
    
    self.log("-- Uploading images to S3 for #{p.mls_acct}")
    media.each do |m|      
      m.save
    end        
  end
  
  def self.refresh_property_media(p)
    self.log("-- Deleting images and metadata for #{p.mls_acct}...")    
    #CabooseRets::Media.where(:mls_acct => p.mls_acct, :media_type => 'Photo').destroy_all
    CabooseRets::Media.where(:mls_acct => p.mls_acct).destroy_all
    
    self.log("-- Downloading image metadata for #{p.mls_acct}...")    
    params = {
      :search_type => 'Media',
      :class => 'GFX',
      #:query => "(MLS_ACCT=*#{p.id}*),(MEDIA_TYPE=|I)",
      :query => "(MLS_ACCT=*#{p.id}*)",
      :timeout => -1
    }    
    self.client.search(params) do |data|      
      m = CabooseRets::Media.new
      m.parse(data)
      #m.id = m.media_id
      m.save
    end
  end
  
  def self.refresh_all_virtual_tours
    # See how many records we have
    self.client.search(
      :search_type => 'Media',
      :class => 'GFX',
      :query => "(MEDIA_TYPE=|V)",
      :count_mode => :only,
      :timeout => -1
    )
    # Return if no records found
    if (self.client.rets_data[:code] == "20201")
      self.log "No virtual tours found."
      return
    else
      count = self.client.rets_data[:count]            
      self.log "Importing #{count} virtual tours..."
    end

    count = self.client.rets_data[:count]    
    batch_count = (count.to_f/@@config['limit'].to_f).ceil
    
    (0...batch_count).each do |i|  
      params = {
        :search_type => 'Media',
        :class => 'GFX',
        :query => "(MEDIA_TYPE=|V)",
        :limit => @@config['limit'],
        :offset => @@config['limit'] * i,
        :timeout => -1
      }
      obj = nil
      self.client.search(params) do |data|
        mls_acct = data['MLS_ACCT'].to_i                
        m = CabooseRets::Media.exists?("mls_acct = '#{mls_acct}' and media_type = 'Virtual Tour'") ? CabooseRets::Media.where("mls_acct = '#{mls_acct}' and media_type = 'Virtual Tour'").first : CabooseRets::Media.new
        m.parse(data)        
        m.save
      end                  
    end
  end
  
  def self.refresh_virtual_tours(p)
    self.log("-- Deleting images and metadata for #{p.mls_acct}...")    
    CabooseRets::Media.where(:mls_acct => p.mls_acct, :media_type => 'Photo').destroy_all
    
    self.log("-- Downloading image metadata for #{p.mls_acct}...")    
    params = {
      :search_type => 'Media',
      :class => 'GFX',
      #:query => "(MLS_ACCT=*#{p.id}*),(MEDIA_TYPE=|I)",
      :query => "(MLS_ACCT=*#{p.id}*)",
      :timeout => -1
    }    
    self.client.search(params) do |data|      
      m = CabooseRets::Media.new
      m.parse(data)
      #m.id = m.media_id
      m.save
    end
  end
  
  #def self.download_property_images(p)
  #
  #  self.log("-- Deleting images and metadata for #{p.mls_acct}...")    
  #  CabooseRets::Media.where(:mls_acct => p.mls_acct, :media_type => 'Photo').destroy_all
  #  
  #  self.log("-- Downloading image metadata for #{p.mls_acct}...")    
  #  params = {
  #    :search_type => 'Media',
  #    :class => 'GFX',
  #    :query => "(MLS_ACCT=*#{p.id}*),(MEDIA_TYPE=|I)",
  #    :timeout => -1
  #  }
  #  puts "Before search #{p.id}"
  #  self.client.search(params) do |data|
  #    puts "download_property_images self.client.search #{p.id}"            
  #    #m = CabooseRets::Media.new
  #    #m.parse(data)
  #    #m.id = m.media_id
  #    #m.save      
  #    self.download_property_images2(p)
  #  end
  #  puts "After search #{p.id}"
  #end
  #
  #def self.download_property_images2(p)
  #  puts "download_property_images2 #{p.id}"
  #  sleep(1)
  #  
  #  #self.log("-- Downloading images and resizing for #{p.mls_acct}")
  #  #media = []
  #  #self.client.get_object(:resource => :Property, :type => :Photo, :location => true, :id => p.id) do |headers, content|
  #  #
  #  ## Find the associated media record for the image
  #  #filename = File.basename(headers['location'])
  #  #m = CabooseRets::Media.where(:mls_acct => p.mls_acct, :file_name => filename).first
  #  #
  #  #if m.nil?
  #  #  self.log("Can't find media record for #{p.mls_acct} #{filename}.")
  #  #else         
  #  #  m.image = URI.parse(headers['location'])
  #  #  media << m
  #  #  #m.save
  #  #end      
  #  #    
  #  #self.log("-- Uploading images to S3 for #{p.mls_acct}")
  #  #media.each do |m|      
  #  #  m.save
  #  #end
  #end

  #=============================================================================
  # GPS
  #=============================================================================
  
  def self.update_coords(p = nil)    
    if p.nil?
      models = [CabooseRets::CommercialProperty, CabooseRets::LandProperty, CabooseRets::MultiFamilyProperty, CabooseRets::ResidentialProperty]
      names = ["commercial", "land", "multi-family", "residential"]
      i = 0
      models.each do |model|      
        self.log "Updating coords #{names[i]} properties..."
        model.where(:latitude => nil).reorder(:mls_acct).each do |p|
          self.update_coords(p)                        
        end
        i = i + 1
      end
      return
    end
    
    self.log "Getting coords for mls_acct #{p.mls_acct}..."
    coords = self.coords_from_address(CGI::escape "#{p.street_num} #{p.street_name}, #{p.city}, #{p.state} #{p.zip}")
    return if coords.nil? || coords == false
    
    p.latitude = coords['lat']
    p.longitude = coords['lng']
    p.save    
  end
  
  def self.coords_from_address(address)   
    begin
      uri = "https://maps.googleapis.com/maps/api/geocode/json?address=#{address}&sensor=false"
      uri.gsub!(" ", "+")      
      resp = HTTParty.get(uri)
      json = JSON.parse(resp.body)
      return json['results'][0]['geometry']['location']          
    rescue
      self.log "Error: #{uri}"
      sleep(2)
      return false      
    end
  end
  
  #=============================================================================
  # Logging
  #=============================================================================
  
  def self.log(msg)
    #puts "[rets_importer] #{msg}"
    Rails.logger.info("[rets_importer] #{msg}")
  end  
end