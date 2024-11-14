class CabooseRets::RetsConfig < ActiveRecord::Base
  self.table_name = "rets_configs"
  
  belongs_to :site, :class_name => 'Caboose::Site'

end