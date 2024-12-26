class CabooseRets::AgentMeta < ActiveRecord::Base
  self.table_name = "rets_agents_meta"
  belongs_to :agent, :foreign_key => 'mls_id', :primary_key => 'la_code', optional: true
  has_attached_file :image,
    :path => 'rets/agent_meta/:id_:style.:extension',
    :default_url => "https://cabooseit.s3.amazonaws.com/assets/shared/default_profile.png",
    :styles => {
      :thumb => '300x300>',
      :medium => '600x600>',
      :large => '900x900>'
    }
  do_not_validate_attachment_file_type :image
end