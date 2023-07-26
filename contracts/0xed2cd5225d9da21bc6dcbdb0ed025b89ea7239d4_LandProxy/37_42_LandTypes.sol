// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Enums

enum MintState {
	CLOSED,
	PRESALE,
	OPEN
}

// item category
enum Category {
	UNKNOWN,
	ONExONE,
	TWOxTWO,
	THREExTHREE,
	SIXxSIX
}

// Data Types

// defines the valid range of token id's of a segment
struct Segment {
	uint16 count; // count of tokens minted in the segment
	uint16 max; // max available for the segment (make sure it doesnt overflow)
	uint24 startIndex; // starting index of the segment
	uint24 endIndex; // end index of the segment
}

// price per type
struct SegmentPrice {
	uint64 one; // 1x1
	uint64 two; // 2x2
	uint64 three; // 3x3
	uint64 four; // 6x6
}

// a zone is a specific area of land
struct Zone {
	Segment one; // 1x1
	Segment two; // 2x2
	Segment three; // 3x3
	Segment four; // 6x6
}

// Init Args

// initialization args for the proxy
struct LandInitArgs {
	address signer;
	address lions;
	address icons;
	SegmentPrice price;
	SegmentPrice lionsDiscountPrice;
	Zone zoneOne; // City
	Zone zoneTwo; // Lion
}

// requests

// request to mint a single item
struct MintRequest {
	address to;
	uint64 deadline; // block.timestamp
	uint8 zoneId;
	uint8 segmentId;
	uint16 count;
}

// request to mint many different types
// expects the SegmentCount array to be in index order
struct MintManyRequest {
	address to;
	uint64 deadline;
	SegmentCount[] zones;
}

// requested amount for a specific segment
struct SegmentCount {
	uint16 countOne; // 1x1
	uint16 countTwo; // 2x2
	uint16 countThree; // 3x3
	uint16 countFour; // 6x6
}