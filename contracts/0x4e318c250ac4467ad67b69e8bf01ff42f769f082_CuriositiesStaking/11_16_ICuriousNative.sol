// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICuriousNative is IERC20 {
    function mintFor(address to, uint256 amount) external;
}