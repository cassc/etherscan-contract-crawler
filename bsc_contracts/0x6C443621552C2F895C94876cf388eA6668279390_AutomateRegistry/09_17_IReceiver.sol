// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IReceiver {
  function transferWithData(bytes calldata data) external payable returns (bool);
}