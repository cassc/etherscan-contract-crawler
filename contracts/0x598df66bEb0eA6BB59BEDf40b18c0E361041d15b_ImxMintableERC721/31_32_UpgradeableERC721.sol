// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ERC20Spec.sol";
import "../interfaces/ERC721SpecExt.sol";
import "../lib/SafeERC20.sol";
import "../utils/UpgradeableAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

/**
 * @title Upgradeable ERC721 Implementation
 *
 * @notice Zeppelin based ERC721 implementation, supporting token enumeration
 *      (ERC721EnumerableUpgradeable) and flexible token URI management (ERC721URIStorageUpgradeable)
 *
 * // TODO: consider allowing to override each individual token URI
 *
 * @dev Based on Zeppelin ERC721EnumerableUpgradeable and ERC721URIStorageUpgradeable with some modifications
 *      to tokenURI function
 *
 * @author Basil Gorin
 */
abstract contract UpgradeableERC721 is MintableERC721, BurnableERC721, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, UpgradeableAccessControl {
	// using ERC20.transfer wrapper from OpenZeppelin adopted SafeERC20
	using SafeERC20 for ERC20;

	/**
	 * @dev Base URI is used to construct ERC721Metadata.tokenURI as
	 *      `base URI + token ID` if token URI is not set (not present in `_tokenURIs` mapping)
	 *
	 * @dev For example, if base URI is https://api.com/token/, then token #1
	 *      will have an URI https://api.com/token/1
	 *
	 * @dev If token URI is set with `setTokenURI()` it will be returned as is via `tokenURI()`
	 */
	string public baseURI;

	/**
	 * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
	 *      the amount of storage used by a contract always adds up to the 50.
	 *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[49] private __gap;

	/**
	 * @notice Enables ERC721 transfers of the tokens
	 *      (transfer by the token owner himself)
	 * @dev Feature FEATURE_TRANSFERS must be enabled in order for
	 *      `transferFrom()` function to succeed when executed by token owner
	 */
	uint32 public constant FEATURE_TRANSFERS = 0x0000_0001;

	/**
	 * @notice Enables ERC721 transfers on behalf
	 *      (transfer by someone else on behalf of token owner)
	 * @dev Feature FEATURE_TRANSFERS_ON_BEHALF must be enabled in order for
	 *      `transferFrom()` function to succeed whe executed by approved operator
	 * @dev Token owner must call `approve()` or `setApprovalForAll()`
	 *      first to authorize the transfer on behalf
	 */
	uint32 public constant FEATURE_TRANSFERS_ON_BEHALF = 0x0000_0002;

	/**
	 * @notice Enables token owners to burn their own tokens
	 *
	 * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
	 *      `burn()` function to succeed when called by token owner
	 */
	uint32 public constant FEATURE_OWN_BURNS = 0x0000_0008;

	/**
	 * @notice Enables approved operators to burn tokens on behalf of their owners
	 *
	 * @dev Feature FEATURE_BURNS_ON_BEHALF must be enabled in order for
	 *      `burn()` function to succeed when called by approved operator
	 */
	uint32 public constant FEATURE_BURNS_ON_BEHALF = 0x0000_0010;

	/**
	 * @notice Token creator is responsible for creating (minting)
	 *      tokens to an arbitrary address
	 * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
	 *      (calling `mint` function)
	 */
	uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

	/**
	 * @notice Token destroyer is responsible for destroying (burning)
	 *      tokens owned by an arbitrary address
	 * @dev Role ROLE_TOKEN_DESTROYER allows burning tokens
	 *      (calling `burn` function)
	 */
	uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

	/**
	 * @notice URI manager is responsible for managing base URI
	 *      part of the token URI ERC721Metadata interface
	 *
	 * @dev Role ROLE_URI_MANAGER allows updating the base URI
	 *      (executing `setBaseURI` function)
	 */
	uint32 public constant ROLE_URI_MANAGER = 0x0004_0000;

	/**
	 * @notice People do mistakes and may send ERC20 tokens by mistake; since
	 *      NFT smart contract is not designed to accept and hold any ERC20 tokens,
	 *      it allows the rescue manager to "rescue" such lost tokens
	 *
	 * @notice Rescue manager is responsible for "rescuing" ERC20 tokens accidentally
	 *      sent to the smart contract
	 *
	 * @dev Role ROLE_RESCUE_MANAGER allows withdrawing any ERC20 tokens stored
	 *      on the smart contract balance
	 */
	uint32 public constant ROLE_RESCUE_MANAGER = 0x0008_0000;

	/**
	 * @dev Fired in _mint() and all the dependent functions like mint(), safeMint()
	 *
	 * @param _by an address which executed update
	 * @param _to an address token was minted to
	 * @param _tokenId token ID minted
	 */
	event Minted(address indexed _by, address indexed _to, uint256 indexed _tokenId);

	/**
	 * @dev Fired in _burn() and all the dependent functions like burn()
	 *
	 * @param _by an address which executed update
	 * @param _from an address token was burnt from
	 * @param _tokenId token ID burnt
	 */
	event Burnt(address indexed _by, address indexed _from, uint256 indexed _tokenId);

	/**
	 * @dev Fired in setBaseURI()
	 *
	 * @param _by an address which executed update
	 * @param oldVal old _baseURI value
	 * @param newVal new _baseURI value
	 */
	event BaseURIUpdated(address indexed _by, string oldVal, string newVal);

	/**
	 * @dev Fired in setTokenURI()
	 *
	 * @param _by an address which executed update
	 * @param tokenId token ID which URI was updated
	 * @param oldVal old _baseURI value
	 * @param newVal new _baseURI value
	 */
	event TokenURIUpdated(address indexed _by, uint256 tokenId, string oldVal, string newVal);

	/**
	 * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
	 *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 *
	 * @param _name token name (ERC721Metadata)
	 * @param _symbol token symbol (ERC721Metadata)
	 * @param _owner smart contract owner having full privileges
	 */
	function _postConstruct(string memory _name, string memory _symbol, address _owner) internal virtual initializer {
		// execute all parent initializers in cascade
		__ERC721_init(_name, _symbol);
		__ERC721Enumerable_init_unchained();
		__ERC721URIStorage_init_unchained();
		UpgradeableAccessControl._postConstruct(_owner);
	}

	/**
	 * @inheritdoc IERC165Upgradeable
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
		// calculate based on own and inherited interfaces
		return ERC721EnumerableUpgradeable.supportsInterface(interfaceId)
			|| interfaceId == type(MintableERC721).interfaceId
			|| interfaceId == type(BurnableERC721).interfaceId;
	}

	/**
	 * @dev Restricted access function which updates base URI used to construct
	 *      ERC721Metadata.tokenURI
	 *
	 * @dev Requires executor to have ROLE_URI_MANAGER permission
	 *
	 * @param __baseURI new base URI to set
	 */
	function setBaseURI(string memory __baseURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit BaseURIUpdated(msg.sender, baseURI, __baseURI);

		// and update base URI
		baseURI = __baseURI;
	}

	/**
	 * @inheritdoc ERC721Upgradeable
	 */
	function _baseURI() internal view virtual override returns (string memory) {
		// just return stored public value to support Zeppelin impl
		return baseURI;
	}

	/**
	 * @dev Sets the token URI for the token defined by its ID
	 *
	 * @param _tokenId an ID of the token to set URI for
	 * @param _tokenURI token URI to set
	 */
	function setTokenURI(uint256 _tokenId, string memory _tokenURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// we do not verify token existence: we want to be able to
		// preallocate token URIs before tokens are actually minted

		// emit an event first - to log both old and new values
		emit TokenURIUpdated(msg.sender, _tokenId, "zeppelin", _tokenURI);

		// and update token URI - delegate to ERC721URIStorage
		_setTokenURI(_tokenId, _tokenURI);
	}

	/**
	 * @inheritdoc ERC721URIStorageUpgradeable
	 */
	function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual override {
		// delegate to ERC721URIStorage impl
		return super._setTokenURI(_tokenId, _tokenURI);
	}

	/**
	 * @inheritdoc ERC721Upgradeable
	 */
	function tokenURI(uint256 _tokenId) public view virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
		// delegate to ERC721URIStorage impl
		return ERC721URIStorageUpgradeable.tokenURI(_tokenId);
	}

	/**
	 * @notice Checks if specified token exists
	 *
	 * @dev Returns whether the specified token ID has an ownership
	 *      information associated with it
	 * @param _tokenId ID of the token to query existence for
	 * @return whether the token exists (true - exists, false - doesn't exist)
	 */
	function exists(uint256 _tokenId) public view virtual override returns (bool) {
		// delegate to super implementation
		return _exists(_tokenId);
	}

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMint` instead of `mint`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function mint(address _to, uint256 _tokenId) public virtual override {
		// mint token - delegate to `_mint`
		_mint(_to, _tokenId);
	}

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMint(address _to, uint256 _tokenId, bytes memory _data) public virtual override {
		// mint token safely - delegate to `_safeMint`
		_safeMint(_to, _tokenId, _data);
	}

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function safeMint(address _to, uint256 _tokenId) public virtual override {
		// mint token safely - delegate to `_safeMint`
		_safeMint(_to, _tokenId);
	}

	/**
	 * @dev Destroys the token with token ID specified
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_DESTROYER` permission
	 *      or FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features to be enabled
	 *
	 * @dev Can be disabled by the contract creator forever by disabling
	 *      FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features and then revoking
	 *      its own roles to burn tokens and to enable burning features
	 *
	 * @param _tokenId ID of the token to burn
	 */
	function burn(uint256 _tokenId) public virtual override {
		// burn token - delegate to `_burn`
		_burn(_tokenId);
	}

	/**
	 * @inheritdoc ERC721Upgradeable
	 */
	function _mint(address _to, uint256 _tokenId) internal virtual override {
		// check if caller has sufficient permissions to mint tokens
		require(isSenderInRole(ROLE_TOKEN_CREATOR), "access denied");

		// delegate to super implementation
		super._mint(_to, _tokenId);

		// emit an additional event to better track who performed the operation
		emit Minted(msg.sender, _to, _tokenId);
	}

	/**
	 * @inheritdoc ERC721Upgradeable
	 */
	function _burn(uint256 _tokenId) internal virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
		// read token owner data
		// verifies token exists under the hood
		address _from = ownerOf(_tokenId);

		// check if caller has sufficient permissions to burn tokens
		// and if not - check for possibility to burn own tokens or to burn on behalf
		if(!isSenderInRole(ROLE_TOKEN_DESTROYER)) {
			// if `_from` is equal to sender, require own burns feature to be enabled
			// otherwise require burns on behalf feature to be enabled
			require(_from == msg.sender && isFeatureEnabled(FEATURE_OWN_BURNS)
			     || _from != msg.sender && isFeatureEnabled(FEATURE_BURNS_ON_BEHALF),
			        _from == msg.sender? "burns are disabled": "burns on behalf are disabled");

			// verify sender is either token owner, or approved by the token owner to burn tokens
			require(msg.sender == _from
			     || msg.sender == getApproved(_tokenId)
			     || isApprovedForAll(_from, msg.sender), "access denied");
		}

		// delegate to the super implementation with URI burning
		ERC721URIStorageUpgradeable._burn(_tokenId);

		// emit an additional event to better track who performed the operation
		emit Burnt(msg.sender, _from, _tokenId);
	}

	/**
	 * @inheritdoc ERC721Upgradeable
	 */
	function _beforeTokenTransfer(
		address _from,
		address _to,
		uint256 _tokenId,
		uint256 _batchSize
	) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
		// for transfers only - verify if transfers are enabled
		require(_from == address(0) || _to == address(0) // won't affect minting/burning
		     || _from == msg.sender && isFeatureEnabled(FEATURE_TRANSFERS)
		     || _from != msg.sender && isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF),
		        _from == msg.sender? "transfers are disabled": "transfers on behalf are disabled");

		// delegate to ERC721Enumerable impl
		ERC721EnumerableUpgradeable._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);
	}

	/**
	 * @dev Restricted access function to rescue accidentally sent ERC20 tokens,
	 *      the tokens are rescued via `transfer` function call on the
	 *      contract address specified and with the parameters specified:
	 *      `_contract.transfer(_to, _value)`
	 *
	 * @dev Requires executor to have `ROLE_RESCUE_MANAGER` permission
	 *
	 * @param _contract smart contract address to execute `transfer` function on
	 * @param _to to address in `transfer(_to, _value)`
	 * @param _value value to transfer in `transfer(_to, _value)`
	 */
	function rescueErc20(address _contract, address _to, uint256 _value) public {
		// verify the access permission
		require(isSenderInRole(ROLE_RESCUE_MANAGER), "access denied");

		// perform the transfer as requested, without any checks
		ERC20(_contract).safeTransfer(_to, _value);
	}
}