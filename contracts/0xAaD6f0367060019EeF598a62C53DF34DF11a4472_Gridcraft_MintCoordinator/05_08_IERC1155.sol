//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC1155 {
  function balanceOf(address account, uint256 id) external view returns (uint256);
}