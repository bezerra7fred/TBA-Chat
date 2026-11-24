class PersonalOutlookConnection < ApplicationRecord
  belongs_to :user

  encrypts :refresh_token

  validates :email, :refresh_token, :expires_at, presence: true
  validates :user_id, uniqueness: true
end
