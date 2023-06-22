// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../vendor/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC20NonStandard.sol";

interface CTokenLike {
  error TransferComptrollerRejection(uint256);

  function balanceOf(address holder) external returns (uint);
  function borrow(uint amount) external returns (uint);
  function transfer(address dst, uint256 amt) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
  function redeem(uint redeemTokens) external returns (uint);
  function borrowBalanceCurrent(address account) external returns (uint);
  function approve(address spender, uint256 amount) external returns (bool);
  function exchangeRateCurrent() external returns (uint);
  function exchangeRateStored() external view returns (uint);
}

interface CErc20 is CTokenLike {
  function underlying() external returns (address);
  function mint(uint mintAmount) external returns (uint);
  function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
}

interface CEther is CTokenLike {
  function repayBorrowBehalf(address borrower) external payable;
}