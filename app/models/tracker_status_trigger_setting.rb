class TrackerStatusTriggerSetting < ActiveRecord::Base
  unloadable
  
  def init
    @missing_config = false
    super if defined?(super)
  end

  def self.check(tracker, relation_name, old_status_str, new_status_str)
    old_status_id = 0
    new_status_id = 0
    old_status = IssueStatus.find_by_name(old_status_str)

    if !old_status.nil?
      old_status_id = old_status.id
    end
    
    new_status = IssueStatus.find_by_name(new_status_str)
    if !new_status.nil?
      new_status_id = new_status.id
    end

    settings = where(tracker_id: tracker, relation: relation_name, status_id_change_from: old_status_id, status_id_change_to: new_status_id)
    if settings.size > 0
      if relation_name == 'child'
        return settings
      else
        return settings[0]
      end
    else
      return nil
    end
  end
  
  def str_upd_status_from
    result = IssueStatus.find_by_id(self.upd_status_id_from)
    if result.nil?
      @missing_config = true
      return 'No status found with id %d' % self.upd_status_id_from
    else
      return result.name
    end
  end

  def str_upd_status_to
    result = IssueStatus.find_by_id(self.upd_status_id_to)
    if result.nil?
      @missing_config = true
      return 'No status found with id %d' % self.upd_status_id_to
    else
      return result.name
    end
  end
  
  def str_change_status_from
    result = IssueStatus.find_by_id(self.status_id_change_from)
    if result.nil?
      @missing_config = true
      return 'No status found with id %d' % self.status_id_change_from
    else
      return result.name
    end
  end

  def str_change_status_to
    result = IssueStatus.find_by_id(self.status_id_change_to)
    if result.nil?
      @missing_config = true
      return 'No status found with id %d' % self.status_id_change_to
    else
      return result.name
    end
  end
  
  def tracker_name
    result = Tracker.find_by_id(self.tracker_id)
    if result.nil?
      @missing_config = true
      return 'No tracker found with id %d' % self.tracker_id
    else
      return result.name
    end
  end
  
  def relation_tracker_name
    if self.relation_tracker_id == 0
      return l(:label_all)
    else
      return Tracker.find_by_id(self.relation_tracker_id).name
    end
  end
  
  def is_missing_config
    return @missing_config
  end
end
