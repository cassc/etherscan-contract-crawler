// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPermissionlessPoolMaster {
  function manager() external view returns (address);

  function currency() external view returns (address);
}