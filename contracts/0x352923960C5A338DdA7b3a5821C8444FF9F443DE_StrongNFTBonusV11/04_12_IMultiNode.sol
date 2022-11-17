// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IMultiNode {
  function doesNodeExist(address entity, uint nodeId) external view returns (bool);

  function hasNodeExpired(address entity, uint nodeId) external view returns (bool);

  function claim(uint nodeId, uint timestamp, address toStrongPool) external payable returns (uint);
}