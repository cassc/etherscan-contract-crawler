// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IAip15 {
  function harvest() external;

  function withdrawFebEmissionDummy() external;

  function targetEmission() external view returns (uint256);
}
