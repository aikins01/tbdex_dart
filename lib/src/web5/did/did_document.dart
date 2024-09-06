import 'dart:convert';

class DIDDocument {
  final String id;
  final List<String>? context;
  final List<String>? alsoKnownAs;
  final String? controller;
  final List<VerificationMethod>? verificationMethod;
  final List<Service>? service;
  final List<String>? authentication;
  final List<String>? assertionMethod;
  final List<String>? keyAgreement;
  final List<String>? capabilityInvocation;
  final List<String>? capabilityDelegation;

  DIDDocument({
    required this.id,
    this.context,
    this.alsoKnownAs,
    this.controller,
    this.verificationMethod,
    this.service,
    this.authentication,
    this.assertionMethod,
    this.keyAgreement,
    this.capabilityInvocation,
    this.capabilityDelegation,
  });

  factory DIDDocument.fromJson(Map<String, dynamic> json) {
    return DIDDocument(
      id: json['id'],
      context: (json['@context'] as List?)?.cast<String>(),
      alsoKnownAs: (json['alsoKnownAs'] as List?)?.cast<String>(),
      controller: json['controller'],
      verificationMethod: (json['verificationMethod'] as List?)
          ?.map((vm) => VerificationMethod.fromJson(vm))
          .toList(),
      service:
          (json['service'] as List?)?.map((s) => Service.fromJson(s)).toList(),
      authentication: (json['authentication'] as List?)?.cast<String>(),
      assertionMethod: (json['assertionMethod'] as List?)?.cast<String>(),
      keyAgreement: (json['keyAgreement'] as List?)?.cast<String>(),
      capabilityInvocation:
          (json['capabilityInvocation'] as List?)?.cast<String>(),
      capabilityDelegation:
          (json['capabilityDelegation'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (context != null) '@context': context,
      if (alsoKnownAs != null) 'alsoKnownAs': alsoKnownAs,
      if (controller != null) 'controller': controller,
      if (verificationMethod != null)
        'verificationMethod':
            verificationMethod!.map((vm) => vm.toJson()).toList(),
      if (service != null) 'service': service!.map((s) => s.toJson()).toList(),
      if (authentication != null) 'authentication': authentication,
      if (assertionMethod != null) 'assertionMethod': assertionMethod,
      if (keyAgreement != null) 'keyAgreement': keyAgreement,
      if (capabilityInvocation != null)
        'capabilityInvocation': capabilityInvocation,
      if (capabilityDelegation != null)
        'capabilityDelegation': capabilityDelegation,
    };
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}

class VerificationMethod {
  final String id;
  final String type;
  final String controller;
  final Map<String, dynamic>? publicKeyJwk;
  final String? publicKeyMultibase;

  VerificationMethod({
    required this.id,
    required this.type,
    required this.controller,
    this.publicKeyJwk,
    this.publicKeyMultibase,
  });

  factory VerificationMethod.fromJson(Map<String, dynamic> json) {
    return VerificationMethod(
      id: json['id'],
      type: json['type'],
      controller: json['controller'],
      publicKeyJwk: json['publicKeyJwk'],
      publicKeyMultibase: json['publicKeyMultibase'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'controller': controller,
      if (publicKeyJwk != null) 'publicKeyJwk': publicKeyJwk,
      if (publicKeyMultibase != null) 'publicKeyMultibase': publicKeyMultibase,
    };
  }
}

class Service {
  final String id;
  final String type;
  final String serviceEndpoint;

  Service({
    required this.id,
    required this.type,
    required this.serviceEndpoint,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      type: json['type'],
      serviceEndpoint: json['serviceEndpoint'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'serviceEndpoint': serviceEndpoint,
    };
  }
}
