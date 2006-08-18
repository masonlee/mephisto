class Comment < Content
  validates_presence_of :author, :author_ip, :article_id
  after_validation_on_create  :snag_article_filter_and_site
  before_create  :check_comment_expiration
  before_save    :update_counter_cache
  before_destroy :decrement_counter_cache
  belongs_to :article
  attr_protected :approved

  def to_liquid
    { 'id'         => id,
      'author'     => author_link,
      'body'       => body_html,
      'created_at' => created_at }
  end

  def author_link
    return CGI::escapeHTML(author) if author_url.blank?
    self.author_url = "http://" + author_url unless author_url =~ /^https?:\/\//
    %Q{<a href="#{CGI::escapeHTML author_url}">#{CGI::escapeHTML author}</a>}
  end
  
  def approved=(value)
    @old_approved ||= approved? ? :true : :false
    write_attribute :approved, value
  end

  protected
    def snag_article_filter_and_site
      self.attributes = { :site_id => article.site_id, :filter => article.filter }
    end

    def check_comment_expiration
      raise Article::CommentNotAllowed unless article.accept_comments?
    end

    def update_counter_cache
      Article.increment_counter 'comments_count', article_id if approved? && @old_approved == :false
      Article.decrement_counter 'comments_count', article_id if !approved? && @old_approved == :true
    end
    
    def decrement_counter_cache
      Article.decrement_counter 'comments_count', article_id if approved?
    end
end
