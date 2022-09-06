// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract ERC721NamedUpgradeable is ERC721Upgradeable {
  mapping(uint256 => string) public names;

  event NameChanged(uint256 indexed tokenId, string name);

  function setTokenName(uint256 __tokenId, string calldata __name) external {
    require(_msgSender() == ownerOf(__tokenId), "Only owner can name token");
    names[__tokenId] = __name;
    emit NameChanged(__tokenId, __name);
  }
}