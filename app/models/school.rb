class School < ApplicationRecord
  # SCHEMA:
  # t.string "code", null: false
  # t.string "name", null: false
  # t.integer "type_entity", default: 0, null: false
  # t.boolean "enable_subject_retreat"
  # t.boolean "enable_change_course"
  # t.boolean "enable_dependents"
  # t.bigint "active_process_id"
  # t.bigint "enroll_process_id"
  # t.datetime "created_at", null: false
  # t.datetime "updated_at", null: false
  # t.bigint "faculty_id"
  # t.string "contact_email", default: "coes.fau@gmail.com", null: false
  
  # ASSOCIATIONS
  belongs_to :active_process, foreign_key: 'active_process_id', class_name: 'AcademicProcess', optional: true
  belongs_to :enroll_process, foreign_key: 'enroll_process_id', class_name: 'AcademicProcess', optional: true

  belongs_to :faculty

  has_many :bank_accounts, dependent: :destroy
  accepts_nested_attributes_for :bank_accounts
  has_many :admission_types
  accepts_nested_attributes_for :admission_types

  has_many :academic_processes
  has_many :areas, dependent: :destroy
  has_many :study_plans, dependent: :destroy
  has_many :grades, through: :study_plans
  accepts_nested_attributes_for :study_plans

  has_many :subjects, through: :areas
  has_many :periods, through: :academic_processes
  has_many :admins, as: :env_authorizable 

  # accepts_nested_attributes_for :areas, :academic_processes, :admission_types

  # ENUMERATIONS:
  enum type_entity: [:pregrado, :postgrado, :extension, :investigacion]

  # VALIDATIONS
  validates :type_entity, presence: true
  validates :code, presence: true, uniqueness: {case_sensitive: false}
  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :contact_email, presence: true

  # CALLBAKCS:
  after_initialize :set_unique_faculty
  before_save :clean_name_and_code


  # HOOKS:
  def clean_name_and_code
    self.name.delete! '^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ '
    self.name.strip!
    self.name.upcase!

    self.code.delete! '^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ'
    self.code.strip!
    self.code.upcase!
  end

  def set_unique_faculty
    self.faculty_id = Faculty.first.id if Faculty.count.eql? 1
  end


  # FUNCTIONS:
  def description
    "#{self.code}: #{self.name}. (#{self.faculty.name}) #{self.type_entity.titleize}"
  end

  def enable_dependents?
    (enable_dependents.eql? true) ? true : false
  end

  rails_admin do
    navigation_label 'Gestión Académica'
    navigation_icon 'fa-regular fa-school'
    weight -3
    # visible false

    list do
      checkboxes false
      fields :code, :name, :type_entity
    end

    show do
      field :description

      fields :study_plans, :enroll_process, :active_process, :periods, :areas, :bank_accounts, :contact_email
    end

    edit do
      # field :faculty do
      #   read_only true
      # end

      field :code do
        read_only true
        html_attributes do
          {:length => 3, :size => 3, :onInput => "$(this).val($(this).val().toUpperCase().replace(/[^A-Za-z]/g,''))"}
        end
      end
      field :name do
        read_only true
        html_attributes do
          {:onInput => "$(this).val($(this).val().toUpperCase())"}
        end       
      end
      field :enable_dependents
      fields :active_process, :enroll_process do
        inline_add false
        inline_edit false
      end

      fields :bank_accounts, :contact_email
    end

    export do
      fields :code, :name, :type_entity
    end
  end

end
