// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC677 {
  function transferAndCall(address to, uint value, bytes calldata data) external returns (bool success);

  event TransferWithData(address indexed from, address indexed to, uint value, bytes data);
}