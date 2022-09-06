// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IMinter is IERC1155 {
  function mintSpecific(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) external;

  function burn(
    address from,
    uint256 id,
    uint256 amount
  ) external;
}