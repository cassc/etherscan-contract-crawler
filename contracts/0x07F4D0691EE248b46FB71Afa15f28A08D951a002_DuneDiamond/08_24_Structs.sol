// SPDX-License-Identifier: UNLICENSED
// © 2022 [XXX]. All rights reserved.
pragma solidity ^0.8.13;

struct Chapter {
	string name;
	string description;
	uint8 attributeTypeCount;

	// attributeTypeId => attributeType
	mapping(uint8 => Attribute.Type) attributeTypes;

	// tokenId => (attributeTypeId => Bitfield of attribute available)
	mapping(
		uint256 => mapping(
			uint8 => uint256
		)
	) availableAttributes;

	// tokenId => (attributeTypeId => attributeId active)
	mapping(
		uint256 => mapping(
			uint8 => uint8
		)
	) activeAttributes;
}

library Attribute {
	struct Selection {
		string name;
		string description;
		string dataUri;
	}

	struct Type {
		string name;
		string description;
		uint8 zIndex;
		bool visible;
		mapping(uint8 => Selection) selections;
	}
}

struct AppStorage {
	// =============================================================================
	// Artwork
	// =============================================================================

	// attributeTypeId reserved for chapters 
	uint8 chapterId;

	mapping(uint8 => Chapter) chapters;

	// attributeTypeId => attributeType
	mapping(uint8 => Attribute.Type) attributeTypes;

	// tokenId => (attributeTypeId => Bitfield of attribute available)
	mapping(
		uint256 => mapping(
			uint8 => uint256
		)
	) availableAttributes;

	// tokenId => (attributeTypeId => attributeId active)
	mapping(
		uint256 => mapping(
			uint8 => uint8
		)
	) activeAttributes;
	
	string tokenBaseExternalUrl;
	string contractLevelImageUrl;
	string contractLevelExternalUrl;

	// =============================================================================
	// Royalty
	// =============================================================================
	address royaltyWalletAddress;
	uint96 royaltyBasisPoints;
}

struct FacetAddressAndPosition {
	address facetAddress;
	uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
}

struct FacetFunctionSelectors {
	bytes4[] functionSelectors;
	uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
}

struct DiamondStorage {
	// maps function selector to the facet address and
	// the position of the selector in the facetFunctionSelectors.selectors array
	mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
	// maps facet addresses to function selectors
	mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
	// facet addresses
	address[] facetAddresses;
	// Used to query if a contract implements an interface.
	// Used to implement ERC-165.
	mapping(bytes4 => bool) supportedInterfaces;
}