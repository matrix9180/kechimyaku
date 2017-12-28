# ~*~ encoding: utf-8 ~*~
require "sinatra/base"
require "sinatra/reloader"
require "slim"
require 'json'
require 'sinatra/activerecord'
require 'gollum-lib'
require 'wikipedia'


class Kechimyaku < Sinatra::Base

  def get_wiki
    wiki = Gollum::Wiki.new("wiki_repo/", :base_path => "wiki")
  end

  def get_master_name_wiki(master)
    master_name_wiki = master.name.gsub(' ', '-')
  end
  
  get '/?' do
    slim :home
  end

  get '/api/masters/?' do
    @master = Master.where(is_root: true).first
    master_tree = generate_master_tree(@master)
    content_type :json 
    master_tree.to_json
  end

  get '/admin/?' do
    redirect :"admin/masters"  
  end

  get '/admin/masters/?:id?' do
    if (params[:id] != nil)
      puts params[:id]
      @master = Relationship.where(:child_master_id => params[:id]).first.parent_master    
    else
      @master = Master.where(is_root: true).first    
    end

    slim :"admin/masters/masters"  
  end

  get '/admin/masters/add/?:parent_id?' do
    @masters = Master.all
    @relationship_types = RelationshipType.all
    slim :"admin/masters/add"
  end

  post '/admin/masters/add/?' do
    new_master = Master.new
    new_master.name = params[:name]
    new_master.name_native = params[:name_native]
    new_master.year_born = params[:year_born]
    new_master.year_died = params[:year_died]
    new_master.location = params[:location]
    new_master.overview = params[:overview]

    if (params[:parent_id] == "")
      new_master.is_root = true
      new_master.save
    else
      new_master.is_root = false
      new_master.save
      
      new_relationship = Relationship.new
      new_relationship.parent_master_id = params[:parent_id]
      new_relationship.child_master_id = new_master.id
      new_relationship.relationship_type_id = params[:relationship_type_id]
      new_relationship.save
    end

    #create wiki page
    wiki = get_wiki()
    master_name_wiki_formatted = get_master_name_wiki(new_master)
    
    commit = { :message => 'creating wiki for ' + new_master.name,
      :name => 'Kenneth Miller',
      :email => 'ken@kechimyaku.com' }
    
    wiki.write_page(master_name_wiki_formatted, :markdown, '', commit)

    redirect "admin/masters/" + new_master.id.to_s
  end

  get '/admin/masters/edit/:id' do
    @master = Master.find(params[:id])
    @masters = Master.all
    @relationship = Relationship.where(child_master_id: @master.id).first 
    @relationship_types = RelationshipType.all

    slim :"/admin/masters/edit"
  end

  post '/admin/masters/edit/:id' do
    master = Master.find(params[:id])
    previous_master_name_wiki = get_master_name_wiki(master)
    master.name = params[:name]
    master.name_native = params[:name_native]
    master.year_born = params[:year_born]
    master.year_died = params[:year_died]
    master.location = params[:location]
    master.overview = params[:overview]

    relationship = Relationship.where(child_master_id: master.id).first 

    if (params[:parent_id] == "")
      master.is_root = true
      if (relationship != nil)
        relationship.delete
      end
      master.save
    else
      master.is_root = false
      master.save

      if (relationship == nil)
        relationship = Relationship.new
      end
    
      relationship.parent_master_id = params[:parent_id]
      relationship.child_master_id = master.id
      relationship.relationship_type_id = params[:relationship_type_id]
      relationship.save
    end

    #rename wiki page if master name has changed
    current_master_name_wiki = get_master_name_wiki(master)
    if previous_master_name_wiki != current_master_name_wiki
      wiki = get_wiki()
      page = wiki.page(previous_master_name_wiki)
      wiki.update_page(page, current_master_name_wiki, page.format, page.raw_data, commit)
    end

    redirect :"admin/masters"  
  end

  get '/admin/masters/delete/:id' do
    master = Master.find(params[:id])
    master.delete
    redirect :"admin/masters"  
    
  end

  get '/admin/sync_wiki/?' do
    wiki = get_wiki
    commit = { :message => 'initial wiki page generation',
      :name => 'Kenneth Miller',
      :email => 'ken@kechimyaku.com' }

    masters = Master.all
    masters.each do |master|
      if master.name
        master_name_wiki_formatted = get_master_name_wiki(master)

        wikipedia_page = Wikipedia.find(master.name)
        wikipedia_content = ''        
        if wikipedia_page.text
          wikipedia_content = wikipedia_page.text
        end 
        page = wiki.page(master_name_wiki_formatted)
        wikipedia_content.gsub!('=== ', '###')
        wikipedia_content.gsub!(' ===', '')
        wikipedia_content.gsub!(' ==', '')
        wikipedia_content.gsub!('== ', '###')
        puts master_name_wiki_formatted        
        if !page
          wiki.write_page(master_name_wiki_formatted, :markdown, wikipedia_content, commit)
        end    
      end
    end

  end

end

#ENTITIES

class Master < ActiveRecord::Base
  has_many :relationships, foreign_key: :parent_master_id
  has_many :child_masters, through: :relationships, source: :child_master
  
end

class Relationship < ActiveRecord::Base
  belongs_to :child_master, class_name: "Master", foreign_key: :child_master_id 
  belongs_to :parent_master, class_name: "Master", foreign_key: :parent_master_id 
end

class RelationshipType < ActiveRecord::Base
end

#FUNCTIONS

def generate_master_tree(master)
  node = {}
  node[:master] = master
  if master.child_masters
    node[:children] = []

    master.child_masters.sort_by {|cm| cm.child_masters.size}.reverse!.each do |cm|
    #master.child_masters.each do |cm|
      node[:children].push(generate_master_tree(cm))
    end
  end

  return node
end

#HELPERS

def render_master_list(master, indent)
  Slim::Template.new("./views/admin/masters/partials/master_listing.slim", {}).render(Object.new, {master: master, indent: indent})
end