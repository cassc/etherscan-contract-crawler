// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPausable {
  event Paused(bool _paused);

  function pause(bool _paused) external;
}