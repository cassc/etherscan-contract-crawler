// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "./Storage.sol";
import "./Liquidity.sol";
import "./Getter.sol";
import "./Admin.sol";

contract LiquidityPoolHop2 is Storage, Liquidity, Admin {}