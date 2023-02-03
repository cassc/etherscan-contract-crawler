// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Minter.sol";
import "./IRERC20.sol";
import "./IBridgeable.sol";

interface IBridgeRERC20 is IBridgeable, IMinter, IRERC20
{
}