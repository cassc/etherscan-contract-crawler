// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface  IERC20Receiver {

  function onERC20Received(address sender, address recipient, uint256 amount, bytes memory _data) external returns(bytes4);
}