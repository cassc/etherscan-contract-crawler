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


contract AndreQuintupleOpenEdition is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata {
    address private _creator;
    address private _marketplace;

    uint256[] private _tokenIds = new uint256[](5);
    uint[] private _listingIds = new uint[](5);
    uint[] private _tokenIdsToMint = new uint[](5);

    // tokenId -> assetURI
    mapping(uint256 => string) private _assetURIs;


    constructor(address creator) {
        _creator = creator;
    }

    function initialize() public adminRequired {
        address[] memory addressToSend = new address[](1);
        addressToSend[0] = msg.sender;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        string[] memory uris = new string[](1);
        uris[0] = "";

        _tokenIds[0] = IERC1155CreatorCore(_creator).mintExtensionNew(
          addressToSend,
          amounts,
          uris
        )[0];
        _tokenIds[1] = IERC1155CreatorCore(_creator).mintExtensionNew(
          addressToSend,
          amounts,
          uris
        )[0];
        _tokenIds[2] = IERC1155CreatorCore(_creator).mintExtensionNew(
          addressToSend,
          amounts,
          uris
        )[0];
        _tokenIds[3] = IERC1155CreatorCore(_creator).mintExtensionNew(
          addressToSend,
          amounts,
          uris
        )[0];
        _tokenIds[4] = IERC1155CreatorCore(_creator).mintExtensionNew(
          addressToSend,
          amounts,
          uris
        )[0];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId
          || interfaceId == type(ILazyDelivery).interfaceId
          || AdminControl.supportsInterface(interfaceId)
          || super.supportsInterface(interfaceId);
    }

    function setListings(address marketplace, uint listingId1, uint listingId2, uint listingId3, uint listingId4, uint listingId5, uint tokenIdToMint1, uint tokenIdToMint2, uint tokenIdToMint3, uint tokenIdToMint4, uint tokenIdToMint5) public adminRequired {
        _marketplace = marketplace;

        _listingIds[0] = listingId1;
        _tokenIdsToMint[0] = tokenIdToMint1;

        _listingIds[1] = listingId2;
        _tokenIdsToMint[1] = tokenIdToMint2;

        _listingIds[2] = listingId3;
        _tokenIdsToMint[2] = tokenIdToMint3;

        _listingIds[3] = listingId4;
        _tokenIdsToMint[3] = tokenIdToMint4;

        _listingIds[4] = listingId5;
        _tokenIdsToMint[4] = tokenIdToMint5;
    }

    /*
     * @dev: Must be ran after setListings is ran once
     */
    function setListing(uint index, uint listingId, uint tokenIdToMint) public adminRequired {
        require(index < 5, "Index OOB");
        _listingIds[index] = listingId;
        _tokenIdsToMint[index] = tokenIdToMint;
    }

    function deliver(address, uint256 listingId, uint256, address to, uint256, uint256) external override returns(uint256) {
        require(msg.sender == _marketplace
            && (listingId == _listingIds[0]
                || listingId == _listingIds[1]
                || listingId == _listingIds[2]
                || listingId == _listingIds[3]
                || listingId == _listingIds[4]
        ), "Invalid call data");

        address[] memory addressToSend = new address[](1);
        addressToSend[0] = to;

        uint[] memory tokenIdToSend = new uint[](1);
        if (listingId == _listingIds[0]) {
            tokenIdToSend[0] = _tokenIdsToMint[0];
        } else if (listingId == _listingIds[1]) {
            tokenIdToSend[0] = _tokenIdsToMint[1];
        } else if (listingId == _listingIds[2]) {
            tokenIdToSend[0] = _tokenIdsToMint[2];
        } else if (listingId == _listingIds[3]) {
            tokenIdToSend[0] = _tokenIdsToMint[3];
        } else if (listingId == _listingIds[4]) {
            tokenIdToSend[0] = _tokenIdsToMint[4];
        }

        uint[] memory amounts = new uint[](1);
        amounts[0] = 1;

        // @dev: use balance checking to enforce limits here

        IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, tokenIdToSend, amounts);

        return 1;
    }

    /*
     * @dev: Must be ran after initialize
     */
    function setNewAssetURIs(string memory newAssetURI1, string memory newAssetURI2, string memory newAssetURI3, string memory newAssetURI4, string memory newAssetURI5) public adminRequired {
        _assetURIs[_tokenIds[0]] = newAssetURI1;
        _assetURIs[_tokenIds[1]] = newAssetURI2;
        _assetURIs[_tokenIds[2]] = newAssetURI3;
        _assetURIs[_tokenIds[3]] = newAssetURI4;
        _assetURIs[_tokenIds[4]] = newAssetURI5;
    }

    /*
     * @dev: Must be ran after initialize
     */
    function setNewAssetURI(uint index, string memory newAssetURI) public adminRequired {
        require(index < 5, "Index OOB");
        _assetURIs[_tokenIds[index]] = newAssetURI;
    }

    function assetURI(uint tokenId) external view override returns(string memory) {
        return _assetURIs[tokenId];
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return this.assetURI(tokenId);
    }
}