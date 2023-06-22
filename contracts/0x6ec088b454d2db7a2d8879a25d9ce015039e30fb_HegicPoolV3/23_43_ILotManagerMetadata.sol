// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface ILotManagerMetadata {
  function isLotManager() external pure returns (bool);
  function getName() external pure returns (string memory);
}