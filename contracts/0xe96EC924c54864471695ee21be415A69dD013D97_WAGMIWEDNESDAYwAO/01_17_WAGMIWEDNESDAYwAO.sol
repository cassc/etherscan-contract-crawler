// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

interface ILazyDelivery is IERC165 {
    function deliver(address caller, uint256 listingId, uint256 assetId, address to, uint256 payableAmount, uint256 index) external returns(uint256);
}

interface ILazyDeliveryMetadata is IERC165 {
    function assetURI(uint256 assetId) external view returns(string memory);
}


contract WAGMIWEDNESDAYwAO is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata {
    address private _creator;
    address private _marketplace;
    uint private _listingId;
    uint private _tokenIdToMint;

    string private _assetURI;

    mapping(address => bool) private minters;

    constructor(address creator) {
        _creator = creator;
    }

    function initialize() public adminRequired {
        address[] memory addressToSend = new address[](1);
        addressToSend[0] = msg.sender;
        uint[] memory amounts = new uint[](1);
        amounts[0] = 1;
        string[] memory uris = new string[](1);
        uris[0] = "";

        IERC1155CreatorCore(_creator).mintExtensionNew(addressToSend, amounts, uris);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(ILazyDelivery).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function setListing(uint listingId, address marketplace, uint tokenIdToMint) public adminRequired {
        _listingId = listingId;
        _marketplace = marketplace;
        _tokenIdToMint = tokenIdToMint;
    }

    function deliver(address, uint256 listingId, uint256, address to, uint256, uint256) external override returns(uint256) {
        require(msg.sender == _marketplace && listingId == _listingId, "Invalid call data");

        address[] memory addressToSend = new address[](1);
        addressToSend[0] = to;
        uint[] memory tokenToSend = new uint[](1);
        tokenToSend[0] = _tokenIdToMint;
        uint[] memory amounts = new uint[](1);
        amounts[0] = 1;
        require(!minters[to], "Only 1 per wallet.");
        minters[to] = true;

        IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, tokenToSend, amounts);

        return 1;
    }

    function setNewAssetURI(string memory newAssetURI) public adminRequired {
        _assetURI = newAssetURI;
    }

    function assetURI(uint256) external view override returns(string memory) {
        return _assetURI;
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return this.assetURI(tokenId);
    }
}