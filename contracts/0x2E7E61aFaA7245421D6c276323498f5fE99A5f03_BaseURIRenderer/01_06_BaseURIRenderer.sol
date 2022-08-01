// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IRebelsRenderer.sol";

contract BaseURIRenderer is IRebelsRenderer, ERC165 {
  string public baseURI;

  constructor(string memory baseURI_) {
    baseURI = baseURI_;
  }

  function tokenURI(uint256 id) external view override returns (string memory) {
    return string(abi.encodePacked(baseURI, Strings.toString(id), ".json"));
  }

  function beforeTokenTransfer(
    address from,
    address to,
    uint256 id
  ) external pure override {}

  function supportsInterface(bytes4 interfaceId) public view
      override(ERC165, IERC165) returns (bool) {
    return interfaceId == type(IRebelsRenderer).interfaceId ||
           super.supportsInterface(interfaceId);
  }
}