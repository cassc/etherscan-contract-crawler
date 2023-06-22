//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IVoters {
  function snapshot() external returns (uint);
  function totalSupplyAt(uint snapshotId) external view returns (uint);
  function votesAt(address account, uint snapshotId) external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function balanceOfAt(address account, uint snapshotId) external view returns (uint);
  function donate(uint amount) external;
}