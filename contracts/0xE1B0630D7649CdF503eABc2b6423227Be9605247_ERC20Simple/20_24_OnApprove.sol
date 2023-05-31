// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface OnApprove {
  function onApprove(address owner, address spender, uint256 amount, bytes calldata data) external returns (bool);
}