// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface ERC20Receiver {
  function onERC20Received(
    address account,
    address recipient,
    uint256 amount,
    bytes memory data
  ) external returns (bytes4);
}