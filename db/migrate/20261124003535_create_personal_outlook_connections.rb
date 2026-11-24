class CreatePersonalOutlookConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :personal_outlook_connections do |t|
      t.references :user, null: false, index: { unique: true }
      t.string :email, null: false
      t.text :refresh_token, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end
  end
end
