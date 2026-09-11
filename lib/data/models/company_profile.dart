class CompanyProfile {
  const CompanyProfile({
    required this.userId,
    this.fullName = '',
    this.companyName,
    this.ice,
    this.ifNumber,
    this.rcNumber,
    this.tpNumber,
    this.activityType = 'services',
    this.address,
    this.city,
    this.phone,
    this.email,
    this.paymentTerms,
  });

  final String userId;
  final String fullName;
  final String? companyName;
  final String? ice;
  final String? ifNumber;
  final String? rcNumber;
  final String? tpNumber;
  final String activityType;
  final String? address;
  final String? city;
  final String? phone;
  final String? email;
  final String? paymentTerms;

  factory CompanyProfile.fromMap(Map<String, dynamic> map) => CompanyProfile(
        userId: map['user_id'] as String,
        fullName: map['full_name'] as String? ?? '',
        companyName: map['company_name'] as String?,
        ice: map['ice'] as String?,
        ifNumber: map['if_number'] as String?,
        rcNumber: map['rc_number'] as String?,
        tpNumber: map['tp_number'] as String?,
        activityType: map['activity_type'] as String? ?? 'services',
        address: map['company_address'] as String?,
        city: map['city'] as String?,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        paymentTerms: map['payment_terms'] as String?,
      );
}
