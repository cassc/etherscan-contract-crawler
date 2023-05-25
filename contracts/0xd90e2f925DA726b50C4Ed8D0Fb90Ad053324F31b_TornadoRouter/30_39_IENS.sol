// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IENS {
  function owner(bytes32 node) external view returns (address);
}