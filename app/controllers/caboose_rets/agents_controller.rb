
module CabooseRets
  class AgentsController < ApplicationController

    # @route GET /real-estate/agents
    # @route GET /agents
    def index
      @agents = Agent.where("office_mls_id ILIKE ?",@site.rets_office_id).order(:sort_order).reject{ |a| (a.meta && a.meta.hide == true) }
    end

    # @route GET /real-estate/agents/:slug
    # @route GET /agents/:mls_id
    def show
      if params[:mls_id].present?
        @agent = find_agent_by_mls_id
      elsif params[:slug].present?
        @agent = find_agent_by_slug
      end

      if @agent.nil? || @agent.mls_id.blank?
        render file: "caboose/extras/error404", layout: "caboose/application", status: 404
        return
      end

      @listings = Property.by_agent_mls_id(@agent.mls_id).active.order('list_price desc').all
    end 

    # @route GET /real-estate/agents/:slug/contact
    # @route GET /agents/:id/contact
    def contact
      @agent = Agent.where(:id => params[:id]).first if !params[:id].blank?
      @agent = Agent.where(:slug => params[:slug]).where("office_mls_id ILIKE ?", @site.rets_office_id).first if !params[:slug].blank?
    end

    # @route GET /rets-unsubscribe
    def user_unsubscribe
      user_id = params[:token].blank? ? nil : params[:token].strip.gsub("7b8v9j","").gsub("9b6h0c2n","")
      @user = user_id ? Caboose::User.where(:id => user_id, :site_id => @site.id).first : nil
      @token = params[:token]
      render :file => "caboose/extras/error404", :layout => "caboose/application", :status => 404 and return if @user.nil? || @token.blank?
      @page.meta_robots = "noindex, nofollow"
      @page.uri = "rets-unsubscribe"
      @page.seo_title = "Confirm Unsubscription | #{@site.description}"
    end

    # @route GET /rets-unsubscribe/confirm
    def user_unsubscribe_confirm
      user_id = params[:token].blank? ? nil : params[:token].strip.gsub("7b8v9j","").gsub("9b6h0c2n","")
      @user = user_id ? Caboose::User.where(:id => user_id, :site_id => @site.id).first : nil
      render :file => "caboose/extras/error404", :layout => "caboose/application", :status => 404 and return if @user.nil?
      @page.meta_robots = "noindex, nofollow"
      @page.uri = "rets-unsubscribe/confirm"
      @page.seo_title = "Unsubscribed | #{@site.description}"
      @user.tax_exempt = true # this means unsubscribed
      @user.save
    end

    #=============================================================================
    # Admin functions 
    #=============================================================================

    # @route GET /admin/agents
    def admin_index
      return unless (user_is_allowed_to 'view', 'rets_agents')     
      render :layout => 'caboose/admin'       
    end

    # @route GET /admin/agents/options
    def admin_agent_options
      options = []
      rc = CabooseRets::RetsConfig.where(:site_id => @site.id).first
      agents = rc ? CabooseRets::Agent.joins(:meta).where(:office_mls_id => rc.office_mls, rets_agents_meta: {hide: FALSE, accepts_listings: true}).order(:sort_order).all : []
      agents.each do |c|
        options << { 'value' => c.mls_id, 'text' => "#{c.first_name} #{c.last_name}" }
      end     
      render :json => options
    end

    # @route GET /admin/agents/json
    def admin_json 
      render :json => false and return if !user_is_allowed_to 'view', 'rets_agents'
      where = "(office_mls_id ILIKE '#{@site.rets_office_id}')"
      pager = Caboose::Pager.new(params, {
        'first_name_like' => '',
        'last_name_like' => ''
      }, {
        'model' => 'CabooseRets::Agent',
        'sort'  => 'last_name',
        'desc'  => 'false',
        'base_url' => '/admin/agents',
        'items_per_page' => 50,
        'additional_where' => [ (where) ]
      })
      render :json => {
        :pager => pager,
        :models => pager.items.as_json(:include => [:meta])
      } 
    end

    # @route GET /admin/agents/:id/json
    def admin_json_single
      render :json => false and return if !user_is_allowed_to 'edit', 'rets_agents'
      prop = Agent.find(params[:id])
      render :json => prop
    end

    # @route GET /admin/agents/edit-sort
    def admin_edit_sort
      return unless user_is_allowed_to 'edit', 'rets_agents'
      @agents = Agent.where("office_mls_id ILIKE ?", @site.rets_office_id).order(:sort_order).all
      render :layout => 'caboose/admin'  
    end

    # @route PUT /admin/agents/update-sort
    def admin_update_sort
      resp = Caboose::StdClass.new
      return unless user_is_allowed_to 'edit', 'rets_agents'
      params[:agent].each_with_index do |ag, ind|
        agent = Agent.find(ag)
        agent.sort_order = ind
        agent.save
      end
      resp.success = true
      render :json => resp
    end

    # @route GET /admin/agents/:id
    def admin_edit
      return unless (user_is_allowed_to 'edit', 'rets_agents')
      @agent = Agent.find(params[:id])
      @agent_meta = @agent.meta ? @agent.meta : AgentMeta.create(:la_code => @agent.matrix_unique_id) if @agent
      render :layout => 'caboose/admin'       
    end

    # @route PUT /admin/agents/:id
    def admin_update
      return unless (user_is_allowed_to 'edit', 'rets_agents')
      resp = Caboose::StdClass.new
      agent = Agent.find(params[:id])
      meta = agent.meta ? agent.meta : AgentMeta.create(:la_code => agent.matrix_unique_id)
      params.each do |k,v|
        case k
          when "bio" then meta.bio = v
          when "slug" then agent.slug = v
          when "hide" then meta.hide = v
          when "weight" then meta.weight = v
          when "accepts_listings" then meta.accepts_listings = v
        end
      end
      agent.save
      meta.save
      resp.success = true
      render :json => resp
    end

    # @route POST /admin/agents/:id/image
    def admin_update_image
      render :json => false and return unless user_is_allowed_to 'edit', 'rets_agents'    
      resp = Caboose::StdClass.new
      agent = Agent.find(params[:id])
      meta = agent.meta ? agent.meta : AgentMeta.create(:la_code => agent.matrix_unique_id) if agent
      meta.image = params[:image]
      meta.save
      resp.success = true 
      resp.attributes = { 'image' => { 'value' => meta.image.url(:thumb) }}
      render :json => resp
    end

    private

    def find_agent_by_mls_id
      return nil unless params[:mls_id].present?

      rets_office_id = Current.site.rets_office_id ? Current.site.rets_office_id.downcase : nil
      Agent.by_mls_id(params[:mls_id]).by_office_mls_id(rets_office_id).first
    end

    def find_agent_by_slug
      return nil unless params[:slug].present?

      rets_office_id = Current.site.rets_office_id ? Current.site.rets_office_id.downcase : nil
      Agent.by_slug(params[:slug]).by_office_mls_id(rets_office_id).first
    end
  end
end
