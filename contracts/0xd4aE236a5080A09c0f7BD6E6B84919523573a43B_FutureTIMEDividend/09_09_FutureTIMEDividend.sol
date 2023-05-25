// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./BaseERC20.sol";

contract FutureTIMEDividend is BaseERC20 {
  constructor(uint256 supply) BaseERC20(supply, "Future T.I.M.E. Dividend", "FUTURE") {}
}