// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
 * @title Foxtrot Command Cards Collections
 * @author Michael Araque
 * @notice Implementation of the Foxtrot Command Cards Collections
 */
contract FoxtrotCommandCards is
	Initializable,
	ERC1155Upgradeable,
	AccessControlUpgradeable,
	ERC1155BurnableUpgradeable,
	ERC1155SupplyUpgradeable
{
	bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant SOULBOUND_LISTER_ROLE = keccak256("SOULBOUND_LISTER_ROLE");

	mapping(uint256 => bool) public souldboundTokens;
	mapping(uint256 => string) private _tokenURIs;

	string private _name;
	string private _symbol;
	string public baseURI;

	event TokensAddedToSoulboundList(uint256[] indexed ids);
	event TokensRemovedFromSoulboundList(uint256[] indexed ids);

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	function initialize() public initializer {
		__ERC1155_init("");
		__AccessControl_init();
		__ERC1155Burnable_init();
		__ERC1155Supply_init();

		_name = "Foxtrot Command Cards";
		_symbol = "FCCard";

		_grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_grantRole(URI_SETTER_ROLE, _msgSender());
		_grantRole(MINTER_ROLE, _msgSender());
		_grantRole(SOULBOUND_LISTER_ROLE, _msgSender());
	}

	/**
	 * @dev Returns the name of the contract.
	 * @return string The name of the contract.
	 */
	function name() public view virtual returns (string memory) {
		return _name;
	}

	// Returns the symbol of the token, usually a shorter version of the name.
	function symbol() public view virtual returns (string memory) {
		return _symbol;
	}

	/**
	 * @notice Set the URI for all tokens of `name`, by relying on the token name
	 * @param _baseURI New URI for all tokens
	 */
	function setBaseUri(string memory _baseURI) public onlyRole(URI_SETTER_ROLE) {
		baseURI = _baseURI;
	}

	/**
	 * @notice Set the URI for a specific token
	 * @param tokenId The id of the token
	 * @param tokenURI The URI of the token
	 */
	function setTokenUri(uint256 tokenId, string memory tokenURI) public onlyRole(URI_SETTER_ROLE) {
		_tokenURIs[tokenId] = tokenURI;
		
		emit URI(tokenURI, tokenId);
	}

	/**
	 * @notice get the URI of a token
	 * @param tokenId the id of the token
	 * @return string URI of the token
	 */
	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_tokenURIs[tokenId], Strings.toString(tokenId), ".json"));
	}

	/**
	 * @dev Add a list of tokens to the soulbound list
	 * @param tokenIds The list of token ids
	 */
	function addTokenToSoulboundList(uint256[] memory tokenIds) public {
		require(hasRole(SOULBOUND_LISTER_ROLE, _msgSender()), "FCC: Only Soulbound Lister Role");

		for (uint i; i < tokenIds.length; i++) {
			souldboundTokens[tokenIds[i]] = true;
		}

		emit TokensAddedToSoulboundList(tokenIds);
	}

	/**
	 * @dev Removes tokens from the Soulbound List
	 * @param tokenIds The tokenIds of the tokens to remove
	 */
	function removeTokenFromSoulboundList(uint256[] memory tokenIds) public {
		require(hasRole(SOULBOUND_LISTER_ROLE, _msgSender()), "FCC: Only Soulbound Lister Role");

		for (uint i; i < tokenIds.length; i++) {
			souldboundTokens[tokenIds[i]] = false;
		}
		emit TokensRemovedFromSoulboundList(tokenIds);
	}

	/**
	 * @dev Checks if a token is soulbound locked
	 * @param tokenId The tokenId of the token
	 * @return bool True if the token is soulbound
	 */
	function isSoulboundToken(uint256 tokenId) public view returns (bool) {
		return souldboundTokens[tokenId];
	}

	/**
	 * @notice Mints `amount` of token of token type `id`
	 * @dev See {IERC1155-_mint}.
	 *
	 * Requirements:
	 *
	 * - the caller must have the `MINTER_ROLE`.
	 *
	 * Emits a {TransferSingle} event.
	 */
	function mint(
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public onlyRole(MINTER_ROLE) {
		_mint(to, id, amount, data);
	}

	/**
	 * @notice Mints `amounts` of tokens of token types `ids`
	 * @dev See {IERC1155-_mintBatch}.
	 *
	 * Requirements:
	 *
	 * - the caller must have the `MINTER_ROLE`.
	 *
	 * Emits a {TransferBatch} event.
	 */
	function mintBatch(
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public onlyRole(MINTER_ROLE) {
		_mintBatch(to, ids, amounts, data);
	}

	// The following functions are overrides required by Solidity.

	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
		if (to != address(0)) {
			for (uint i = 0; i < ids.length; i++) {
				if (!hasRole(MINTER_ROLE, _msgSender())) {
					require(souldboundTokens[ids[i]] == false, "FCC: Intrasferable");
				}
			}
		}

		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
	}

	function supportsInterface(
		bytes4 interfaceId
	) public view override(ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}