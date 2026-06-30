/// Official Uni Eats policy documents shown in the vendor app's Legal section.
///
/// Content is curated for the restaurant-vendor audience from the source policy
/// documents (Legal/POLICIES/uni-eats-policies). Internal-only material
/// (signature blocks, revision tables, employee-only role duties, engineering
/// controls) is trimmed; everything that governs or informs a restaurant vendor
/// is kept. Baked in as Dart constants so policies are fully readable offline.
library;

enum PolicyBlockType { paragraph, bullet, subhead }

/// One renderable unit inside a policy section.
class PolicyBlock {
  final PolicyBlockType type;
  final String text;
  const PolicyBlock.p(this.text) : type = PolicyBlockType.paragraph;
  const PolicyBlock.b(this.text) : type = PolicyBlockType.bullet;
  const PolicyBlock.h(this.text) : type = PolicyBlockType.subhead;
}

class PolicySection {
  final String heading;
  final List<PolicyBlock> blocks;
  const PolicySection(this.heading, this.blocks);
}

class PolicyDoc {
  final String ref;
  final String title;
  final String effectiveDate;

  /// One-line "key takeaway" shown in the highlighted intro card.
  final String takeaway;
  final List<PolicySection> sections;

  const PolicyDoc({
    required this.ref,
    required this.title,
    required this.effectiveDate,
    required this.takeaway,
    required this.sections,
  });
}

/// All policies surfaced in the vendor app, in display order.
const List<PolicyDoc> kVendorPolicies = [
  _dataPrivacy,
  _foodSafety,
  _acceptableUse,
  _refundCancellation,
  _paymentSecurity,
  _dataRetention,
];

// =============================================================================
// UE-POL-PRIV-001 — Data Protection & Privacy
// =============================================================================
const _dataPrivacy = PolicyDoc(
  ref: 'UE-POL-PRIV-001',
  title: 'Data Protection & Privacy',
  effectiveDate: '22 June 2026',
  takeaway:
      'Data protection is a legal requirement, not a choice. Every restaurant '
      'partner that handles Uni Eats data — including customer order details — '
      'has a responsibility to protect it, under Qatar PDPPL Law 13/2016.',
  sections: [
    PolicySection('1. Purpose & Scope', [
      PolicyBlock.p(
          'This policy governs how Uni Eats collects, uses, stores, shares, and '
          'destroys personal data, in compliance with the Qatar Personal Data '
          'Privacy Protection Law (Law No. 13 of 2016) and applicable international '
          'data protection laws.'),
      PolicyBlock.p(
          'It applies to the personal data of everyone who uses Uni Eats, '
          'including restaurant vendors who use the Vendor App and the customer '
          'data vendors access to fulfil orders.'),
    ]),
    PolicySection('2. Our Data Protection Principles', [
      PolicyBlock.b('Lawfulness, fairness, and transparency: we process data lawfully and tell you how it is used.'),
      PolicyBlock.b('Purpose limitation: we collect data only for specified, legitimate purposes.'),
      PolicyBlock.b('Data minimisation: we collect only what is necessary.'),
      PolicyBlock.b('Accuracy: we keep data accurate and up to date; inaccurate data is corrected or erased without delay.'),
      PolicyBlock.b('Storage limitation: we retain data only as long as necessary.'),
      PolicyBlock.b('Integrity and confidentiality: we protect data against unauthorised processing, loss, or damage.'),
      PolicyBlock.b('Accountability: we keep records of processing and can demonstrate compliance.'),
    ]),
    PolicySection('3. Your Responsibilities as a Vendor', [
      PolicyBlock.p('Every restaurant partner with access to personal data must:'),
      PolicyBlock.b('Use customer data (name, contact details, order notes) only to prepare and fulfil the order.'),
      PolicyBlock.b('Report any suspected data breach, unauthorised access, or loss of personal data immediately.'),
      PolicyBlock.b('Not download, screenshot, copy, or transfer customer personal data to personal devices or unauthorised systems.'),
      PolicyBlock.b('Not contact customers outside the Uni Eats platform for anything unrelated to the current order.'),
      PolicyBlock.b('Keep Vendor App login credentials confidential and never share your account.'),
    ]),
    PolicySection('4. Your Data Rights', [
      PolicyBlock.p('Under Qatar PDPPL Law 13/2016 you have the following rights over your own personal and business data:'),
      PolicyBlock.h('Access'),
      PolicyBlock.p('Request a copy of your data by emailing unieats.qa@gmail.com with the subject "Data Access Request". Responded to within 30 days.'),
      PolicyBlock.h('Rectification'),
      PolicyBlock.p('Correct basic data (restaurant name, contact, location) via in-app profile edit. Email the DPO for verification data such as business registration.'),
      PolicyBlock.h('Erasure'),
      PolicyBlock.p('Request deletion of your data within 30 days, unless retention is required by law (e.g. commercial and payment records). Data that cannot be erased is anonymised.'),
      PolicyBlock.h('Restrict Processing'),
      PolicyBlock.p('Request that processing be paused while a dispute about accuracy or lawfulness is resolved.'),
      PolicyBlock.h('Data Portability'),
      PolicyBlock.p('Receive the data you provided (business details, menu, order history) in JSON or CSV format.'),
      PolicyBlock.h('Object & Withdraw Consent'),
      PolicyBlock.p('Opt out of marketing at any time via app settings, and withdraw consent for processing based on consent.'),
    ]),
    PolicySection('5. How We Secure Your Data', [
      PolicyBlock.b('In transit: TLS 1.3 for all API communications, app traffic, and admin access.'),
      PolicyBlock.b('At rest: AES-256 encryption for databases containing personal data.'),
      PolicyBlock.b('Passwords: hashed using bcrypt or Argon2id with salting.'),
      PolicyBlock.b('Access control: role-based access and least privilege — you only access data necessary for your role.'),
      PolicyBlock.b('Logging: all access to personal data is logged, and anomalous patterns trigger alerts.'),
    ]),
    PolicySection('6. Data Breaches', [
      PolicyBlock.p(
          'Personal data breaches are reported to the Qatar MCIT / CDPD within 72 '
          'hours of discovery. If a breach is likely to put your rights at high '
          'risk, you will be notified without undue delay by email and in-app '
          'notification.'),
      PolicyBlock.p('To raise a data protection question or request, contact unieats.qa@gmail.com.'),
    ]),
  ],
);

// =============================================================================
// UE-POL-FOOD-001 — Food Safety & Handling
// =============================================================================
const _foodSafety = PolicyDoc(
  ref: 'UE-POL-FOOD-001',
  title: 'Food Safety & Handling',
  effectiveDate: '22 June 2026',
  takeaway:
      'Food safety is non-negotiable. Every restaurant vendor must comply with '
      'Qatari food safety regulations and the standards in this policy. Uni Eats '
      'will suspend vendors who fail to meet them.',
  sections: [
    PolicySection('1. Purpose & Scope', [
      PolicyBlock.p(
          'This policy sets the minimum food safety standards that every vendor '
          'and driver on the Uni Eats platform must follow. It supports compliance '
          'with the Qatar Food Safety Law (Law No. 8 of 1990), the Ministry of '
          'Public Health (MOPH), and the Municipality of Doha (Baladiya).'),
      PolicyBlock.p(
          'It covers food preparation, storage, packaging, and the handover of '
          'orders to delivery drivers.'),
    ]),
    PolicySection('2. Your Responsibilities as a Vendor', [
      PolicyBlock.b('Maintain a valid food establishment licence from the Municipality of Doha (Baladiya) and display it prominently.'),
      PolicyBlock.b('Comply with all MOPH food safety requirements, including kitchen hygiene, staff training, and temperature control.'),
      PolicyBlock.b('Ensure all food prepared for Uni Eats orders is safe, properly cooked, and free from contamination.'),
      PolicyBlock.b('Package food in tamper-evident, spill-proof containers that maintain quality during transport.'),
      PolicyBlock.b('Label all packaged items with the order number, item name, and any allergen information.'),
      PolicyBlock.b('Notify Uni Eats immediately of any food safety issue, recall, or regulatory action.'),
    ]),
    PolicySection('3. Kitchen & Facility Standards', [
      PolicyBlock.b('Operate from a licensed commercial kitchen. Home-based food preparation is not permitted on the platform.'),
      PolicyBlock.b('Undergo periodic health inspections by MOPH or Baladiya and provide reports to Uni Eats on request.'),
      PolicyBlock.b('Maintain separate storage areas for raw and cooked foods to prevent cross-contamination.'),
      PolicyBlock.h('Staff Hygiene'),
      PolicyBlock.b('All kitchen staff must hold valid food handler cards or equivalent training certification.'),
      PolicyBlock.b('Staff must wash hands before handling food and after any activity that could contaminate them.'),
      PolicyBlock.b('Staff with symptoms of illness (vomiting, diarrhoea, fever, infected cuts) must not handle food.'),
      PolicyBlock.b('Hair must be covered, and clean uniforms or aprons worn at all times during food preparation.'),
      PolicyBlock.h('Temperature Control'),
      PolicyBlock.b('Hot food must be held at 63°C or above before packaging for delivery.'),
      PolicyBlock.b('Cold food must be held at 5°C or below before packaging.'),
      PolicyBlock.b('Frozen food must be stored at −18°C or below.'),
      PolicyBlock.b('Temperature logs must be maintained for refrigeration and hot-hold equipment.'),
    ]),
    PolicySection('4. Allergen Management', [
      PolicyBlock.b('Provide accurate allergen information for every menu item.'),
      PolicyBlock.b('Ensure customers can view allergen information before placing an order.'),
      PolicyBlock.b('Communicate cross-contact risks to customers who disclose allergies in order notes.'),
      PolicyBlock.b('Update menu allergen information within 48 hours of any recipe change.'),
    ]),
    PolicySection('5. Packaging Standards', [
      PolicyBlock.b('Package all food in food-grade, leak-proof, tamper-evident containers.'),
      PolicyBlock.b('Match packaging to the food type: liquids in sealed containers, hot food in insulated packaging, cold food in chilled packaging.'),
      PolicyBlock.b('Seal each package with a tamper-evident seal or sticker provided or approved by Uni Eats.'),
      PolicyBlock.b('Eco-friendly packaging is encouraged and must comply with applicable environmental regulations in Qatar.'),
    ]),
    PolicySection('6. Incident Reporting', [
      PolicyBlock.p('Report any food safety incident to Uni Eats operations within 2 hours of discovery. This includes:'),
      PolicyBlock.b('A customer complaint alleging foodborne illness.'),
      PolicyBlock.b('Discovery of contaminated, spoiled, or incorrectly prepared food.'),
      PolicyBlock.b('A packaging failure resulting in spillage, leakage, or contamination.'),
      PolicyBlock.b('A temperature control failure at your premises.'),
      PolicyBlock.b('A regulatory inspection or enforcement action at your premises.'),
    ]),
  ],
);

// =============================================================================
// UE-POL-AUP-001 — Acceptable Use
// =============================================================================
const _acceptableUse = PolicyDoc(
  ref: 'UE-POL-AUP-001',
  title: 'Acceptable Use Policy',
  effectiveDate: '22 June 2026',
  takeaway:
      'Every user of Uni Eats systems is responsible for using them responsibly. '
      'Misuse — accidental or intentional — can lead to data breaches, legal '
      'liability, and removal from the platform.',
  sections: [
    PolicySection('1. Purpose & Scope', [
      PolicyBlock.p(
          'This policy establishes clear rules for the responsible and secure use '
          'of Uni Eats systems, devices, networks, and data. It applies to '
          'everyone who accesses any Uni Eats system, including restaurant vendors '
          'using the Vendor App.'),
      PolicyBlock.p(
          'It supports compliance with the Qatar Cybercrime Law (Law No. 14 of '
          '2014) and the Personal Data Privacy Protection Law (Law No. 13 of 2016).'),
    ]),
    PolicySection('2. Your Responsibilities', [
      PolicyBlock.b('Use Uni Eats systems only for lawful purposes and in compliance with Qatari law.'),
      PolicyBlock.b('Protect the confidentiality, integrity, and availability of Uni Eats data and systems.'),
      PolicyBlock.b('Use strong passwords and keep your credentials confidential.'),
      PolicyBlock.b('Report suspected security incidents, policy violations, or vulnerabilities immediately.'),
      PolicyBlock.b('Log out when not in active use and lock your device when unattended.'),
      PolicyBlock.b('Respect the privacy of Uni Eats customers, partners, and employees.'),
    ]),
    PolicySection('3. Prohibited Uses', [
      PolicyBlock.h('Unauthorised Access'),
      PolicyBlock.b('Accessing any Uni Eats system, account, or data without authorisation.'),
      PolicyBlock.b('Sharing account credentials, passwords, or tokens with anyone.'),
      PolicyBlock.b('Using another person\'s account, or circumventing security controls.'),
      PolicyBlock.h('Data Misuse'),
      PolicyBlock.b('Copying, modifying, or deleting data without authorisation.'),
      PolicyBlock.b('Transferring Uni Eats data to personal devices or unapproved storage.'),
      PolicyBlock.b('Sharing customer personal data (names, phone numbers, addresses) with unauthorised parties.'),
      PolicyBlock.b('Screenshotting, photographing, or recording customer information or order details.'),
      PolicyBlock.h('System Abuse'),
      PolicyBlock.b('Installing unauthorised software or connecting unauthorised hardware.'),
      PolicyBlock.b('Introducing malware or malicious code.'),
      PolicyBlock.b('Conducting security testing without explicit written authorisation.'),
      PolicyBlock.h('Conduct & Financial Integrity'),
      PolicyBlock.b('Harassing, threatening, or bullying other users, employees, customers, or partners.'),
      PolicyBlock.b('Misrepresenting your identity, role, or affiliation with Uni Eats.'),
      PolicyBlock.b('Tampering with payment amounts, fees, commissions, or financial records.'),
      PolicyBlock.b('Exploiting pricing errors, discount codes, or promotions for unfair gain.'),
    ]),
    PolicySection('4. System & Account Security', [
      PolicyBlock.b('Use strong, unique passwords of at least 12 characters for all Uni Eats accounts.'),
      PolicyBlock.b('Enable multi-factor authentication (MFA) on all accounts that support it.'),
      PolicyBlock.b('Lock your device screen when leaving it unattended, even briefly.'),
      PolicyBlock.b('Report lost or stolen devices immediately.'),
      PolicyBlock.b('Keep the Vendor App updated to the latest version.'),
      PolicyBlock.b('Do not use public or unsecured Wi-Fi when accessing systems containing customer data.'),
      PolicyBlock.b('Do not share your Vendor App login or let others use your account.'),
    ]),
    PolicySection('5. Monitoring & Reporting', [
      PolicyBlock.p(
          'Uni Eats may monitor, record, and review use of its systems to ensure '
          'compliance — including access logs and audits of data access patterns. '
          'You should not expect privacy when using Uni Eats-owned systems.'),
      PolicyBlock.p(
          'Report suspected violations to unieats.qa@gmail.com. Reports may be made '
          'anonymously, are handled confidentially, and no retaliation will be '
          'taken against anyone who reports in good faith.'),
    ]),
  ],
);

// =============================================================================
// UE-POL-REF-001 — Refund & Cancellation
// =============================================================================
const _refundCancellation = PolicyDoc(
  ref: 'UE-POL-REF-001',
  title: 'Refund & Cancellation',
  effectiveDate: '22 June 2026',
  takeaway:
      'Every refund and cancellation is handled promptly, transparently, and '
      'fairly. Vendors are compensated for completed work, and clear rules '
      'govern when an order can be cancelled.',
  sections: [
    PolicySection('1. Purpose & Scope', [
      PolicyBlock.p(
          'This policy sets clear rules for when and how orders can be cancelled '
          'or refunded, balancing the interests of customers, vendors, and drivers '
          'while complying with the Qatar Consumer Protection Law (Law No. 8 of 2008).'),
    ]),
    PolicySection('2. Order Cancellations', [
      PolicyBlock.h('Customer-Initiated'),
      PolicyBlock.b('A customer may cancel free of charge any time before your restaurant accepts the order.'),
      PolicyBlock.b('Once you accept the order, the customer may only cancel if you agree.'),
      PolicyBlock.b('After a driver picks up the order, cancellation is not possible — the customer must refuse delivery and contact support for a refund.'),
      PolicyBlock.h('Restaurant-Initiated'),
      PolicyBlock.b('You may cancel an order if items are unavailable or you cannot fulfil it.'),
      PolicyBlock.b('The customer is notified immediately and a full refund is processed automatically if already paid.'),
      PolicyBlock.b('Frequent restaurant-initiated cancellations may affect your standing on the platform.'),
      PolicyBlock.h('Force Majeure'),
      PolicyBlock.b('During a campus closure, severe weather, or public health emergency, in-progress orders may be cancelled with full refunds to customers.'),
      PolicyBlock.b('Vendors are compensated for completed work up to the point of cancellation, at Uni Eats discretion.'),
    ]),
    PolicySection('3. Vendor Compensation & Disputes', [
      PolicyBlock.b('You are compensated for orders you have begun preparing when a cancellation is not your fault.'),
      PolicyBlock.b('You may dispute a cancellation that affected your earnings via Uni Eats support.'),
      PolicyBlock.b('Uni Eats reviews order logs and timestamps to determine how far an order had progressed.'),
      PolicyBlock.b('No compensation is due for orders cancelled before you accepted them.'),
    ]),
    PolicySection('4. Refund Processing', [
      PolicyBlock.p('For awareness, approved customer refunds are processed within 5–10 business days of approval:'),
      PolicyBlock.b('Card payments (noqoody): credited to the original card; timing depends on the issuing bank.'),
      PolicyBlock.b('QPay: refunded to the original account within 3 business days.'),
      PolicyBlock.b('Wallet payments: credited to the in-app wallet within 24 hours.'),
      PolicyBlock.b('Cash on delivery: the customer is not charged, so no refund is needed.'),
    ]),
  ],
);

// =============================================================================
// UE-POL-PAY-001 — Payment Security & noqoody Handling
// =============================================================================
const _paymentSecurity = PolicyDoc(
  ref: 'UE-POL-PAY-001',
  title: 'Payment Security',
  effectiveDate: '22 June 2026',
  takeaway:
      'No cardholder data ever touches Uni Eats — or your — systems. All '
      'payments are processed through noqoody, a PCI DSS Level 1 certified '
      'gateway, so card details are entered only into noqoody\'s secure interface.',
  sections: [
    PolicySection('1. Purpose & Scope', [
      PolicyBlock.p(
          'This policy establishes how card payments, QPay transactions, and '
          'digital wallet payments are processed securely through the noqoody '
          'payment gateway. It supports compliance with the Qatar Central Bank '
          'Payment Services Regulation (QCB PSR) and PCI DSS v4.0.'),
      PolicyBlock.p(
          'It applies to every payment for an order on the Uni Eats platform and '
          'to how vendors receive and reconcile settlement for those orders.'),
    ]),
    PolicySection('2. How Payments Work', [
      PolicyBlock.b('Customers pay through noqoody\'s PCI-certified hosted interface — Uni Eats never sees the card number, CVV, or PIN.'),
      PolicyBlock.b('Uni Eats stores only a tokenised transaction reference, amount, timestamp, and status — never cardholder data.'),
      PolicyBlock.b('noqoody confirms the final transaction status, and the order is released to your restaurant for preparation.'),
      PolicyBlock.b('Card details are meaningless outside noqoody and cannot be used to derive a customer\'s real card number.'),
    ]),
    PolicySection('3. Your Responsibilities as a Vendor', [
      PolicyBlock.b('Never ask a customer for their card number, CVV, PIN, or full payment details — inside or outside the app.'),
      PolicyBlock.b('Never attempt to collect payment for a Uni Eats order through any channel other than the Uni Eats platform.'),
      PolicyBlock.b('Treat order and payment metadata you can see (amount, status, transaction ID) as confidential.'),
      PolicyBlock.b('Report any suspected payment fraud, tampering, or suspicious order pattern to Uni Eats immediately.'),
      PolicyBlock.b('Keep your Vendor App account secure with a strong password and MFA where available.'),
    ]),
    PolicySection('4. Settlement & Reconciliation', [
      PolicyBlock.b('Payouts are calculated from completed orders, net of the agreed platform commission.'),
      PolicyBlock.b('noqoody settlement reports are reconciled against order records before payout.'),
      PolicyBlock.b('Raise any settlement discrepancy with Uni Eats finance, who will review the underlying transaction logs.'),
      PolicyBlock.b('Payment transaction records are retained for the period required by QCB regulations.'),
    ]),
    PolicySection('5. Fraud & Chargebacks', [
      PolicyBlock.p(
          'Uni Eats monitors transactions for fraud and money-laundering patterns '
          'and reports suspicious activity to the Qatar authorities as required by '
          'law. Vendors must cooperate with any investigation.'),
      PolicyBlock.b('For disputed transactions, Uni Eats preserves order records, delivery confirmations, and communications as evidence.'),
      PolicyBlock.b('Provide any requested order documentation promptly to help resolve a chargeback in the platform\'s favour.'),
    ]),
  ],
);

// =============================================================================
// UE-POL-DR-001 — Data Retention & Deletion
// =============================================================================
const _dataRetention = PolicyDoc(
  ref: 'UE-POL-DR-001',
  title: 'Data Retention & Deletion',
  effectiveDate: '22 June 2026',
  takeaway:
      'No data is kept indefinitely. Every category of data Uni Eats holds has a '
      'defined retention period and a documented deletion procedure, in '
      'compliance with Qatar PDPPL Law 13/2016.',
  sections: [
    PolicySection('1. Purpose & Scope', [
      PolicyBlock.p(
          'This policy establishes standardised retention periods and secure '
          'disposal procedures for all data held by Uni Eats. It ensures personal '
          'data is not kept longer than necessary and is securely destroyed when '
          'no longer needed.'),
      PolicyBlock.p(
          'It applies to all data processed through the Customer App, Vendor App, '
          'Driver App, Admin Dashboard, and website — including your restaurant '
          'records and the order data you handle.'),
    ]),
    PolicySection('2. Our Commitment', [
      PolicyBlock.b('Collect only what is necessary, retain it only as long as needed, and delete it securely.'),
      PolicyBlock.b('Maintain a documented retention schedule for every data category.'),
      PolicyBlock.b('Use automated deletion mechanisms where technically feasible.'),
      PolicyBlock.b('Respond to data subject deletion requests within the timeframe required by law.'),
      PolicyBlock.b('Never retain data beyond its scheduled period unless a legal hold requires it.'),
    ]),
    PolicySection('3. Retention Schedule (Key Categories)', [
      PolicyBlock.h('Restaurant / Vendor Records'),
      PolicyBlock.p('Business registration, owner details, menu data, commission records, contact, and bank details — retained for the duration of the active partnership plus 2 years after deactivation (contractual and commercial-records obligations).'),
      PolicyBlock.h('Order History'),
      PolicyBlock.p('Order details, prices, restaurant, driver, location, and status history — retained for 2 years from order completion, then anonymised (Qatar Consumer Protection Law and tax compliance).'),
      PolicyBlock.h('Payment Data'),
      PolicyBlock.p('Payment metadata (last 4 digits, card type), transaction ID, amount, status, and refund records — retained for 3 years from the transaction date (Qatar Central Bank requirements).'),
      PolicyBlock.h('Communication Records'),
      PolicyBlock.p('Support tickets, in-app messages, and correspondence — retained for 2 years from the last communication.'),
      PolicyBlock.h('System Audit Logs'),
      PolicyBlock.p('Authentication events, API calls, and data-access logs — retained for up to 3 years for security and compliance.'),
    ]),
    PolicySection('4. Deletion & Your Rights', [
      PolicyBlock.p(
          'When a retention period expires, data is permanently deleted from '
          'active systems and backups, or irreversibly anonymised. Data under a '
          'legal hold is preserved until the hold is formally released.'),
      PolicyBlock.p(
          'To request access to, or deletion of, your data, email '
          'unieats.qa@gmail.com. Requests are handled within 30 days, subject to '
          'legal retention obligations such as commercial and payment records.'),
    ]),
  ],
);
