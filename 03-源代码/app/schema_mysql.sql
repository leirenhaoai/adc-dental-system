-- ADC 诊疗管理系统 建库脚本（MySQL 8.0 方言，由 tools/gen_schema_mysql.py 生成）
-- 用法：在云托管 MySQL 里执行（控制台「数据库 → 导入」），或本地 mysql < schema_mysql.sql
-- 说明：外键不建物理约束，靠应用层 + 唯一索引保证一致性（避免批量 seed 的顺序依赖）。
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;

-- ADC 诊疗管理系统 建库脚本（由 tools/_dump_schema.py 从 data/adc.db 导出）
-- 用法：python app/server.py --init-only
-- 说明：表结构由 生成脚本/db_model9.py 设计，本文件是它落库后的实际形态，
--       含后续追加的 SEQ 发号表、NOTICE 通知表与防并发唯一索引。

-- table: ACCOUNT_PAYABLE
CREATE TABLE IF NOT EXISTS `ACCOUNT_PAYABLE` (
  `payable_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `supplier_id` INT,
  `po_id` INT,
  `statement_id` INT,
  `payable_no` VARCHAR(191),
  `payable_amount` DECIMAL(14,2),
  `status` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: ALLERGY
CREATE TABLE IF NOT EXISTS `ALLERGY` (
  `allergy_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `patient_id` INT,
  `allergy_name` TEXT,
  `allergen_type` TEXT,
  `severity` TEXT,
  `reaction` TEXT,
  `discovered_date` TEXT,
  `is_confirmed` INT,
  `confirming_dentist_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: APPOINTMENT
CREATE TABLE IF NOT EXISTS `APPOINTMENT` (
  `appointment_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `appointment_no` VARCHAR(191),
  `patient_id` INT,
  `roster_id` INT,
  `appointment_datetime` TEXT,
  `status` TEXT,
  `cancellation_category` TEXT,
  `visit_reason` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: AUDIT_LOG
CREATE TABLE IF NOT EXISTS `AUDIT_LOG` (
  `audit_log_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `patient_id` INT,
  `record_table` TEXT,
  `record_id_ref` TEXT,
  `changed_field` TEXT,
  `old_value` TEXT,
  `new_value` TEXT,
  `operator_name` TEXT,
  `changed_datetime` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: CLINIC
CREATE TABLE IF NOT EXISTS `CLINIC` (
  `clinic_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `clinic_no` VARCHAR(191),
  `clinic_name` TEXT,
  `postal_address` TEXT,
  `region` TEXT,
  `manager_name` TEXT,
  `phone` TEXT,
  `email` TEXT,
  `office_area_sqm` DECIMAL(14,2),
  `license_no` TEXT,
  `license_valid_until` TEXT,
  `service_scope` TEXT,
  `opened_date` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: CLINIC_CALENDAR
CREATE TABLE IF NOT EXISTS `CLINIC_CALENDAR` (
  `calendar_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `clinic_id` INT,
  `weekday` INT,
  `open_time` TEXT,
  `close_time` TEXT,
  `is_operating` INT,
  `chair_count` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: COMPLAINT
CREATE TABLE IF NOT EXISTS `COMPLAINT` (
  `complaint_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `patient_id` INT,
  `visit_id` INT,
  `clinic_id` INT,
  `channel` TEXT,
  `content` TEXT,
  `filed_date` TEXT,
  `status` TEXT,
  `resolution` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: COST_VERSION
CREATE TABLE IF NOT EXISTS `COST_VERSION` (
  `version_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `version_no` VARCHAR(191),
  `effective_date` TEXT,
  `description` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: DENTIST
CREATE TABLE IF NOT EXISTS `DENTIST` (
  `dentist_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `employee_no` INT,
  `name` TEXT,
  `date_of_birth` TEXT,
  `home_address` TEXT,
  `phone` TEXT,
  `email` TEXT,
  `active` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: DENTIST_LEAVE
CREATE TABLE IF NOT EXISTS `DENTIST_LEAVE` (
  `leave_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `dentist_id` INT,
  `clinic_id` INT,
  `leave_start` TEXT,
  `leave_end` TEXT,
  `leave_type` TEXT,
  `leave_reason` TEXT,
  `approval_status` TEXT,
  `approver_staff_id` INT,
  `approved_date` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: DENTIST_QUALIFICATION
CREATE TABLE IF NOT EXISTS `DENTIST_QUALIFICATION` (
  `dentist_id` INT,
  `qualification_id` INT,
  `obtained_date` TEXT,
  `certificate_no` TEXT,
  `valid_until` TEXT,
  `cert_status` TEXT,
  PRIMARY KEY (dentist_id, qualification_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: DENTIST_QUARTER_PERFORMANCE
CREATE TABLE IF NOT EXISTS `DENTIST_QUARTER_PERFORMANCE` (
  `perf_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `dentist_id` INT,
  `quarter` TEXT,
  `revenue_amount` DECIMAL(14,2),
  `cost_amount` DECIMAL(14,2),
  `operating_expense_amount` DECIMAL(14,2),
  `visit_count` INT,
  `patient_count` INT,
  `recall_rate` DECIMAL(14,2),
  `complaint_count` INT,
  `quality_incident_count` INT,
  `chair_utilization` DECIMAL(14,2),
  `work_days` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: DISINFECTION_RECORD
CREATE TABLE IF NOT EXISTS `DISINFECTION_RECORD` (
  `disinfection_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `clinic_id` INT,
  `record_date` TEXT,
  `operator_name` TEXT,
  `scope` TEXT,
  `result` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: EXPENSE_ALLOCATION
CREATE TABLE IF NOT EXISTS `EXPENSE_ALLOCATION` (
  `allocation_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `expense_id` INT,
  `clinic_id` INT,
  `quarter` TEXT,
  `allocated_amount` DECIMAL(14,2),
  `basis` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: FOLLOWUP_RECALL
CREATE TABLE IF NOT EXISTS `FOLLOWUP_RECALL` (
  `recall_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `patient_id` INT,
  `visit_id` INT,
  `due_date` TEXT,
  `channel` TEXT,
  `status` TEXT,
  `completed_date` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: IMAGE_RECORD
CREATE TABLE IF NOT EXISTS `IMAGE_RECORD` (
  `image_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `patient_id` INT,
  `visit_id` INT,
  `tooth_fdi` TEXT,
  `image_type` TEXT,
  `image_url` TEXT,
  `taken_datetime` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: INCENTIVE_FUND
CREATE TABLE IF NOT EXISTS `INCENTIVE_FUND` (
  `fund_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `perf_id` INT,
  `quarter` TEXT,
  `net_profit` DECIMAL(14,2),
  `fund_rate` DECIMAL(14,2),
  `fund_amount` DECIMAL(14,2),
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: INSTALLMENT_PLAN
CREATE TABLE IF NOT EXISTS `INSTALLMENT_PLAN` (
  `installment_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `invoice_id` INT,
  `installment_count` INT,
  `first_due_date` TEXT,
  `status` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: INSURANCE_CLAIM
CREATE TABLE IF NOT EXISTS `INSURANCE_CLAIM` (
  `claim_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `invoice_id` INT,
  `policy_id` INT,
  `submitted_date` TEXT,
  `claimed_amount` DECIMAL(14,2),
  `approved_amount` DECIMAL(14,2),
  `status` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: INSURANCE_POLICY
CREATE TABLE IF NOT EXISTS `INSURANCE_POLICY` (
  `policy_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `patient_id` INT,
  `insurer_name` TEXT,
  `policy_no` VARCHAR(191),
  `coverage_scope` TEXT,
  `valid_until` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: INVOICE
CREATE TABLE IF NOT EXISTS `INVOICE` (
  `invoice_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `invoice_no` VARCHAR(191),
  `visit_id` INT,
  `invoice_date` TEXT,
  `status` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: INVOICE_LINE
CREATE TABLE IF NOT EXISTS `INVOICE_LINE` (
  `invoice_id` INT,
  `line_no` INT,
  `item_name` TEXT,
  `units_used` TEXT,
  `unit_price` DECIMAL(14,2),
  `line_subtotal` DECIMAL(14,2),
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT,
  PRIMARY KEY (invoice_id, line_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: MATERIAL
CREATE TABLE IF NOT EXISTS `MATERIAL` (
  `material_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `material_code` TEXT,
  `material_name` TEXT,
  `unit` TEXT,
  `is_high_value` INT,
  `reorder_point` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: MATERIAL_BATCH
CREATE TABLE IF NOT EXISTS `MATERIAL_BATCH` (
  `batch_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `material_id` INT,
  `batch_serial_no` VARCHAR(191),
  `expiry_date` TEXT,
  `purchase_unit_price` DECIMAL(14,2)
, received_qty DECIMAL(14,2) DEFAULT 0, issued_qty DECIMAL(14,2) DEFAULT 0) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: MATERIAL_ISSUE
CREATE TABLE IF NOT EXISTS `MATERIAL_ISSUE` (
  `issue_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `issue_no` VARCHAR(191),
  `batch_id` INT,
  `visit_id` INT,
  `quantity` DECIMAL(14,2),
  `issued_datetime` TEXT,
  `issued_by` TEXT
, clinic_id INT) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: MEDICAL_HISTORY
CREATE TABLE IF NOT EXISTS `MEDICAL_HISTORY` (
  `history_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `patient_id` INT,
  `record_date` TEXT,
  `condition_description` TEXT,
  `status` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: MEMBER
CREATE TABLE IF NOT EXISTS `MEMBER` (
  `member_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `patient_id` INT,
  `member_no` VARCHAR(191),
  `member_level` TEXT,
  `joined_date` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: NOTICE
CREATE TABLE IF NOT EXISTS `NOTICE` (
  `notice_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `account_id` INT,
  `patient_id` INT,
  `kind` TEXT,
  `title` TEXT,
  `body` TEXT,
  `ref_table` TEXT,
  `ref_id` INT,
  `created_at` TEXT,
  `read_at` VARCHAR(191),
  `is_void` INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: OPERATING_EXPENSE
CREATE TABLE IF NOT EXISTS `OPERATING_EXPENSE` (
  `expense_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `clinic_id` INT,
  `quarter` TEXT,
  `expense_category` TEXT,
  `amount` DECIMAL(14,2),
  `description` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: PATIENT
CREATE TABLE IF NOT EXISTS `PATIENT` (
  `patient_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `patient_no` INT,
  `name` TEXT,
  `date_of_birth` TEXT,
  `billing_address` TEXT,
  `phone` TEXT,
  `email` TEXT,
  `id_card_no` TEXT,
  `insurance_card_no` TEXT,
  `occupation` TEXT,
  `source_channel` TEXT,
  `first_visit_date` TEXT,
  `emergency_contact_name` TEXT,
  `emergency_contact_phone` TEXT,
  `account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: PAYMENT
CREATE TABLE IF NOT EXISTS `PAYMENT` (
  `payment_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `invoice_id` INT,
  `payment_no` VARCHAR(191),
  `amount` DECIMAL(14,2),
  `method` TEXT,
  `paid_datetime` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
, refund_reason TEXT, refund_no TEXT) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: PAYMENT_RECORD
CREATE TABLE IF NOT EXISTS `PAYMENT_RECORD` (
  `payment_record_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `payable_id` INT,
  `supplier_id` INT,
  `record_no` VARCHAR(191),
  `amount` DECIMAL(14,2),
  `method` TEXT,
  `paid_date` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: PURCHASE_ORDER
CREATE TABLE IF NOT EXISTS `PURCHASE_ORDER` (
  `po_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `po_no` VARCHAR(191),
  `supplier_id` INT,
  `term_id` INT,
  `order_date` TEXT,
  `expected_date` TEXT,
  `status` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
, clinic_id INT) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: PURCHASE_ORDER_LINE
CREATE TABLE IF NOT EXISTS `PURCHASE_ORDER_LINE` (
  `po_id` INT,
  `line_no` INT,
  `material_id` INT,
  `quantity` DECIMAL(14,2),
  `unit_price` DECIMAL(14,2),
  PRIMARY KEY (po_id, line_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: QUALIFICATION
CREATE TABLE IF NOT EXISTS `QUALIFICATION` (
  `qualification_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `qualification_code` TEXT,
  `qualification_name` TEXT,
  `issuing_body` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: QUALITY_INCIDENT
CREATE TABLE IF NOT EXISTS `QUALITY_INCIDENT` (
  `incident_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `visit_id` INT,
  `clinic_id` INT,
  `incident_type` TEXT,
  `description` TEXT,
  `occurred_date` TEXT,
  `severity` TEXT,
  `status` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: RECEIPT_LINE
CREATE TABLE IF NOT EXISTS `RECEIPT_LINE` (
  `receipt_id` INT,
  `line_no` INT,
  `material_id` INT,
  `batch_id` INT,
  `quantity` DECIMAL(14,2),
  PRIMARY KEY (receipt_id, line_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: RECEIPT_NOTE
CREATE TABLE IF NOT EXISTS `RECEIPT_NOTE` (
  `receipt_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `receipt_no` VARCHAR(191),
  `po_id` INT,
  `clinic_id` INT,
  `received_date` TEXT,
  `status` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: RECORD_ACCESS_LOG
CREATE TABLE IF NOT EXISTS `RECORD_ACCESS_LOG` (
  `access_log_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `patient_id` INT,
  `clinic_id` INT,
  `operator_name` TEXT,
  `access_datetime` TEXT,
  `purpose` TEXT,
  `authorization_ref` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: ROSTER
CREATE TABLE IF NOT EXISTS `ROSTER` (
  `roster_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `dentist_id` INT,
  `clinic_id` INT,
  `roster_date` TEXT,
  `slot_start` TEXT,
  `slot_end` TEXT,
  `slot_capacity` INT,
  `roster_status` TEXT,
  `is_published` INT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT,
  `is_reserved` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: SEQ
CREATE TABLE IF NOT EXISTS `SEQ` (
  `name` VARCHAR(191) PRIMARY KEY,
  `val` INT NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: SESSION
CREATE TABLE IF NOT EXISTS `SESSION` (
  `session_id` VARCHAR(191) PRIMARY KEY,
  `account_id` INT,
  `role` TEXT,
  `is_guest` INT,
  `csrf_token` TEXT,
  `issued_at` TEXT,
  `expires_at` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: SETTLEMENT_TERM
CREATE TABLE IF NOT EXISTS `SETTLEMENT_TERM` (
  `term_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `term_code` TEXT,
  `payment_days` INT,
  `return_ratio` DECIMAL(14,2),
  `fee_items` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: SHIFT_REQUEST
CREATE TABLE IF NOT EXISTS `SHIFT_REQUEST` (
  `request_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `clinic_id` INT,
  `requester_staff_id` INT,
  `dentist_id` INT,
  `request_date` TEXT,
  `slot_start` TEXT,
  `slot_end` TEXT,
  `direction` TEXT,
  `reason` TEXT,
  `request_status` TEXT,
  `approver_staff_id` INT,
  `approved_date` TEXT,
  `result_roster_id` INT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: SHIFT_REQUISITION
CREATE TABLE IF NOT EXISTS `SHIFT_REQUISITION` (
  `requisition_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `from_clinic_id` INT,
  `to_clinic_id` INT,
  `dentist_id` INT,
  `requisition_date` TEXT,
  `start_time` TEXT,
  `end_time` TEXT,
  `requisition_reason` TEXT,
  `requisition_status` TEXT,
  `requester_account_id` INT,
  `approver_account_id` INT,
  `submitted_at` TEXT,
  `approved_at` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: SHIFT_SUBSTITUTION
CREATE TABLE IF NOT EXISTS `SHIFT_SUBSTITUTION` (
  `substitution_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `roster_id` INT,
  `absent_dentist_id` INT,
  `substitute_dentist_id` INT,
  `source_clinic_id` INT,
  `effective_from` TEXT,
  `effective_to` TEXT,
  `reason_type` TEXT,
  `request_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: STAFF
CREATE TABLE IF NOT EXISTS `STAFF` (
  `staff_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `clinic_id` INT,
  `staff_no` INT,
  `name` TEXT,
  `role` TEXT,
  `phone` TEXT,
  `email` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: STANDARD_COST
CREATE TABLE IF NOT EXISTS `STANDARD_COST` (
  `cost_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `catalog_id` INT,
  `version_id` INT,
  `standard_cost` DECIMAL(14,2),
  `effective_date` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: STATEMENT
CREATE TABLE IF NOT EXISTS `STATEMENT` (
  `statement_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `statement_no` VARCHAR(191),
  `supplier_id` INT,
  `period_start` TEXT,
  `period_end` TEXT,
  `status` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: STATEMENT_LINE
CREATE TABLE IF NOT EXISTS `STATEMENT_LINE` (
  `statement_id` INT,
  `line_no` INT,
  `source_type` TEXT,
  `source_no` VARCHAR(191),
  `amount` DECIMAL(14,2),
  PRIMARY KEY (statement_id, line_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: STOCK_LEDGER
CREATE TABLE IF NOT EXISTS `STOCK_LEDGER` (
  `ledger_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `clinic_id` INT,
  `material_id` INT,
  `on_hand_qty` DECIMAL(14,2),
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: STOCK_MOVEMENT
CREATE TABLE IF NOT EXISTS `STOCK_MOVEMENT` (
  `movement_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `ledger_id` INT,
  `movement_type` TEXT,
  `direction` TEXT,
  `quantity` DECIMAL(14,2),
  `source_type` TEXT,
  `source_no` VARCHAR(191),
  `moved_datetime` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: SUPPLIER
CREATE TABLE IF NOT EXISTS `SUPPLIER` (
  `supplier_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `supplier_code` TEXT,
  `supplier_name` TEXT,
  `contact_name` TEXT,
  `phone` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: TREATMENT_CATALOG
CREATE TABLE IF NOT EXISTS `TREATMENT_CATALOG` (
  `catalog_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `item_code` TEXT,
  `item_name` TEXT,
  `unit` TEXT,
  `standard_unit_price` DECIMAL(14,2),
  `is_whole_mouth` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: TREATMENT_ITEM
CREATE TABLE IF NOT EXISTS `TREATMENT_ITEM` (
  `visit_id` INT,
  `line_no` INT,
  `catalog_id` INT,
  `dentist_id` INT,
  `tooth_fdi` TEXT,
  `standard_units` DECIMAL(14,2),
  `standard_unit_price` DECIMAL(14,2),
  `agreed_price` DECIMAL(14,2),
  `added_during_visit` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT,
  PRIMARY KEY (visit_id, line_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: TREATMENT_PLAN
CREATE TABLE IF NOT EXISTS `TREATMENT_PLAN` (
  `plan_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `visit_id` INT,
  `plan_no` VARCHAR(191),
  `created_date` TEXT,
  `plan_description` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: USER_ACCOUNT
CREATE TABLE IF NOT EXISTS `USER_ACCOUNT` (
  `account_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `login_name` TEXT,
  `password_hash` TEXT,
  `password_salt` TEXT,
  `role` TEXT,
  `staff_id` INT,
  `dentist_id` INT,
  `account_status` TEXT,
  `registered_at` TEXT,
  `last_login_at` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- table: VISIT
CREATE TABLE IF NOT EXISTS `VISIT` (
  `visit_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `visit_no` INT,
  `appointment_id` INT,
  `clinic_id` INT,
  `visit_datetime` TEXT,
  `treated` INT,
  `special_notes` TEXT,
  `chief_complaint` TEXT,
  `present_history` TEXT,
  `examination` TEXT,
  `diagnosis` TEXT,
  `treatment_note` TEXT,
  `is_void` INT,
  `void_reason` TEXT,
  `void_at` TEXT,
  `void_account_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- index: IX_NOTICE_ACCT
CREATE INDEX IX_NOTICE_ACCT ON `NOTICE`(`account_id`, `read_at`);

-- index: UX_APPT_ACTIVE
-- 部分唯一索引 UX_APPT_ACTIVE 的 MySQL 等价物（生成列 + 唯一索引）
ALTER TABLE `APPOINTMENT` ADD COLUMN `k_appt_active` VARCHAR(64) GENERATED ALWAYS AS (CASE WHEN `is_void`=0 AND `status` IN ('已预约','已到诊') THEN CONCAT_WS('/', `patient_id`, `roster_id`) END) STORED;
ALTER TABLE `APPOINTMENT` ADD UNIQUE INDEX `UX_APPT_ACTIVE` (`k_appt_active`);

-- index: UX_INVOICE_NO
-- 部分唯一索引 UX_INVOICE_NO 的 MySQL 等价物（生成列 + 唯一索引）
ALTER TABLE `INVOICE` ADD COLUMN `k_invoice_no` VARCHAR(64) GENERATED ALWAYS AS (CASE WHEN IFNULL(`is_void`,0)=0 THEN CONCAT_WS('/', `invoice_no`) END) STORED;
ALTER TABLE `INVOICE` ADD UNIQUE INDEX `UX_INVOICE_NO` (`k_invoice_no`);

-- index: UX_INVOICE_VISIT
-- 部分唯一索引 UX_INVOICE_VISIT 的 MySQL 等价物（生成列 + 唯一索引）
ALTER TABLE `INVOICE` ADD COLUMN `k_invoice_visit` VARCHAR(64) GENERATED ALWAYS AS (CASE WHEN IFNULL(`is_void`,0)=0 THEN CONCAT_WS('/', `visit_id`) END) STORED;
ALTER TABLE `INVOICE` ADD UNIQUE INDEX `UX_INVOICE_VISIT` (`k_invoice_visit`);

-- index: UX_PAYMENT_NO
-- 部分唯一索引 UX_PAYMENT_NO 的 MySQL 等价物（生成列 + 唯一索引）
ALTER TABLE `PAYMENT` ADD COLUMN `k_payment_no` VARCHAR(64) GENERATED ALWAYS AS (CASE WHEN `payment_no` IS NOT NULL THEN CONCAT_WS('/', `payment_no`) END) STORED;
ALTER TABLE `PAYMENT` ADD UNIQUE INDEX `UX_PAYMENT_NO` (`k_payment_no`);

-- index: UX_VISIT_APPT
-- 部分唯一索引 UX_VISIT_APPT 的 MySQL 等价物（生成列 + 唯一索引）
ALTER TABLE `VISIT` ADD COLUMN `k_visit_appt` VARCHAR(64) GENERATED ALWAYS AS (CASE WHEN `appointment_id` IS NOT NULL THEN CONCAT_WS('/', `appointment_id`) END) STORED;
ALTER TABLE `VISIT` ADD UNIQUE INDEX `UX_VISIT_APPT` (`k_visit_appt`);

SET FOREIGN_KEY_CHECKS=1;
