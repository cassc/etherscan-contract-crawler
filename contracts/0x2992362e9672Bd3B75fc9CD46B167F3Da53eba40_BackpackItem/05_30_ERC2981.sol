// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC2981.sol";

abstract contract ERC2981 is ERC165, IERC2981 {
  struct RoyaltyInfo {
    address recipient;
    uint24 amount;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }
}