// SPDX-License-Identifier: Apache-2.0

/// @title ERC1155TL.sol
/// @notice Transient Labs ERC-1155 Creator Contract
/// @dev features include
///      - batch minting
///      - airdrops
///      - ability to hook in external mint contracts
///      - ability to set multiple admins
///      - Story Contract
///      - BlockList
///      - individual token royalties
/// @author transientlabs.xyz

/*
    ____        _ __    __   ____  _ ________                     __ 
   / __ )__  __(_) /___/ /  / __ \(_) __/ __/__  ________  ____  / /_
  / __  / / / / / / __  /  / / / / / /_/ /_/ _ \/ ___/ _ \/ __ \/ __/
 / /_/ / /_/ / / / /_/ /  / /_/ / / __/ __/  __/ /  /  __/ / / / /__ 
/_____/\__,_/_/_/\__,_/  /_____/_/_/ /_/  \___/_/   \___/_/ /_/\__(_)*/

pragma solidity 0.8.17;

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {
    ERC1155Upgradeable,
    IERC1155Upgradeable,
    ERC165Upgradeable
} from "openzeppelin-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {EIP2981TLUpgradeable} from "tl-sol-tools/upgradeable/royalties/EIP2981TLUpgradeable.sol";
import {OwnableAccessControlUpgradeable} from "tl-sol-tools/upgradeable/access/OwnableAccessControlUpgradeable.sol";
import {StoryContractUpgradeable} from "tl-story/upgradeable/StoryContractUpgradeable.sol";
import {BlockListUpgradeable} from "tl-blocklist/BlockListUpgradeable.sol";

/*//////////////////////////////////////////////////////////////////////////
                            Custom Errors
//////////////////////////////////////////////////////////////////////////*/

/// @dev token uri is an empty string
error EmptyTokenURI();

/// @dev batch size too small
error BatchSizeTooSmall();

/// @dev mint to zero addresses
error MintToZeroAddresses();

/// @dev array length mismatch
error ArrayLengthMismatch();

/// @dev token not owned by the owner of the contract
error TokenNotOwnedByOwner();

/// @dev caller is not approved or owner
error CallerNotApprovedOrOwner();

/// @dev token does not exist
error TokenDoesntExist();

/// @dev burning zero tokens
error BurnZeroTokens();

/*//////////////////////////////////////////////////////////////////////////
                            ERC1155TL
//////////////////////////////////////////////////////////////////////////*/

contract ERC1155TL is
    ERC1155Upgradeable,
    EIP2981TLUpgradeable,
    OwnableAccessControlUpgradeable,
    StoryContractUpgradeable,
    BlockListUpgradeable
{
    /*//////////////////////////////////////////////////////////////////////////
                                Custom Types
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev struct defining a token
    struct Token {
        bool created;
        string uri;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant VERSION = 1;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant APPROVED_MINT_CONTRACT = keccak256("APPROVED_MINT_CONTRACT");
    uint256 private _counter;
    string public name;
    string public symbol;
    mapping(uint256 => Token) private _tokens;

    /*//////////////////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////////////////*/

    /// @param disable: boolean to disable initialization for the implementation contract
    constructor(bool disable) {
        if (disable) _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @param name_: the name of the 1155 contract
    /// @param symbol_: the symbol for the 1155 contract
    /// @param defaultRoyaltyRecipient: the default address for royalty payments
    /// @param defaultRoyaltyPercentage: the default royalty percentage of basis points (out of 10,000)
    /// @param initOwner: the owner of the contract
    /// @param admins: array of admin addresses to add to the contract
    /// @param enableStory: a bool deciding whether to add story fuctionality or not
    /// @param blockListRegistry: address of the blocklist registry to use
    function initialize(
        string memory name_,
        string memory symbol_,
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address initOwner,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    ) external initializer {
        // initialize parent contracts
        __ERC1155_init("");
        __EIP2981TL_init(defaultRoyaltyRecipient, defaultRoyaltyPercentage);
        __OwnableAccessControl_init(initOwner);
        __StoryContractUpgradeable_init(enableStory);
        __BlockList_init(blockListRegistry);

        // add admins
        _setRole(ADMIN_ROLE, admins, true);

        // set name & symbol
        name = name_;
        symbol = symbol_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                General Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to get token creation details
    /// @param tokenId: the token to lookup
    function getTokenDetails(uint256 tokenId) external view returns (Token memory) {
        return _tokens[tokenId];
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Access Control Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to set approved mint contracts
    /// @dev access to owner or admin
    /// @param minters: array of minters to grant approval to
    /// @param status: status for the minters
    function setApprovedMintContracts(address[] calldata minters, bool status) external onlyRoleOrOwner(ADMIN_ROLE) {
        _setRole(APPROVED_MINT_CONTRACT, minters, status);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Creation Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to create a token that can be minted to creator or airdropped
    /// @dev requires owner or admin
    /// @param newUri: the uri for the token to create
    /// @param addresses: the addresses to mint the new token to
    /// @param amounts: the amount of the new token to mint to each address
    function createToken(string calldata newUri, address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyRoleOrOwner(ADMIN_ROLE)
    {
        _createToken(newUri, addresses, amounts);
    }

    /// @notice function to create a token that can be minted to creator or airdropped
    /// @dev overloaded function where you can set the token royalty config in this tx
    /// @dev requires owner or admin
    /// @param newUri: the uri for the token to create
    /// @param addresses: the addresses to mint the new token to
    /// @param amounts: the amount of the new token to mint to each address
    /// @param royaltyAddress: royalty payout address for the created token
    /// @param royaltyPercent: royalty percentage for this token
    function createToken(string calldata newUri, address[] calldata addresses, uint256[] calldata amounts, address royaltyAddress, uint256 royaltyPercent)
        external
        onlyRoleOrOwner(ADMIN_ROLE)
    {
       uint256 tokenId =  _createToken(newUri, addresses, amounts);
       _overrideTokenRoyaltyInfo(tokenId, royaltyAddress, royaltyPercent);
    }

    /// @notice function to batch create tokens that can be minted to creator or airdropped
    /// @dev requires owner or admin
    /// @param newUris: the uris for the tokens to create
    /// @param addresses: 2d dynamic array holding the addresses to mint the new tokens to
    /// @param amounts: 2d dynamic array holding the amounts of the new tokens to mint to each address
    function batchCreateToken(string[] calldata newUris, address[][] calldata addresses, uint256[][] calldata amounts)
        external
        onlyRoleOrOwner(ADMIN_ROLE)
    {
        if (newUris.length == 0) revert EmptyTokenURI();
        for (uint256 i = 0; i < newUris.length; i++) {
            _createToken(newUris[i], addresses[i], amounts[i]);
        }
    }

    /// @notice function to batch create tokens that can be minted to creator or airdropped
    /// @dev overloaded function where you can set the token royalty config in this tx
    /// @dev requires owner or admin
    /// @param newUris: the uris for the tokens to create
    /// @param addresses: 2d dynamic array holding the addresses to mint the new tokens to
    /// @param amounts: 2d dynamic array holding the amounts of the new tokens to mint to each address
    /// @param royaltyAddresses: royalty payout addresses for the tokens
    /// @param royaltyPercents: royalty payout percents for the tokens
    function batchCreateToken(string[] calldata newUris, address[][] calldata addresses, uint256[][] calldata amounts, address[] calldata royaltyAddresses, uint256[] calldata royaltyPercents)
        external
        onlyRoleOrOwner(ADMIN_ROLE)
    {
        if (newUris.length == 0) revert EmptyTokenURI();
        for (uint256 i = 0; i < newUris.length; i++) {
            uint256 tokenId = _createToken(newUris[i], addresses[i], amounts[i]);
            _overrideTokenRoyaltyInfo(tokenId, royaltyAddresses[i], royaltyPercents[i]);
        }
    }

    /// @notice private helper function to create a new token
    /// @param newUri: the uri for the token to create
    /// @param addresses: the addresses to mint the new token to
    /// @param amounts: the amount of the new token to mint to each address
    /// @return _counter: token id created
    function _createToken(string memory newUri, address[] memory addresses, uint256[] memory amounts) private returns(uint256) {
        if (bytes(newUri).length == 0) revert EmptyTokenURI();
        if (addresses.length == 0) revert MintToZeroAddresses();
        if (addresses.length != amounts.length) revert ArrayLengthMismatch();
        _counter++;
        _tokens[_counter] = Token(true, newUri);
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], _counter, amounts[i], "");
        }

        return _counter;
    }

    /// @notice private helper function to verify a token exists
    /// @param tokenId: the token to check existence for
    function _exists(uint256 tokenId) private view returns (bool) {
        return _tokens[tokenId].created;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Mint Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to mint existing token to recipients
    /// @dev requires owner or admin
    /// @param tokenId: the token to mint
    /// @param addresses: the addresses to mint to
    /// @param amounts: amounts of the token to mint to each address
    function mintToken(uint256 tokenId, address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyRoleOrOwner(ADMIN_ROLE)
    {
        _mintToken(tokenId, addresses, amounts);
    }

    /// @notice external mint function
    /// @dev requires caller to be an approved mint contract
    /// @param tokenId: the token to mint
    /// @param addresses: the addresses to mint to
    /// @param amounts: amounts of the token to mint to each address
    function externalMint(uint256 tokenId, address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyRole(APPROVED_MINT_CONTRACT)
    {
        _mintToken(tokenId, addresses, amounts);
    }

    /// @notice private helper function
    /// @param tokenId: the token to mint
    /// @param addresses: the addresses to mint to
    /// @param amounts: amounts of the token to mint to each address
    function _mintToken(uint256 tokenId, address[] calldata addresses, uint256[] calldata amounts) private {
        if (!_exists(tokenId)) revert TokenDoesntExist();
        if (addresses.length == 0) revert MintToZeroAddresses();
        if (addresses.length != amounts.length) revert ArrayLengthMismatch();
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], tokenId, amounts[i], "");
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Burn Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to burn tokens from an account
    /// @dev msg.sender must be owner or operator
    /// @dev if this function is called from another contract as part of a burn/redeem,
    ///      the contract must ensure that no amount is '0' or if it is, that it isn't a vulnerability.
    /// @param from: address to burn from
    /// @param tokenIds: array of tokens to burn
    /// @param amounts: amount of each token to burn
    function burn(address from, uint256[] calldata tokenIds, uint256[] calldata amounts) external {
        if (tokenIds.length == 0) revert BurnZeroTokens();
        if (msg.sender != from && !isApprovedForAll(from, msg.sender)) revert CallerNotApprovedOrOwner();
        _burnBatch(from, tokenIds, amounts);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Royalty Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to set the default royalty specification
    /// @dev requires owner
    /// @param newRecipient: the new royalty payout address
    /// @param newPercentage: the new royalty percentage in basis (out of 10,000)
    function setDefaultRoyalty(address newRecipient, uint256 newPercentage) external onlyOwner {
        _setDefaultRoyaltyInfo(newRecipient, newPercentage);
    }

    /// @notice function to override a token's royalty info
    /// @dev requires owner
    /// @param tokenId: the token to override royalty for
    /// @param newRecipient: the new royalty payout address for the token id
    /// @param newPercentage: the new royalty percentage in basis (out of 10,000) for the token id
    function setTokenRoyalty(uint256 tokenId, address newRecipient, uint256 newPercentage) external onlyOwner {
        _overrideTokenRoyaltyInfo(tokenId, newRecipient, newPercentage);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Token Uri Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to set token Uri for a token
    /// @dev requires owner or admin
    /// @param tokenId: token to set a uri for
    /// @param newUri: the new uri for the token
    function setTokenUri(uint256 tokenId, string calldata newUri) external onlyRoleOrOwner(ADMIN_ROLE) {
        if (!_exists(tokenId)) revert TokenDoesntExist();
        if (bytes(newUri).length == 0) revert EmptyTokenURI();
        _tokens[tokenId].uri = newUri;
        emit IERC1155Upgradeable.URI(newUri, tokenId);
    }

    /// @notice function for token uris
    /// @param tokenId: token for which to get the uri
    function uri(uint256 tokenId) public view override(ERC1155Upgradeable) returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesntExist();
        return _tokens[tokenId].uri;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Story Contract Hooks
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc StoryContractUpgradeable
    /// @dev restricted to the owner of the contract
    function _isStoryAdmin(address potentialAdmin) internal view override(StoryContractUpgradeable) returns (bool) {
        return potentialAdmin == owner();
    }

    /// @inheritdoc StoryContractUpgradeable
    function _tokenExists(uint256 tokenId) internal view override(StoryContractUpgradeable) returns (bool) {
        return _exists(tokenId);
    }

    /// @inheritdoc StoryContractUpgradeable
    function _isTokenOwner(address potentialOwner, uint256 tokenId)
        internal
        view
        override(StoryContractUpgradeable)
        returns (bool)
    {
        return balanceOf(potentialOwner, tokenId) > 0;
    }

    /// @inheritdoc StoryContractUpgradeable
    /// @dev restricted to the owner of the contract
    function _isCreator(address potentialCreator, uint256 /* tokenId */ )
        internal
        view
        override(StoryContractUpgradeable)
        returns (bool)
    {
        return potentialCreator == owner();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                BlockList Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc BlockListUpgradeable
    /// @dev restricted to the owner of the contract
    function isBlockListAdmin(address potentialAdmin) public view override(BlockListUpgradeable) returns (bool) {
        return potentialAdmin == owner();
    }

    /// @inheritdoc ERC1155Upgradeable
    /// @dev added the `notBlocked` modifier for blocklist
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC1155Upgradeable)
        notBlocked(operator)
    {
        ERC1155Upgradeable.setApprovalForAll(operator, approved);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ERC-165 Support
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, EIP2981TLUpgradeable, StoryContractUpgradeable)
        returns (bool)
    {
        return (
            ERC1155Upgradeable.supportsInterface(interfaceId) || EIP2981TLUpgradeable.supportsInterface(interfaceId)
                || StoryContractUpgradeable.supportsInterface(interfaceId)
        );
    }
}