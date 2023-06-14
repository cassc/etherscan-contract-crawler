// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface INamelessToken {
  function initialize(string memory name, string memory symbol, address tokenDataContract, address initialAdmin) external;
}