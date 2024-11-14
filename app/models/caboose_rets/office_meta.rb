
class CabooseRets::OfficeMeta < ActiveRecord::Base
  self.table_name = "rets_offices_meta"  
  
  belongs_to :office, :foreign_key => 'lo_code', :primary_key => 'lo_code'
  has_attached_file :image, 
    :path => 'rets/offices/:lo_code_:style.:extension', 
    :styles => {
      :thumb => '100x150>', 
      :large => '200x300>'
    }
  do_not_validate_attachment_file_type :image
    
end
