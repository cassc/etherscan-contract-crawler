// SPDX-License-Identifier: MIT LICENSE 

pragma solidity 0.8.4;

interface IWarRoom {
  function addManyToBarnAndPack(address account, uint16[] calldata tokenIds) external;
  function randomWolfOwner(uint256 seed) external view returns (address);
}