// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract WhopWithdrawable {
  error TransferFailed();

  function withdraw() public {
    _withdrawEth(address(this).balance, msg.sender);
  }

  function withdraw(uint256 amount) public {
    if (amount > address(this).balance) amount = address(this).balance;
    _withdrawEth(amount, msg.sender);
  }

  function withdraw(address token) public {
    _withdrawERC20(token, IERC20(token).balanceOf(address(this)), msg.sender);
  }

  function withdraw(address token, uint256 amount) public {
    uint256 balance = IERC20(token).balanceOf(address(this));
    if (amount > balance) _withdrawERC20(token, balance, msg.sender);
    else _withdrawERC20(token, amount, msg.sender);
  }

  function withdrawTo(address receiver) public {
    _withdrawEth(address(this).balance, receiver);
  }

  function withdrawTo(address receiver, uint256 amount) public {
    if (amount > address(this).balance) amount = address(this).balance;
    _withdrawEth(amount, receiver);
  }

  function withdrawTo(address token, address receiver) public {
    _withdrawERC20(token, IERC20(token).balanceOf(address(this)), receiver);
  }

  function withdrawTo(
    address token,
    address receiver,
    uint256 amount
  ) public {
    uint256 balance = IERC20(token).balanceOf(address(this));
    if (amount > balance) _withdrawERC20(token, balance, receiver);
    else _withdrawERC20(token, amount, receiver);
  }

  function _withdrawEth(uint256 amount, address receiver) private {
    uint256 actual = _beforeWithdraw(msg.sender, receiver, address(0), amount);
    (bool success, ) = receiver.call{value: actual}("");
    if (!success) revert TransferFailed();
  }

  function _withdrawERC20(
    address token,
    uint256 amount,
    address receiver
  ) private {
    uint256 actual = _beforeWithdraw(msg.sender, receiver, token, amount);
    bool success = IERC20(token).transfer(receiver, actual);
    if (!success) revert TransferFailed();
  }

  function _beforeWithdraw(
    address withdrawer,
    address receiver,
    address token,
    uint256 amount
  ) internal virtual returns (uint256);

  receive() external payable {}
}