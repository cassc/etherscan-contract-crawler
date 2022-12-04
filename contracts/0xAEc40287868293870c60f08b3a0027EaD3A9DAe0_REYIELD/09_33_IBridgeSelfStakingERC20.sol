// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Minter.sol";
import "./ISelfStakingERC20.sol";
import "./IBridgeable.sol";

interface IBridgeSelfStakingERC20 is IBridgeable, IMinter, ISelfStakingERC20
{
}