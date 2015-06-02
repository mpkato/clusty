module ApplicationHelper
  def navlink(anchor_text, link, controllername=nil)
    return content_tag(:li, class: controller_name == controllername ? "active" : "") do 
      link_to(anchor_text, link)
    end
  end
end
