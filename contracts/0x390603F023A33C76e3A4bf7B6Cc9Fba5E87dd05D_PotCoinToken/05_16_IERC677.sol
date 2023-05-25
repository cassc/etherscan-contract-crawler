// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

abstract contract IERC677 {
  function transferAndCall(address to, uint value, bytes memory data) public virtual returns (bool success);

  event Transfer(address indexed from, address indexed to, uint value, bytes data);
  
}