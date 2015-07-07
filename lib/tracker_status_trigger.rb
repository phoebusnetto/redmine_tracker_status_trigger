module TrackerStatusTrigger
  module Patches
    module IssuePatch
      @user = nil
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable

          after_save  :update_relations
          validate    :validate_update_trigger_relations
        end
      end
    end
      
    module ClassMethods
    end
    
    module InstanceMethods
      def validate_update_trigger_relations
        logger.info '*****************************************'
        if self.parent_issue_id.to_i > 0
          logger.info 'Validating parent status change...'
          validate_parent_status_change
        end
        if self.relations.to_s != ''
          logger.info 'Validating relation statuses change...'
          validate_relations_issues_status_change
        end
        if self.children.count.to_i > 0
          logger.info 'Validating child statuses change...'
          validate_children_status_change
        end
        logger.info '*****************************************'
      end
      
      def get_tst_user
        user = User.current
        # By default, the settings comes all as strings, so we compare the checkbox checked attribute with 
        # the string 'true' instead of the boolean value (true)
        if Setting.plugin_redmine_tracker_status_trigger['use_specific_user'] == 'true'
          logger.info '---------------------------------------------'
          logger.info 'Using master permission to use in Tracker Status Trigger'
          user = User.find_by_login(Setting.plugin_redmine_tracker_status_trigger['specific_user'])
          if user.nil?
            logger.info '---------------------------------------------'
            logger.info 'Could not find user %s to run the Tracker Status Trigger plugin' % Setting.plugin_redmine_tracker_status_trigger['specific_user']
            logger.info 'Using current login %s' % User.current.login
            logger.info '---------------------------------------------'
            user = User.current
          end
        end
        return user
      end
      
      def check_possible_status(issue, old_status_id, new_status_id)
        logger.info 'check_possible_status'
        result = nil
        
        possible_statuses = issue.new_statuses_allowed_to(get_tst_user)
        possible_statuses.each do |status|
          status_id = IssueStatus.find_by_name(status.to_s)
          if !status_id.nil?
            if status_id.id == new_status_id
              result = true
              break
            end
          end
        end
        
        if issue.status_id == old_status_id
          if result.nil?
            logger.info 'TrackerID %d' % issue.tracker_id
            logger.info 'Old StatusID %d' % old_status_id
            logger.info 'StatusID %d not allowed' % new_status_id
            return false
          else
            logger.info 'Validation successfull!'
          end
        end
      
        return true
      end
      
      def child_check_possible_status(issue, old_status_id, new_status_id)
        issue.children.each do |child|
          child_check_possible_status(child, old_status_id, new_status_id)
        end
        result = check_possible_status(issue, old_status_id, new_status_id)
        if result == false
          old_status = IssueStatus.find_by_id(old_status_id)
          new_status = IssueStatus.find_by_id(new_status_id)
          errors.add :base, :msg_child_issue_not_allow_this_statuts_change, {:id =>issue.id, :type => issue.tracker.to_s, :old_status => old_status.to_s, :new_status => new_status.to_s }
        end
      end
      
      def validate_children_status_change
        result = TrackerStatusTriggerSetting.check(self.tracker_id, l(:child_relation), self.status_was.to_s, self.status.to_s)
        if !result.nil?
          result.each do |res|
            child_old_status_id = res.upd_status_id_from.to_i
            child_new_status_id = res.upd_status_id_to.to_i
            
            self.children.each do |child|
              if (res.relation_tracker_id.to_i == 0) or (res.relation_tracker_id.to_i == child.tracker_id.to_i)
                child_check_possible_status(child, child_old_status_id, child_new_status_id)
              end
            end
          end
        end
      end
      
      def validate_parent_status_change
        result = TrackerStatusTriggerSetting.check(self.tracker_id, l(:parent_relation), self.status_was.to_s, self.status.to_s)
        if !result.nil?
          parent_old_status_id = result.upd_status_id_from.to_i
          parent_new_status_id = result.upd_status_id_to.to_i
          
          parent_issue = Issue.find_by_id(self.parent_issue_id.to_i)
          if (result.relation_tracker_id.to_i == 0) or (result.relation_tracker_id.to_i == parent_issue.tracker_id.to_i)
            result = check_possible_status(parent_issue, parent_old_status_id, parent_new_status_id)
            if result == false
              old_status = IssueStatus.find_by_id(parent_old_status_id)
              new_status = IssueStatus.find_by_id(parent_new_status_id)
              errors.add :base, :msg_parent_issue_not_allow_this_statuts_change, { :type => parent_issue.tracker.to_s, :old_status => old_status.to_s, :new_status => new_status.to_s }
            end
          end
        end
      end
      
      def validate_related_possible_status(relation_type, other_issue_id, related_issue, old_status_id, new_status_id)
        result = check_possible_status(related_issue, old_status_id, new_status_id)
        if result == false
          old_status = IssueStatus.find_by_id(old_status_id)
          new_status = IssueStatus.find_by_id(new_status_id)
          errors.add :base, :msg_related_issue_not_allow_this_status_change, { :relation => relation_type, :task => other_issue_id, :type => related_issue.tracker.to_s, :old_status => old_status.to_s, :new_status => new_status.to_s }
        end
      end

      def validate_related_issues_status_change(relations)
        result = TrackerStatusTriggerSetting.check(self.tracker_id, l(:relates_relation), self.status_was.to_s, self.status.to_s)
        if !result.nil?
          related_old_status_id = result.upd_status_id_from.to_i
          related_new_status_id = result.upd_status_id_to.to_i
          relations.each {
            |relation|
            related_issue = Issue.find_by_id(relation.other_issue(self).id.to_i)
            if (result.relation_tracker_id.to_i == 0) or (result.relation_tracker_id.to_i == related_issue.tracker_id.to_i)
              validate_related_possible_status(l(:relates_relation), relation.other_issue(self).id.to_i, related_issue, related_old_status_id, related_new_status_id.to_i)
            end
          }
        end
      end
      
      def validate_relations_issues_status_change
        relations = []
        self.relations.each do |relation|
          if relation.relation_type == l(:relates_relation)
            relations << relation
          end
        end
        
        if relations.count > 0
          validate_related_issues_status_change(relations)
        end
      end

      # This will update the status of related issues
      def update_relations
        self.reload
        logger.info '*****************************************'
        if self.parent_issue_id.to_i > 0
          logger.info 'Update parent (id %d) status...' % self.parent_issue_id.to_i
          update_parent_status
        end
        if self.relations.to_s != ''
          logger.info 'Update relation statuses...'
          update_relation_issues_status
        end
        if self.children.count.to_i > 0
          logger.info 'Update children status from parent (id %d) ...' % self.parent_issue_id.to_i
          update_children_status
        end
        logger.info '*****************************************'
      end
      
      def update_relation_issues_status
        relations = []
        self.relations.each do |relation|
          if relation.relation_type == l(:relates_relation)
            relations << relation
          end
        end
        
        if relations.count > 0
          update_related_issues_status(relations)
        end
      end

      # This will update the status of related issues
      def update_related_issues_status(relations)
        result = TrackerStatusTriggerSetting.check(self.tracker_id, l(:relates_relation), self.status_was.to_s, self.status.to_s)
        if !result.nil?
          related_old_status_id = result.upd_status_id_from.to_i
          related_new_status_id = result.upd_status_id_to.to_i
          relations.each {
            |relation|
            related_issue = Issue.find_by_id(relation.other_issue(self).id.to_i)
            logger.info 'Related tracker id: %d' % related_issue.tracker_id.to_i
            logger.info 'TST: %d' % result.relation_tracker_id.to_i
            if ((result.relation_tracker_id.to_i == 0) or (result.relation_tracker_id.to_i == related_issue.tracker_id.to_i)) and related_issue.status_id == related_old_status_id
              logger.info 'Updating status of related issue id %d...' % related_issue.id.to_i
              related_issue.status_id = related_new_status_id
              related_issue.save(:validate => false)
              journal = Journal.new(:journalized => related_issue, :user => get_tst_user)
              journal.details << JournalDetail.new(:property => 'attr',
                                                    :prop_key => 'status',
                                                    :old_value => result.str_upd_status_from,
                                                    :value => result.str_upd_status_to)
              journal.save
              logger.info 'Done!'
            end
          }
        end
      end

      def update_child_status(issue, old_status_id, new_status_id, settings)
        issue.children.each do |child|
          update_child_status(child, old_status_id, new_status_id, settings)
        end
        
        issue.reload
        if issue.status_id == old_status_id
          logger.info 'Updating status of children id %d...' % issue.id.to_i
          issue.status_id = new_status_id
          issue.save(:validate => false)
          journal = Journal.new(:journalized => issue, :user => get_tst_user)
          journal.details << JournalDetail.new(:property => 'attr',
                                                :prop_key => 'status',
                                                :old_value => settings.str_upd_status_from,
                                                :value => settings.str_upd_status_to)
          journal.save
          logger.info 'Done!'
        end
      end
      
      def update_children_status
        result = TrackerStatusTriggerSetting.check(self.tracker_id, l(:child_relation), self.status_was.to_s, self.status.to_s)
        if !result.nil?
          result.each do |res|
            child_old_status_id = res.upd_status_id_from.to_i
            child_new_status_id = res.upd_status_id_to.to_i
            
            self.children.each do |child|
              if (result.relation_tracker_id.to_i == 0) or (result.relation_tracker_id.to_i == child.tracker_id.to_i)
                update_child_status(child, child_old_status_id, child_new_status_id, res)
              end
            end
          end
        end
      end
      
      def update_parent_status
        result = TrackerStatusTriggerSetting.check(self.tracker_id, l(:parent_relation), self.status_was.to_s, self.status.to_s)
        if !result.nil?
          parent_old_status_id = result.upd_status_id_from.to_i
          parent_new_status_id = result.upd_status_id_to.to_i
            
          parent_issue = Issue.find_by_id(self.parent_issue_id.to_i)
          if ((result.relation_tracker_id.to_i == 0) or (result.relation_tracker_id.to_i == parent_issue.tracker_id.to_i)) and parent_issue.status_id.to_i == parent_old_status_id.to_i
            logger.info 'Updating status of parent id %d...' % parent_issue.id.to_i
            parent_issue.status_id = parent_new_status_id
            parent_issue.save(:validate => false)
            journal = Journal.new(:journalized => parent_issue, :user => get_tst_user)
            journal.details << JournalDetail.new(:property => 'attr',
                                                  :prop_key => 'status',
                                                  :old_value => result.str_upd_status_from,
                                                  :value => result.str_upd_status_to)
            journal.save
            logger.info 'Done!'
          end
        end
      end
    end
  end
end