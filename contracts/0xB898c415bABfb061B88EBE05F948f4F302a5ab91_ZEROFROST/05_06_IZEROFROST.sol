// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZEROFROST {
  function epoch() external view returns (uint256);

  function nextEpoch() external view returns (uint256);

  function epochLength() external view returns (uint256);
}