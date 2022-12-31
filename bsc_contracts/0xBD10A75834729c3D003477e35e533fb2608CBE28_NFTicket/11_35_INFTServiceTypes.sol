// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// First byte is Processing Mode: from here we derive the caluclation and account booking logic
// basic differentiator being Ticket or Certificate (of ownership)
// all tickets need lowest bit of first semi-byte set
// all certificates need lowest bit of first semi-byte set
// all checkin-checkout tickets need second-lowest bit of first-semi-byte set --> 0x03000000
// high bits for each byte or half.byte are categories, low bits are instances
uint32 constant IS_CERTIFICATE =    0x40000000; // 2nd highest bit of CERTT-half-byte = 1 - cannot use highest bit?
uint32 constant IS_TICKET =         0x08000000; // highest bit of ticket-halfbyte = 1
uint32 constant CHECKOUT_TICKET =   0x09000000; // highest bit of ticket-halfbyte = 1 AND lowest bit = 1
uint32 constant CASH_VOUCHER =      0x0A000000; // highest bit of ticket-halfbyte = 1 AND 2nd bit = 1

// company identifiers last 10 bbits, e.g. 1023 companies
uint32 constant BLOXMOVE = 0x00000200; // top of 10 bits for company identifiers
uint32 constant NRVERSE = 0x00000001;
uint32 constant MITTWEIDA = 0x00000002;
uint32 constant EQUOTA = 0x00000003;

// Industrial Category - byte2
uint32 constant THG = 0x80800000; //  CERTIFICATE & highest bit of category half-byte = 1
uint32 constant REC = 0x80400000; //  CERTIFICATE & 2nd highest bit of category half-byte = 1

// Last byte is company identifier 1-255
uint32 constant NRVERSE_REC = 0x80800001; // CERTIFICATE & REC & 0x00000001
uint32 constant eQUOTA_THG = 0x80400003; // CERTIFICATE & THG & 0x00000003
uint32 constant MITTWEIDA_M4A = 0x09000002; // CHECKOUT_TICKET & MITTWEIDA
uint32 constant BLOXMOVE_CO = 0x09000200;
uint32 constant BLOXMOVE_CV = 0x0A000200;
uint32 constant BLOXMOVE_CI = 0x08000200;
uint32 constant BLOXMOVE_NG = 0x09000201;
uint32 constant DutchMaaS = 0x09000003;
uint32 constant TIER_MW = 0x09000004;

/***********************************************
 *
 * generic schematizable data payload
 * allows for customization between reseller and
 * service operator while keeping NFTicket agnostic
 *
 ***********************************************/

enum eDataType {
    _UNDEF,
    _UINT,
    _UINT256,
    _USTRING
}

struct TicketInfo {
    uint256 ticketFee;
    bool ticketUsed;
}

/*
* TODO reconcile overlaps between Payload, BuyNFTicketParams and Ticket
*/
struct Ticket {
    uint256 tokenID;
    address serviceProvider; // the index to the map where we keep info about serviceProviders
    uint32 serviceDescriptor;
    address issuedTo;
    uint256 certValue;
    uint certValidFrom; // value can be redeemedn after this time
    uint256 price;
    uint256 credits; // [7]
    uint256 pricePerCredit;
    uint256 serviceFee;
    uint256 resellerFee;
    uint256 transactionFee;
    string tokenURI;
}

struct Payload {
    address recipient;
    string tokenURI;
    DataSchema schema;
    string[] data;
    string[] serializedTicket;
    uint256 certValue;
    string uuid;
    uint256 credits;
    uint256 pricePerCredit;
    uint256 price;
    uint256 timestamp;
}

/**** END TODO overlap */

enum CheckInMode {checkin, checkout, neither}

struct DataSchema {
    string name;
    uint32 size;
    string[] keys;
    uint8[] keyTypes;
}

struct DataRecords {
    DataSchema _schema;
    string[] _data; // a one-dimensional array of length [_schema.size * <number of records> ]
}

struct ConsumedRecord {
    uint certId;
    string energyType;
    string location;
    uint amount;
}