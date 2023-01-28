//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface IAirbaseManager {
  event UpdateCA(address indexed old, address indexed newCa);

  function updateCA(address ca) external;
}