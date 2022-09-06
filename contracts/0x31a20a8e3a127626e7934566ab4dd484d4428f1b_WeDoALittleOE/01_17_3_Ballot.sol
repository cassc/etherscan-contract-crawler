// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

interface ILazyDelivery {
    function deliver(uint40 listingId, address to, uint256 assetId, uint24 payableCount, uint256 payableAmount, address payableERC20, uint256 index) external returns(uint256);
}

interface ILazyDeliveryMetadata {
    function assetURI(uint256 assetId) external view returns(string memory);
}

contract WeDoALittleOE is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata {

    using Strings for uint256;
    using Strings for uint16;

    address _creator;
    uint _listingId;
    address _marketplace;
    string _baseURI;

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(ILazyDelivery).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function configure(uint listingId, address marketplace, address creatorContract) public adminRequired {
        _listingId = listingId;
        _marketplace = marketplace;
        _creator = creatorContract;
    }

    function deliver(uint40 listingId, address to, uint256, uint24, uint256, address, uint256) external override returns(uint256) {
        require(msg.sender == _marketplace && listingId == _listingId, "Invalid call data");

        address[] memory addressToSend = new address[](1);
        addressToSend[0] = to;
        uint[] memory tokenToSend = new uint[](1);
        tokenToSend[0] = 1;
        uint[] memory numToSend = new uint[](1);
        numToSend[0] = 1;

        if (IERC1155CreatorCore(_creator).totalSupply(1) < 1) {
            string[] memory uris = new string[](1);
            uris[0] = "";
            IERC1155CreatorCore(_creator).mintExtensionNew(addressToSend, tokenToSend, uris);
        } else {
            IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, tokenToSend, numToSend);
        }

        return 1;
    }

    function setURI(string memory baseURI) public adminRequired {
        _baseURI = baseURI;
    }

    function assetURI(uint256) external view override returns(string memory) {
        return _baseURI;
    }

    function tokenURI(address creator, uint256) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return _baseURI;
    }
}