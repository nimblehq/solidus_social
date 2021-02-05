class AddLoginNameToAuthenticationMethods < ActiveRecord::Migration[6.1]
  def up
    change_table :spree_authentication_methods do |t|
      t.string  :login_name
    end
  end

  def down
    change_table :spree_authentication_methods do |t|
      t.remove :login_name
    end
  end
end
