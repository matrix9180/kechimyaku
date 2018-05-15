class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email, null: false
      t.string :password_digest
      t.integer :role, null: false, default: 0

      t.timestamps

      t.index :email, unique: true
    end
  end
end
