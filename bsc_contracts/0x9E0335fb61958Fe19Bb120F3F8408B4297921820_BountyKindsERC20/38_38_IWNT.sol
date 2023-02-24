// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "../../../oz/token/ERC20/IERC20.sol";

interface IWNT is IERC20 {
    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}