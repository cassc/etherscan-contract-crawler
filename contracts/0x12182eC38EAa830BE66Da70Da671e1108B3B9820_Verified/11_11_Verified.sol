//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ERC721ABurnable, ERC721A, IERC721A} from "erc721a/contracts/extensions/ERC721ABurnable.sol";

import {IERC4906, IERC165} from "./IERC4906.sol";

import {IVerified} from "./IVerified.sol";

/// @title Verified
/// @author @dievardump
contract Verified is IVerified, Ownable, ERC721ABurnable, IERC4906 {
	error NotAuthorized();
	error InvalidExtraData();

	address public minter;

	address public royaltiesRecipient;

	address public metadataManager;

	string public contractURI;

	modifier onlyMinter() {
		if (msg.sender != minter) {
			revert NotAuthorized();
		}
		_;
	}

	constructor(address newRoyaltiesRecipient, string memory contractURI_)
		ERC721A(unicode"✓erified", unicode"✓ERIFIED")
	{
		royaltiesRecipient = newRoyaltiesRecipient;
		contractURI = contractURI_;
	}

	// =============================================================
	//                   				Getters
	// =============================================================

	function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC721A, IERC721A) returns (bool) {
		return
			interfaceId == this.royaltyInfo.selector ||
			interfaceId == bytes4(0x49064906) ||
			ERC721A.supportsInterface(interfaceId);
	}

	/// @notice 4.20% royalties on secondary
	function royaltyInfo(uint256 tokenId, uint256 amount) public view returns (address, uint256) {
		return (royaltiesRecipient, (amount * 420) / 10000);
	}

	/// @dev we delegate all tokenURIs to a metadataManager allowing to fix the renderings over time if needed
	/// @inheritdoc ERC721A
	function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
		// has the same
		return ERC721A(metadataManager).tokenURI(tokenId);
	}

	function extraData(uint256 tokenId) external view override returns (uint256) {
		return uint256(_exists(tokenId) ? _ownershipOf(tokenId).extraData : _ownershipAt(tokenId).extraData);
	}

	// =============================================================
	//                   Gated Mix
	// =============================================================

	/// @notice allows a token owner OR a minter to set the extra data for a token (here the format in dataHolder)
	/// @notice please make sure "format" is set in dataHolder else the token will not render
	function setExtraData(uint256 tokenId, uint24 format) external override {
		// only owner of a token, or the minter, can change the current format for the token
		if (msg.sender != ownerOf(tokenId) && msg.sender != minter) {
			revert NotAuthorized();
		}

		// because items are only minted one by one, we can be sure the data are initialized so this shouldn't fail
		_setExtraDataAt(tokenId, format);

		// notify
		emit MetadataUpdate(tokenId);
	}

	// =============================================================
	//                   Gated Minter
	// =============================================================

	/// @notice allows a minter to mint a token to `to` with `extraData`
	function mint(address to, uint24 extraData) external override onlyMinter returns (uint256) {
		// extradata is needed to be able to m
		if (extraData == 0) {
			revert InvalidExtraData();
		}

		uint256 tokenId = _nextTokenId();

		// mint
		_mint(to, 1);

		// set the index, minting one by one so every token is initialiazed
		_setExtraDataAt(tokenId, extraData);

		return tokenId;
	}

	// =============================================================
	//                       	   Owner
	// =============================================================

	/// @notice Allows owner to update metadataManager
	/// @param newMetadataManager the new address of the third eye
	/// @param emitEvent if the contract must warn indexers to refetch all data
	function setMetadataManager(address newMetadataManager, bool emitEvent) external onlyOwner {
		metadataManager = newMetadataManager;

		if (emitEvent) {
			emit BatchMetadataUpdate(_startTokenId(), _nextTokenId() - 1);
		}
	}

	/// @notice Allows owner to update contractURI
	/// @param newContractURI the new contract URI
	function setContractURI(string calldata newContractURI) external onlyOwner {
		contractURI = newContractURI;
	}

	/// @notice Allows owner to update the minter
	/// @param newMinter the new minter
	function setMinter(address newMinter) external onlyOwner {
		minter = newMinter;
	}

	/// @notice Allows owner to update the royalties recipient
	/// @param newRoyaltiesRecipient the new royalties recipient
	function setRoyaltiesRecipient(address newRoyaltiesRecipient) external onlyOwner {
		royaltiesRecipient = newRoyaltiesRecipient;
	}

	// =============================================================
	//                  			 Internals
	// =============================================================

	/**
	 * @dev Returns the starting token ID.
	 * To change the starting token ID, please override this function.
	 */
	function _startTokenId() internal view override returns (uint256) {
		return 1;
	}
}