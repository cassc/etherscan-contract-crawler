// SPDX-License-Identifier: PROPRIETARY

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapHelper is Ownable {
  constructor() {}

  function safeApprove(
    address token,
    address spender,
    uint amount
  ) external onlyOwner {
    IERC20(token).approve(spender, amount);
  }

  function safeWithdraw() external onlyOwner {
    payable(_msgSender()).transfer(address(this).balance);
  }
}