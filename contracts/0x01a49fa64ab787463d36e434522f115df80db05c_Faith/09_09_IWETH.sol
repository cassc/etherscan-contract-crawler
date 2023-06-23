// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function withdraw(uint256 amt) external;

    function deposit(uint256 amt) external payable;
}