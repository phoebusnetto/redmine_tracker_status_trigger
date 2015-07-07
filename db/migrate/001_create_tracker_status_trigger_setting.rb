class CreateTrackerStatusTriggerSetting < ActiveRecord::Migration
  def change
    create_table :tracker_status_trigger_setting do |t|
      t.integer :tracker_id, :null => false, :default => 0
      t.string  :relation, :null => false, :default => 'relates'
      t.integer :upd_status_id_from, :null => false, :default => 0
      t.integer :upd_status_id_to, :null => false, :default => 0
      t.integer :status_id_change_from, :null => false, :default => 0
      t.integer :status_id_change_to, :null => false, :default => 0
      t.integer :relation_tracker_id, :integer, :default => 0
    end
  end
  
  def down
    drop_table :tracker_status_trigger_setting
  end
end
