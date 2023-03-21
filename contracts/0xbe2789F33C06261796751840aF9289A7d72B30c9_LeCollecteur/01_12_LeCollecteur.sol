// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

interface ILazyDelivery is IERC165 {
    function deliver(uint40 listingId, address to, uint256 assetId, uint24 payableCount, uint256 payableAmount, address payableERC20, uint256 index) external;
}

interface ILazyDeliveryMetadata is IERC165 {
    function assetURI(uint256 assetId) external view returns(string memory);
}

contract LeCollecteur is AdminControl, ILazyDelivery, ILazyDeliveryMetadata {
    using Strings for uint256;

    address private _creator;
    uint256 private _firstTokenId;
    address private _tokenOwner;

    uint40 private _listingId;
    address private _marketplace;

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ILazyDelivery).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function setToken(address creator, uint256 firstTokenId, address tokenOwner) public adminRequired {
        _creator = creator;
        _firstTokenId = firstTokenId;
        _tokenOwner = tokenOwner;
    }

    function setListing(uint40 listingId, address marketplace) public adminRequired {
        _listingId = listingId;
        _marketplace = marketplace;
    }

    function deliver(uint40 listingId, address to, uint256, uint24, uint256, address, uint256 index) external override {
        require(msg.sender == _marketplace && listingId == _listingId, "Invalid call data");

        IERC721Metadata(_creator).safeTransferFrom(_tokenOwner, to, _firstTokenId + index);
    }

    function assetURI(uint256) public view override returns(string memory) {
        return IERC721Metadata(_creator).tokenURI(_firstTokenId);
    }
}