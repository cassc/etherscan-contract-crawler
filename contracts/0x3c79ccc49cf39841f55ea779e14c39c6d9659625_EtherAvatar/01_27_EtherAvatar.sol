// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import {ERC2981Upgradeable} from "@openzeppelin-upgradeable/contracts/token/common/ERC2981Upgradeable.sol";
import {BitMapsUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/structs/BitMapsUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";

error TokenDoesNotExist();
error NotAuthorized();
error TokenIsLocked(uint256 tokenId);

/**
 * @title EtherAvatar
 * @author cygaar <@0xCygaar>
 */
contract EtherAvatar is UUPSUpgradeable, OperatorFilterer, OwnableUpgradeable, ERC2981Upgradeable, ERC721Upgradeable {
    using Strings for uint256;

    // Address of the capsule NFT that will mint from this contract
    address public etherCapsule;

    // Whether operator filtering is enabled
    bool public operatorFilteringEnabled;

    // Mapping of token ids to lockup expirations
    mapping(uint256 => uint256) public tokenLockups;

    // Base metadata uri
    string private _baseTokenURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * Proxy initialization code. Used in place of a constructor for upgradeable contracts.
     * @param name Token name
     * @param symbol Token symbol
     * @param _capsule Address of the capsule contract that will mint NFTs from this contract
     * @param _royaltyReceiver Address that will receive royalties
     */
    function initialize(string memory name, string memory symbol, address _capsule, address _royaltyReceiver)
        public
        initializer
    {
        // Upgradeable initializations
        __ERC721_init(name, symbol);
        __UUPSUpgradeable_init();
        __Ownable_init();

        // Set capsule contract
        etherCapsule = _capsule;

        // Setup operator filtering
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty to 5%
        _setDefaultRoyalty(_royaltyReceiver, 500);
    }

    /**
     * Function to redeem an EtherAvatar after burning a capsule. Token lockups will carry
     * over from the capsule nft. Only the capsule contract can call this function.
     * @param to Address that will receive the NFT
     * @param tokenId The id of the capsule that was burned. These tokens will map 1:1
     * @param lockupExpiration The lockup expiration time of the capsule nft.
     */
    function redeem(address to, uint256 tokenId, uint256 lockupExpiration) external {
        if (msg.sender != etherCapsule) revert NotAuthorized();

        // Mint the tokens
        _mint(to, tokenId);

        // Carry over lockup expiration from capsule
        tokenLockups[tokenId] = lockupExpiration;
    }

    /**
     * Owner-only function to adjust the lockup period for a given token.
     * @param tokenId Token Id to set the lockup period for
     * @param expiration The new lockup expiration
     */
    function setTokenLockup(uint256 tokenId, uint256 expiration) external onlyOwner {
        tokenLockups[tokenId] = expiration;
    }

    // =========================================================================
    //                                  ERC165
    // =========================================================================

    /**
     * Overridden supportsInterface with IERC721 support and ERC2981 support
     * @param interfaceId Interface Id to check
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    /**
     * Overridden OpenZeppelin transfer hook that will make sure locked tokens cannot be transferred.
     */
    function _beforeTokenTransfer(address, address, uint256 firstTokenId, uint256 batchSize) internal view override {
        unchecked {
            for (uint256 i; i < batchSize; ++i) {
                if (tokenLockups[firstTokenId + i] >= block.timestamp) {
                    revert TokenIsLocked(firstTokenId + i);
                }
            }
        }
    }

    /**
     * Overridden setApprovalForAll with operator filtering.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * Overridden approve with operator filtering.
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * Overridden transferFrom with operator filtering.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * Overridden safeTransferFrom with operator filtering
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * Overridden safeTransferFrom with operator filtering
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * Owner-only function to toggle operator filtering.
     * @param value Whether operator filtering is on/off.
     */
    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    // =========================================================================
    //                                 ERC2891
    // =========================================================================

    /**
     * Owner-only function to set the royalty receiver and royalty rate
     * @param receiver Address that will receive royalties
     * @param feeNumerator Royalty amount in basis points. Denominated by 10000
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // =========================================================================
    //                                 Metadata
    // =========================================================================

    /**
     * Owner-only function to set the base uri used for metadata.
     * @param baseURI uri to use for metadata
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Function to retrieve the metadata uri for a given token. Reverts for tokens that don't exist.
     * @param tokenId Token Id to get metadata for
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }
}