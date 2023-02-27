// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./RefIERC4906.sol";

contract ERC4906 is ERC721, IERC4906 {
  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
    return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }
}