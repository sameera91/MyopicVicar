# Copyright 2012 Trustees of FreeBMD
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
require 'record_type'
require 'name_role'
class ApplicationController < ActionController::Base
  protect_from_forgery
end
def clean_session
  session[:freereg1_csv_file_id] = nil
    session[:freereg1_csv_file_name] = nil
    session[:county] = nil
    session[:place_name] = nil
    session[:church_name] = nil
    session[:sort] = nil  
  session[:csvfile] = nil
  session[:my_own] = nil
 session[:role] = nil
  session[:freereg] = nil
  session[:edit] = nil
  
end