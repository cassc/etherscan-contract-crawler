// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PreWknd is ReentrancyGuard, AdminControl, ICreatorExtensionTokenURI, IERC1155Receiver, IERC721Receiver {
    using Strings for uint256;

    address public _creatorCore;
    address public _sharedContract;

    mapping(uint => bool) public _allowedTokenIds;

    mapping(uint => string) public tokenURIs;
    mapping(uint => bool) public hasBeenWrapped;

    mapping(uint => uint) public newToOldTokenMappings;
    mapping(uint => uint) public oldToNewTokenMappings;

    mapping(uint => bool) public showRemastered;

    function configure(address creatorCore, address sharedContract, uint[] calldata allowedTokenIds) public adminRequired {
      require(_creatorCore == address(0), "Already configured");
      _creatorCore = creatorCore;
      _sharedContract = sharedContract;
      for (uint i = 0; i < allowedTokenIds.length; i++){ 
          _allowedTokenIds[allowedTokenIds[i]] = true;
      }
    }

    function onERC1155Received(
      address,
      address from,
      uint256 id,
      uint256,
      bytes calldata
    ) external override nonReentrant returns(bytes4) {
      require(msg.sender == _sharedContract && _allowedTokenIds[id], "Cannot redeem non-allowed token");
      if (hasBeenWrapped[id]) {
          // If already wrapped, accept token and send back 721 token
          IERC721(_creatorCore).transferFrom(address(this), from, oldToNewTokenMappings[id]);
      } else {
          // Make new token
          uint tokenId = IERC721CreatorCore(_creatorCore).mintExtension(from);
          // Associate new and old tokens
          newToOldTokenMappings[tokenId] = id;
          oldToNewTokenMappings[id] = tokenId;
          hasBeenWrapped[id] = true;
      }
      return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
      address operator,
      address from,
      uint256[] calldata ids,
      uint256[] calldata values,
      bytes calldata data
    ) external override nonReentrant returns(bytes4) {
      require(ids.length == 1 && ids.length == values.length, "Invalid input");
      this.onERC1155Received(operator, from, ids[0], values[0], data);
      return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
      address,
      address from,
      uint256 id,
      bytes calldata
    ) external override nonReentrant returns(bytes4) {
      require(msg.sender == _creatorCore, "Cannot redeem other tokens.");
      // Send out the old token
      IERC1155(_sharedContract).safeTransferFrom(address(this), from, newToOldTokenMappings[id], 1, "0x0");
      return this.onERC721Received.selector;
    }

    function setTokenURI(string memory uri, uint tokenId) public adminRequired {
      tokenURIs[tokenId] = uri;
    }

    function flipOverride(uint tokenId) public {
      require(IERC721(_creatorCore).ownerOf(tokenId) == msg.sender, "Not owner");
      showRemastered[tokenId] = !showRemastered[tokenId];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
      return interfaceId == type(ICreatorExtensionTokenURI).interfaceId
        || interfaceId == type(IERC1155Receiver).interfaceId
        || interfaceId == type(IERC721Receiver).interfaceId
        || super.supportsInterface(interfaceId);
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
      require(creator == _creatorCore, "Invalid token");
      if (showRemastered[tokenId]) {
        return tokenURIs[tokenId];
      } else {
        string memory originalString = IERC1155MetadataURI(_sharedContract).uri(newToOldTokenMappings[tokenId]);
        bytes memory originalBytes = bytes(originalString);
        bytes memory modifiedBytes = new bytes(originalBytes.length-5);
        for(uint i = 0; i < originalBytes.length-6; i++) {
            modifiedBytes[i] = originalBytes[i];
        }
        return string(abi.encodePacked(string(modifiedBytes), newToOldTokenMappings[tokenId].toHexString()));
      }
    }


}