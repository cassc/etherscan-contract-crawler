// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: @yungwknd

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@manifoldxyz/marketplace-solidity/contracts/ILazyDelivery.sol";
import "@manifoldxyz/marketplace-solidity/contracts/ILazyDeliveryMetadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Breathe is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata {
    using Strings for uint256;
    address private _creatorAddress;
    string private _baseURI;

    uint40 private _listingId;
    address private _marketplace;

    uint[] private numbers;
    uint private numbersLeft;
    uint private seed;

    mapping(uint => uint) public tokens;

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return (
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            interfaceId == type(ILazyDelivery).interfaceId ||
            interfaceId == type(ILazyDeliveryMetadata).interfaceId ||
            AdminControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId)
        );
    }

    function configure(uint40 listingId, address marketplace, address creator) public adminRequired {
        _listingId = listingId;
        _marketplace = marketplace;
        _creatorAddress = creator;
    }

    function setBaseURI(string memory baseURI, uint maxTokens, uint newSeed) public adminRequired {
        _baseURI = baseURI;
        numbersLeft = maxTokens;
        for (uint i = 1; i <= maxTokens; i++) {
            numbers.push(i);
        }
        seed = newSeed;
    }

    function getRandomMint() private returns (uint) {
        require(numbersLeft > 0, "All numbers have been picked");

        uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % numbersLeft;
        uint result = numbers[randomIndex];

        numbers[randomIndex] = numbers[numbersLeft - 1];
        numbersLeft--;

        return result;
    }

    function deliver(uint40 listingId, address to, uint256, uint24 payableCount, uint256, address, uint256) external override {
        require(msg.sender == _marketplace && listingId == _listingId, "Invalid call data");

        for (uint i = 0; i < payableCount; i++) {
            uint t = IERC721CreatorCore(_creatorAddress).mintExtension(to);
            tokens[t] = getRandomMint();
        }
    }

    function assetURI(uint256) public view override returns(string memory) {
        return string(abi.encodePacked(
            _baseURI,
            (uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % numbers.length).toString(),
            ".json"
        ));
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns(string memory) {
        require(creator == _creatorAddress, "Invalid creator");
        return string(abi.encodePacked(
            _baseURI,
            tokens[tokenId].toString(),
            ".json"
        ));
    }
}