// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IKeeperWrapper {
  function harvest(address _strategy) external;
}