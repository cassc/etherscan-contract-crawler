// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library AppStorage {
	struct State {
		// =============================================================================
		// ERC721A
		// =============================================================================

		// The tokenId of the next token to be minted
		uint256 currentIndex;

		// The number of tokens burned
		uint256 burnCounter;

		// Max supply of tokens
		uint256 maxSupply;

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
		// Minting
		// =============================================================================

		uint256 mintPrice;
		
		// =============================================================================
		// Metadata
		// =============================================================================

        string baseURI;

		// =============================================================================
		// Pausing
		// =============================================================================

		mapping(uint256 => bool) pauseTransfer;
    	bool pauseAllTransfers;

		// =============================================================================
		// Subscription
		// =============================================================================

		mapping(uint256 => uint256) subscriptionDeadline;
    	uint256 renewSubscriptionPrice;
		uint256 afterMintSubscription;

		// =============================================================================
		// For signing
		// =============================================================================

		address publicKey;
		mapping(uint256 => uint256) nonce;
		mapping(address => uint256) mintNonce;

	}

	bytes32 constant APP_STORAGE_POSITION = keccak256("diamond.standard.the.ternPlus.storage");

	function getState() internal pure returns (State storage s) {
		bytes32 position = APP_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}