// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IJob {
  function work(bytes32 network, bytes calldata args) external;

  function workable(bytes32 network) external returns (bool canWork, bytes memory args);
}