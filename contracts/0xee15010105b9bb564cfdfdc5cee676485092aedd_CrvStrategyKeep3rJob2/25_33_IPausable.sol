// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPausable {
  event Paused(bool _paused);

  function pause(bool _paused) external;
}