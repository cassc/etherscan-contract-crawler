// SPDX-License-Identifier: MIT
// GM2 Contracts (last updated v0.0.1)
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '../interfaces/IGMAttributesController.sol';

contract GMAttributesController is ERC165, IGMAttributesController {
  function getDynamicAttributes(address from, uint256 tokenId)
    external
    view
    virtual
    returns (Attribute[] memory attributes)
  {}

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return interfaceId == type(IGMAttributesController).interfaceId || super.supportsInterface(interfaceId);
  }
}