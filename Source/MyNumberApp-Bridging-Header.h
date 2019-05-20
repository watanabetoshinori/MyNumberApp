//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Security/CMSDecoder.h>
#import <Security/SecAsn1Coder.h>
#import <Security/SecAsn1Templates.h>
#import <Security/SecRequirement.h>

typedef struct {
    size_t          length;
    unsigned char   *data;
} ASN1_Data;

typedef struct {
    ASN1_Data type;     // INTEGER
    ASN1_Data version;  // INTEGER
    ASN1_Data value;    // OCTET STRING
} RVNReceiptAttribute;

typedef struct {
    RVNReceiptAttribute **attrs;
} RVNReceiptPayload;

//// ASN.1 receipt attribute template
static const SecAsn1Template kReceiptAttributeTemplate[] = {
    { SEC_ASN1_SEQUENCE, 0, NULL, sizeof(RVNReceiptAttribute) },
    { SEC_ASN1_INTEGER, offsetof(RVNReceiptAttribute, type), NULL, 0 },
    { SEC_ASN1_INTEGER, offsetof(RVNReceiptAttribute, version), NULL, 0 },
    { SEC_ASN1_OCTET_STRING, offsetof(RVNReceiptAttribute, value), NULL, 0 },
    { 0, 0, NULL, 0 }
};

// ASN.1 receipt template set
static const SecAsn1Template kSetOfReceiptAttributeTemplate[] = {
    { SEC_ASN1_SET_OF, 0, kReceiptAttributeTemplate, sizeof(RVNReceiptPayload) },
    { 0, 0, NULL, 0 }
};
