// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155, ERC1155URIStorage} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {WithOperatorFilter} from "./utils/WithOperatorFilter/WithOperatorFilter.sol";

import {ICyberbrokersAccolades} from "./ICyberbrokersAccolades.sol";

/// @title CyberbrokersAccolades
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Recognition tokens for the CyberBrokers community
contract CyberbrokersAccolades is ICyberbrokersAccolades, Ownable, ERC1155URIStorage, WithOperatorFilter, ERC2981 {
	error NotAuthorized();
	error InvalidLength();

	string public name = "CyberBrokers Accolades";
	string public symbol = "CB-ACCOLADES";

	/// @notice the contract uri
	string public contractURI;

	/// @notice address allowed to mint
	/// @dev using the minter patterns allows to later create contracts with more minting schemes
	mapping(address => bool) public minters;

	modifier onlyMinter() {
		if (msg.sender != owner() && !minters[msg.sender]) {
			revert NotAuthorized();
		}
		_;
	}

	constructor(
		string memory newContractURI,
		address feeRecipient,
		uint96 feeNumerator
	) ERC1155("") {
		contractURI = newContractURI;
		_setDefaultRoyalty(feeRecipient, feeNumerator);
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	////////////////////////////////////////////////////////////
	// Gated Minter                                           //
	////////////////////////////////////////////////////////////

	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, id, amount, data);
	}

	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual override onlyAllowedOperator(from) {
		super.safeBatchTransferFrom(from, to, ids, amounts, data);
	}

	function setApprovalForAll(address operator, bool _approved)
		public
		override
		onlyAllowedOperatorForApproval(operator, _approved)
	{
		super.setApprovalForAll(operator, _approved);
	}

	////////////////////////////////////////////////////////////
	// Gated Minter                                           //
	////////////////////////////////////////////////////////////

	/// @notice Allows minter to mint `amount` token of `tokenId` to each `addresses[index]`
	/// @param addresses the addresses to mint to
	/// @param tokenId the token id to mint
	/// @param amount the amount to mint
	function mint(
		address[] calldata addresses,
		uint256 tokenId,
		uint256 amount
	) external override onlyMinter {
		uint256 length = addresses.length;
		if (length == 0) {
			revert InvalidLength();
		}

		do {
			unchecked {
				length--;
			}
			_mint(addresses[length], tokenId, amount, "");
		} while (length > 0);
	}

	/// @notice Allows minter to mint `amounts[index]` tokens of `tokenIds[index]` to `addresses[index]`
	/// @param addresses the addresses to mint to
	/// @param tokenIds the token ids to mint
	/// @param amounts the amount for each token ids to mint
	function mintBatch(
		address[] calldata addresses,
		uint256[] calldata tokenIds,
		uint256[] calldata amounts
	) external override onlyMinter {
		uint256 length = addresses.length;
		if (length == 0 || length != tokenIds.length || length != amounts.length) {
			revert InvalidLength();
		}

		do {
			unchecked {
				length--;
			}
			_mint(addresses[length], tokenIds[length], amounts[length], "");
		} while (length > 0);
	}

	/// @notice Allows minter to set the URI for `tokenId`
	/// @param tokenId the token id to set the uri for
	/// @param newURI the new URI
	function setURI(uint256 tokenId, string calldata newURI) external onlyMinter {
		_setURI(tokenId, newURI);
	}

	/// @notice Allows minter to set the URIs for each tokenIds
	/// @param tokenIds the token ids to set the uri for
	/// @param uris the uris for each token id
	function setURIBatch(uint256[] calldata tokenIds, string[] calldata uris) external onlyMinter {
		uint256 length = tokenIds.length;
		if (length == 0 || length != uris.length) {
			revert InvalidLength();
		}

		do {
			unchecked {
				length--;
			}
			_setURI(tokenIds[length], uris[length]);
		} while (length > 0);
	}

	////////////////////////////////////////////////////////////
	// Gated Owner                                            //
	////////////////////////////////////////////////////////////

	/// @notice Allows owner to add/remove minters
	/// @param targets the new minter address
	/// @param isMinter if we add or remove the addresses
	function setMinter(address[] calldata targets, bool isMinter) external onlyOwner {
		uint256 length = targets.length;
		if (length == 0) {
			revert InvalidLength();
		}

		do {
			unchecked {
				length--;
			}
			minters[targets[length]] = isMinter;
		} while (length > 0);
	}

	/// @notice Allows owner to set the contract URI
	/// @param newContractURI the new contract uri
	function setContractURI(string calldata newContractURI) external onlyOwner {
		contractURI = newContractURI;
	}

	/// @notice Allows owner to set the default royalties
	/// @param receiver the royalties recipient
	/// @param feeNumerator basis point percentage
	function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
		_setDefaultRoyalty(receiver, feeNumerator);
	}

	/// @notice Allows owner to switch on/off the OperatorFilter
	/// @param newIsEnabled the new state
	function setIsOperatorFilterEnabled(bool newIsEnabled) public onlyOwner {
		isOperatorFilterEnabled = newIsEnabled;
	}
}