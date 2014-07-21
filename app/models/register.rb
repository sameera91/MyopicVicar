class Register
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
   require 'record_type'
    require 'register_type' 

  field :status, type: String
  field :register_name,  type: String
  field :alternate_register_name,  type: String
  field :register_type,  type: String
  field :quality,  type: String
  field :source,  type: String
  field :copyright,  type: String
  field :register_notes,  type: String
  field :last_amended, type: String
  
  has_many :freereg1_csv_files, dependent: :restrict
  belongs_to :church, index: true

 
  index({ church_id: 1, register_name: 1}, { unique: true })
  index({ register_name: 1})
  index({ alternate_register_name: 1})
   index({ church_id: 1, alternate_register_name: 1}, { unique: true })
   
 
 
  def self.update_or_create_register(freereg1_csv_file)
    @@result = nil
    # find if register exists
   register = find_register(freereg1_csv_file.to_register)
    if register
      #update register
      register.freereg1_csv_files << freereg1_csv_file
      #freereg1_csv_file.save
    else 
    # create the register  
     register = create_register_for_church(freereg1_csv_file.to_register, freereg1_csv_file)   
    end
    
     
  end

  def self.create_register_for_church(args,freereg1_csv_file)
    # look for the church
    if @@my_church
      # locate place
     my_place = @@my_church.place
    else
      #church does not exist so see if Place exists with another church
      my_place = Place.where('chapman_code' => args[:chapman_code], 'place_name' => args[:place_name]).first
      unless my_place
       #place does not exist so lets create new place first
       my_place = Place.new(:chapman_code => args[:chapman_code], :place_name => args[:place_name], :disabled => 'false', :grid_reference => 'TQ336805') 
           
       my_place.error_flag = "Place name is not approved" 

       end
      #now create the church entry
      @@my_church = Church.new(:church_name => args[:church_name])
      my_place.churches << @@my_church
    end
    #now create the register
    register = Register.new(args) 
    register.freereg1_csv_files << freereg1_csv_file
   
    @@my_church.registers << register
    @@my_church.save
    #and save everything
      
    my_place.save
    #freereg1_csv_file.save
   
   
    register
  end


 
  
  def self.find_register(args)
    
    @@my_church = Church.find_by_name_and_place(args[:chapman_code], args[:place_name], args[:church_name])
    if @@my_church
      my_church_id = @@my_church[:_id]
      register = Register.where(:church_id =>my_church_id, :alternate_register_name=> args[:alternate_register_name] ).first
      unless register then
        register = Register.where(:church_id =>my_church_id, :register_name=> args[:alternate_register_name] ).first
        unless register
          register = nil
        end
       end
    else
      register = nil
    end
     register 
  end
  def self.clean_empty_registers(freereg_file)
    #clean out empty register/church/places
    register = freereg_file.register._id
    register = Register.find(register)
    church = register.church._id
    church = Church.find(church)
    #place = church.place._id
    #place = Place.find(place)
    register.destroy unless register.freereg1_csv_files.exists?
    church.destroy unless church.registers.exists?
    #place.destroy unless place.churches.exists?
  end

  
  
end