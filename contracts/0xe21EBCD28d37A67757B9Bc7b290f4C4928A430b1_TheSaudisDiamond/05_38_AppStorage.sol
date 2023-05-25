// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Attributes.sol";

library AppStorage {
	struct State {
		// =============================================================================
		// Pausable
		// =============================================================================
		bool paused;
		
		// =============================================================================
		// ERC721A
		// =============================================================================
		// The tokenId of the next token to be minted.
		uint256 currentIndex;

		// The number of tokens burned.
		uint256 burnCounter;

		// Token name
		string name;

		// Token symbol
		string symbol;

		// Token Version
		string version;

		// Token description
		string description;

		// Mapping from token ID to ownership details
		// An empty struct value does not necessarily mean the token is unowned.
		// See `_packedOwnershipOf` implementation for details.
		//
		// Bits Layout:
		// - [0..159]   `addr`
		// - [160..223] `startTimestamp`
		// - [224]      `burned`
		// - [225]      `nextInitialized`
		// - [232..255] `extraData`
		mapping(uint256 => uint256) packedOwnerships;

		// Mapping owner address to address data.
		//
		// Bits Layout:
		// - [0..63]    `balance`
		// - [64..127]  `numberMinted`
		// - [128..191] `numberBurned`
		// - [192..255] `aux`
		mapping(address => uint256) packedAddressData;

		// Mapping from token ID to approved address.
		mapping(uint256 => address) tokenApprovals;

		// Mapping from owner to operator approvals
		mapping(address => mapping(address => bool)) operatorApprovals;

		// =============================================================================
		// Artwork
		// =============================================================================

		// attributeTypeId => attributeType
		mapping(uint8 => AttributeType) attributeTypes;

		// tokenId => (attributeTypeId => Bitfield of attribute available)
		mapping(
			uint256 => mapping(
				uint8 => uint256
			)
		) attributesAvailable;

		// tokenId => (attributeTypeId => attributeId active)
		mapping(
			uint256 => mapping(
				uint8 => uint8
			)
		) attributesActive;
		
		// =============================================================================
		// Metadata
		// =============================================================================
		string tokenBaseExternalUrl;
		string contractLevelImageUrl;
		string contractLevelExternalUrl;
		bool wlMinting;

		// =============================================================================
		// Royalty
		// =============================================================================
		address royaltyWalletAddress;
		uint96 royaltyBasisPoints;
	}

	bytes32 constant APP_STORAGE_POSITION = keccak256("diamond.standard.the.saudis.storage");

	function getState() internal pure returns (State storage s) {
		bytes32 position = APP_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}