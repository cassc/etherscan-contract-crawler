// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import './OffchainBouncer.sol';

library OpenSeaGasFreeListing {
  /**
  @notice Returns whether the operator is an OpenSea proxy for the owner, thus
  allowing it to list without the token owner paying gas.
  @dev ERC{721,1155}.isApprovedForAll should be overriden to also check if
  this function returns true.
    */
  function isApprovedForAll(address owner, address operator) internal view returns (bool) {
    OSProxy registry;
    assembly {
      switch chainid()
      case 1 {
        // mainnet
        registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
      }
      case 4 {
        // rinkeby
        registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
      }
    }

    return address(registry) != address(0) && address(registry.proxies(owner)) == operator;
  }
}

contract OwnableDelegateProxy { }

contract OSProxy {
  mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract ERC1155Bouncer is OffchainBouncer, ERC1155, ERC1155Supply, ERC1155Burnable, Pausable {
  string name_;
  string symbol_; 

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }    

  /**
  * @notice change the base URI for the NFT
  *
  * @param baseURI the new NFT uri base
  */
  function setURI(string memory baseURI) external onlyOwner {
    _setURI(baseURI);
  }

  /**
  * @notice returns the metadata uri for a given id
  *
  * @param _id the NFT to return metadata for
  */
  function uri(uint256 _id) public view override returns (string memory) {
    require(exists(_id), "URI: nonexistent token");

    return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json"));
  }

  // Required overrides
  function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControl, ERC1155) returns (bool) {
    return ERC1155.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
  } 

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155Supply) {
      super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  /**
   * OpenSea gas-free listings.
   */

  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    return OpenSeaGasFreeListing.isApprovedForAll(owner, operator) || super.isApprovedForAll(owner, operator);
  }
}