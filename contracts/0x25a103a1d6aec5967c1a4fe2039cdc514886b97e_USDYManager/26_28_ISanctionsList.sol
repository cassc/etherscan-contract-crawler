/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface ISanctionsList {
  function isSanctioned(address addr) external view returns (bool);
}