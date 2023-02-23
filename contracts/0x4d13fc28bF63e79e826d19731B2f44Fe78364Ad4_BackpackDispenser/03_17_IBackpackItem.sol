// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

interface IBackpackItem {
  function fulfill(address recipient, bool maximum) external;
}