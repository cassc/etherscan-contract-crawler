// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/extensions/IERC721AQueryable.sol";

interface IBeansDrop is IERC721AQueryable {
  function burn(uint256 tokenId) external;
}