// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

interface IPausable {
  function paused() external view returns (bool);

  function pause() external;

  function unpause() external;
}