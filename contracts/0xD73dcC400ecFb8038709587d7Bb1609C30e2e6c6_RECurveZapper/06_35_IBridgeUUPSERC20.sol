// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Minter.sol";
import "./IUUPSERC20.sol";
import "./IBridgeable.sol";

interface IBridgeUUPSERC20 is IBridgeable, IMinter, IUUPSERC20
{
}