//Made with Student Coin Terminal
//SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IToken} from "./IToken.sol";

interface ITokenERC20 is IERC20, IToken {}