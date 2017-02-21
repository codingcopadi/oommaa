# == Schema Information
#
# Table name: licensors
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Licensor < ApplicationRecord
  validates :name, presence: true
  validates :name, uniqueness: true
end
