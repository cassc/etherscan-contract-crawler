// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC1155Minter {
  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;
}