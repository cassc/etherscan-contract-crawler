// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

interface IBurnableERC20 is IERC20 {
    function burn(uint256 amount) external;
}