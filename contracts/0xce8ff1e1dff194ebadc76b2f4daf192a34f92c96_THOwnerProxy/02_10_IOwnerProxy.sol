// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface IOwnerProxy{
  function ownerOf(bytes32 hash) external view returns(address);
  function initOwnerOf(bytes32 hash, address addr) external returns(bool);
}