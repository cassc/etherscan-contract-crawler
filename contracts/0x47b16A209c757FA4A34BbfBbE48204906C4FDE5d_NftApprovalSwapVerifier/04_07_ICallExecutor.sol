// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

interface ICallExecutor {
  function proxyCall(address to, bytes memory data) external payable;
}