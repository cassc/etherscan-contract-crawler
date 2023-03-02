// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}