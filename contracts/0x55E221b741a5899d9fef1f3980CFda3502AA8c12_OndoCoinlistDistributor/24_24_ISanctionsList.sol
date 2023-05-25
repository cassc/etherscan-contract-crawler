/// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.3;

interface ISanctionsList {
  function isSanctioned(address addr) external view returns (bool);
}