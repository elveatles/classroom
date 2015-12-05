class Assignment < ActiveRecord::Base
  include GitHubPlan
  include Sluggable

  default_scope { where(deleted_at: nil) }

  has_one :assignment_invitation, dependent: :destroy, autosave: true

  has_many :assignment_repos, dependent: :destroy
  has_many :repo_accesses,    through:   :assignment_repos
  has_many :users,            through:   :repo_accesses

  belongs_to :creator, class_name: User
  belongs_to :organization

  validates :creator, presence: true

  validates :organization, presence: true

  validates :title, presence: true
  validates :title, length: { maximum: 60 }

  validate :uniqueness_of_title_and_slug
  validate :uniqueness_of_title_across_organization

  alias_attribute :invitation, :assignment_invitation

  def private?
    !public_repo
  end

  def public?
    public_repo
  end

  def starter_code?
    starter_code_repo_id.present?
  end

  private

  def uniqueness_of_title_and_slug
    if new_record?
      return unless Assignment.where(slug: slug, organization: organization).present?
    else
      return unless Assignment.where('slug=? AND organization_id=? AND id!=?', slug, organization_id, id).present?
    end

    errors.add(:title, :taken)
  end

  def uniqueness_of_title_across_organization
    return unless GroupAssignment.where(slug: slug, organization: organization).present?
    errors.add(:title, :taken)
  end
end
