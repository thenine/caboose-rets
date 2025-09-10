class CabooseRets::Agent < ActiveRecord::Base
  self.table_name = "rets_agents"  
  
  has_one :meta, :class_name => 'AgentMeta', :primary_key => 'mls_id', :foreign_key => 'la_code'
  has_many :properties
  # attr_accessible :id, :agent_number, :matrix_unique_id, :sort_order, :mls_id, :last_updated
  after_initialize :fix_name

  scope :by_mls_id, ->(mls_id) { where(mls_id:) }
  scope :by_slug, ->(slug) { where(slug:) }
  scope :by_office_mls_id,
        ->(office_mls_id) { where("LOWER(office_mls_id) = ?", office_mls_id) }
  
  def image
    return nil if self.meta.nil?
    return self.meta.image
  end

  # def assistants
  #   CabooseRets::Agent.where(:assistant_to => self.mls_id).reorder(:last_name, :first_name).all
  
  # end

  def office
    CabooseRets::Office.where(:lo_mls_id => self.mls_id).first
  end
  
  def fix_name
    return if self.first_name.nil?
    self.first_name = self.first_name.split(' ').collect{ |str| str.downcase.capitalize }.join(' ')
    return if self.last_name.nil?          
    self.last_name  = self.last_name.split(' ').collect{ |str| str.downcase.capitalize }.join(' ')    
    if self.last_name.starts_with?('Mc')
      self.last_name[2] = self.last_name[2].upcase
    end
  end
  
  def refresh_from_mls
    CabooseRets::RetsImporter.import('Member',"(MemberMlsId=#{self.mls_id})")
    CabooseRets::RetsImporter.download_property_images(self)
  end
  
  def self.refresh_from_mls(agent_number)
    CabooseRets::RetsImporter.import('Member', "(MemberMlsId=#{self.mls_id})")
    CabooseRets::RetsImporter.import_agent(self.mls_id)          
  end

  # Sends a SMS to the agent (using Twilio) notifying them that a new user has registered and been assigned to them.
  def send_text(message, site_id)
    s1 = Caboose::Setting.where(:site_id => site_id, :name => "twilio_account_sid").first
    account_sid = s1 ? s1.value : nil
    s2 = Caboose::Setting.where(:site_id => site_id, :name => "twilio_auth_token").first
    auth_token = s2 ? s2.value : nil
    s3 = Caboose::Setting.where(:site_id => site_id, :name => "twilio_from_number").first
    twilio_number = s3 ? s3.value : nil
    send_to = self.cell_phone.blank? ? (self.direct_work_phone.blank? ? self.other_phone : self.direct_work_phone) : self.cell_phone
    send_to = '205-657-0937' if Rails.env.development? # Billy's cell
    if account_sid && auth_token && twilio_number && !send_to.blank? && !message.blank?
      @client = Twilio::REST::Client.new account_sid, auth_token
      begin
        message = @client.messages.create(
          body: message,
          to:   "+1#{send_to.gsub(/[(\- )]/, '')}",
          from: "#{twilio_number}"
        )
      rescue
        Caboose.log("invalid phone number")
      end
    end
  end

  def self.assign_to_new_user(user)
    if user && user.site && user.site.use_rets
      rc = CabooseRets::RetsConfig.where(:site_id => user.site_id).first
      agents                 = rc ? CabooseRets::Agent.joins(:meta).where(:office_mls_id => rc.office_mls, rets_agents_meta: {hide: FALSE, accepts_listings: true}).order(:sort_order).all : []
      last_agent_mls_id      = Caboose::Setting.where(:name => "latest_user_agent", :site_id => user.site_id).exists? ? Caboose::Setting.where(:name => "latest_user_agent", :site_id => user.site_id).first : Caboose::Setting.create(:name => "latest_user_agent", :site_id => user.site_id, :value => agents.first.mls_id)
      last_agent             = CabooseRets::Agent.joins(:meta).where(:mls_id => last_agent_mls_id.value, rets_agents_meta: {hide: FALSE, accepts_listings: true}).first
      agent_index            = last_agent.present? ? agents.find_index(last_agent) : 0
      agent_index + 1 < agents.count ? agent_index += 1 : agent_index = 0
      agent = agents[agent_index]   
      if agent.mls_id == '118593505' # Steven Deal shouldn't be assigned
        agent_index + 1 < agents.count ? agent_index += 1 : agent_index = 0
        agent = agents[agent_index]
      end
      Caboose.log("Assigning agent #{agent.mls_id} to user #{user.id}") if Rails.env.development?
      user.rets_agent_mls_id = agent.mls_id
      last_agent_mls_id.value = agent.mls_id
      user.save

      s1 = Caboose::Setting.where(:site_id => user.site_id, :name => "agent_text_message").first
      message = s1 ? s1.value : nil

      if !message.blank?
        message = message.gsub("|user_first_name|", user.first_name)
        message = message.gsub("|user_last_name|", user.last_name)
        message = message.gsub("|user_email|", user.email)
        message = message.gsub("|user_phone|", user.phone)
        agent.delay(:queue => 'rets', :priority => 0).send_text(message, user.site_id)
      end

      CabooseRets::RetsMailer.configure_for_site(user.site_id).new_user(agent, user).deliver_later
      CabooseRets::RetsMailer.configure_for_site(user.site_id).user_welcome(agent, user).deliver_later

      last_agent_mls_id.save
      role = Caboose::Role.where(:name => 'RETS Visitor', :site_id => user.site_id).exists? ? Caboose::Role.where(:name => 'RETS Visitor', :site_id => user.site_id).first : Caboose::Role.create(:name => 'RETS Visitor', :site_id => user.site_id)
      Caboose::RoleMembership.create(:user_id => user.id, :role_id => role.id)
    end
  end
    
  def parse(data)
#    self.agent_number                 = data['AgentNumber']
    self.cell_phone                   = data['MemberMobilePhone']
    self.direct_work_phone            = data['MemberDirectPhone']
    self.email                        = data['MemberEmail']
    self.fax_phone                    = data['MemberFax']
    self.first_name                   = data['MemberFirstName']
    self.full_name                    = data['MemberFullName']
   # self.generational_name            = data['MemberMiddleName']
    self.last_name                    = data['MemberLastName']
    self.matrix_unique_id             = data['MemberMlsId']
    self.matrix_modified_dt           = data['ModificationTimestamp']
    self.middle_name                  = data['MemberMiddleName']
    self.mls                          = 'West Alabama Multiple Listing Service'
    self.mls_id                       = data['MemberMlsId']
    self.office_mui                   = data['OfficeMlsId']
    self.office_mls_id                = data['OfficeMlsId']
    self.office_phone                 = data['MemberOfficePhone']
    self.other_phone                  = data['MemberPreferredPhone']
    self.phone_toll_free              = data['MemberTollFreePhone']
    self.phone_voice_mail             = data['MemberVoiceMail']        
  #  self.photo_count                  = data['PhotoCount']
  #  self.photo_modification_timestamp = data['PhotoModificationTimestamp']
    self.slug                         = "#{data['MemberFirstName']}-#{data['MemberLastName']}".parameterize
  end
  
  def verify_meta_exists
     self.meta = CabooseRets::AgentMeta.create(:la_code => self.mls_id) if self.meta.nil?
  end
  
  def image_url(style)                
    if CabooseRets::use_hosted_images == true
      return "#{CabooseRets::agents_base_url}/#{self.image_location}"
      self.verify_meta_exists      
      return self.meta.image_location
    end
    return "" if self.image.nil?
    return self.image.url(style)           
  end
     
end
