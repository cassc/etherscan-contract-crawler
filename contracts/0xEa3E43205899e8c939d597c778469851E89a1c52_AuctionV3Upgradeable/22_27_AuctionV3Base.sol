/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./AuctionV2Base.sol";

/// @title Variables for the V3 contract of the squirrel degens project
abstract contract AuctionV3Base is AuctionV2Base, DefaultOperatorFiltererUpgradeable, ERC2981Upgradeable {

    /*
       Private Mint
    */
    bool public privateMintStarted;
    bool public privateMintStopped;
    uint256 public privateMintPrice;
    uint256 public privateMintSupply;
    uint256 public privateMintTokensPerWallet;
    mapping(address => uint256) public privateMintMap;
    CountersUpgradeable.Counter internal _privateMintTokenCounter;

    /*
       Public Mint
    */
    bool public publicMintStarted;
    bool public publicMintStopped;
    uint256 public publicMintPrice;
    uint256 public publicMintSupply;
    uint256 public publicMintTokensPerWallet;
    mapping(address => uint256) public publicMintMap;
    CountersUpgradeable.Counter internal _publicMintTokenCounter;

    /*
        Crossmint
    */
    address internal _crossmintWallet;

    /*
       Royalties
    */
    address internal _royaltiesRecipient;

    modifier onlyCrossmint() {
        require(_msgSender() == _crossmintWallet, "Only the crossmint wallet may use this function");
        _;
    }

    function initializeV3(address crossmintWallet_, address royaltiesRecipient_) public reinitializer(3) onlyOwner {
        __ERC2981_init();
        __DefaultOperatorFilterer_init();

        _royaltiesRecipient = royaltiesRecipient_;
        _setDefaultRoyalty(royaltiesRecipient_, 500);

        _crossmintWallet = crossmintWallet_;
    }

    function supportsInterface(bytes4 interfaceId) public view override(AuctionV2Base, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setRoyalties(uint96 feeNominator) public onlyOwner {
        _setDefaultRoyalty(_royaltiesRecipient, feeNominator);
    }
}