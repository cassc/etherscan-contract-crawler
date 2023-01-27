// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz
/// @artist: Gavin Shapiro

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCoreEnumerable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


interface ILazyDelivery is IERC165 {
    function deliver(uint40 listingId, address to, uint256 assetId, uint24 payableCount, uint256 payableAmount, address payableERC20, uint256 index) external returns(uint256);
}

contract MeaningExtension is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery{
    
    // Creator Contract Address
    address private _creator;
    bool public delivered;

    // Animation and thumbnail URIs. All other metadata is on-chain.
    string private _imageURI;
    string private _animationURI;
    string private _description;

    // Marketplace address and listingID for the Meaning auction
    address _marketplace;
    uint _listingId;

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(ILazyDelivery).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    // Set up extension with marketplace address, listing ID, thumbnail image URI, and animation URI
    function configure(address creator, uint40 listingId, address marketplace, string memory newImageURI, string memory newAnimationURI, string memory description) public adminRequired {
        _creator = creator;
        _listingId = listingId;
        _marketplace = marketplace;
        _imageURI = newImageURI;
        _animationURI = newAnimationURI;
        _description = description;
    }

    // Mint tokens to auction winners upon settlement
    function deliver(uint40 listingId, address to, uint256, uint24, uint256, address, uint256) external override returns(uint) {
        require(msg.sender == _marketplace && listingId == _listingId, "Invalid calldata");
        delivered = true;
        return IERC721CreatorCore(_creator).mintExtension(to);
    }

    function _wrapTrait(string memory trait, string memory value) public pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }

    // Build tokenURI based on on-chain metadata
    function buildTokenURI(uint tokenID) public view returns(string memory){
        return string(abi.encodePacked('data:application/json;utf8,',
            '{"name":"Meaning #',
            Strings.toString(tokenID), 
            '","description":',
            '"',_description,'"', 
            ',"attributes":[',
            _wrapTrait("Type", "Meaning"),
            '],"animation_url":"',
            _animationURI,'","',
            "image_url",'":"',
            _imageURI,
            '"}')
        );
    }

    function tokenURI(address creator, uint256 tokenId) public view override returns(string memory) {
        require(creator == _creator, "Invalid token");
        return buildTokenURI(tokenId);
    }
}