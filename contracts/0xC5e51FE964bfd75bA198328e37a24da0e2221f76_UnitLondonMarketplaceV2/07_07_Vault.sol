// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) public virtual returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) public virtual returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return 0x150b7a02;
  }

  // Used by ERC721BasicToken.sol
  function onERC721Received(
    address,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return 0xf0b9e5ba;
  }

  receive() external payable {}
}