//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDataHolder} from "./IDataHolder.sol";

/// @title VerifiedDataHolder
/// @author @dievardump
contract VerifiedDataHolder is IDataHolder, Ownable {
	error NotAuthorized();
	error UnsafeOverwrite();
	error UnknownOriginToken();
	error TokenAlreadyVerified();

	struct VerifiedData {
		uint256 verifiedId;
		// format => dataHolder
		mapping(uint256 => address) formats;
	}

	/// @notice Origin NFT data (linked verifiedId and available formats)
	/// @dev id => format => dataHolder
	/// @dev format 1 == 8x10; format 2 == 24x24; format 3 == 36x36; maybe more in the future?
	mapping(bytes32 => VerifiedData) public originTokens;

	/// @notice link verifiedId => originalNFT
	mapping(uint256 => bytes32) public verifiedToData;

	/// @notice operators having the right to write on this contract; should be the "VerifiedMinter"
	mapping(address => bool) public operators;

	modifier onlyOperator() {
		if (!operators[msg.sender]) {
			revert NotAuthorized();
		}
		_;
	}

	// =============================================================
	//                   				Getters
	// =============================================================

	/// @inheritdoc IDataHolder
	function id(address collection, uint256 tokenId) public pure returns (bytes32) {
		return keccak256(abi.encode(collection, tokenId));
	}

	/// @inheritdoc IDataHolder
	function getOriginTokenVerifiedId(address collection, uint256 tokenId) public view returns (uint256) {
		bytes32 itemId = id(collection, tokenId);
		uint256 verifiedId = originTokens[itemId].verifiedId;

		if (verifiedId == 0) {
			revert UnknownOriginToken();
		}

		return verifiedId;
	}

	/// @inheritdoc IDataHolder
	function getVerifiedFormatHolder(uint256 verifiedId, uint256 format) external view override returns (address) {
		return originTokens[verifiedToData[verifiedId]].formats[format];
	}

	// =============================================================
	//                   		Gated Operators
	// =============================================================

	/// @inheritdoc IDataHolder
	function initVerifiedTokenData(
		uint256 verifiedId,
		address collection,
		uint256 tokenId,
		uint256 format,
		address dataHolder
	) external override onlyOperator {
		// we make sure this verified id doesn't already have a linked token
		if (verifiedToData[verifiedId] != 0x0) {
			revert NotAuthorized();
		}

		bytes32 itemId = id(collection, tokenId);
		// verify we don't have any token already linked to (collection, tokenId)
		if (originTokens[itemId].verifiedId != 0) {
			revert TokenAlreadyVerified();
		}

		// we link verifiedId => origin item
		verifiedToData[verifiedId] = itemId;

		// we link origin item with verified item
		originTokens[itemId].verifiedId = verifiedId;
		originTokens[itemId].formats[format] = dataHolder;
	}

	/// @inheritdoc IDataHolder
	function safeSetData(
		address collection,
		uint256 tokenId,
		uint256 format,
		address dataHolder
	) external override onlyOperator {
		bytes32 itemId = id(collection, tokenId);

		address holder = originTokens[itemId].formats[format];

		if (holder != address(0)) {
			revert UnsafeOverwrite();
		}

		originTokens[itemId].formats[format] = dataHolder;
	}

	/// @inheritdoc IDataHolder
	function setData(
		address collection,
		uint256 tokenId,
		uint256 format,
		address dataHolder
	) external override onlyOperator {
		originTokens[id(collection, tokenId)].formats[format] = dataHolder;
	}

	// =============================================================
	//                   				Gated Owner
	// =============================================================

	/// @notice allows owner to add/remove operators
	/// @param operators_ the operators to edit
	/// @param enabled if we enable or disable those operators
	function setOperators(address[] calldata operators_, bool enabled) external onlyOwner {
		for (uint256 i; i < operators_.length; i++) {
			operators[operators_[i]] = enabled;
		}
	}
}