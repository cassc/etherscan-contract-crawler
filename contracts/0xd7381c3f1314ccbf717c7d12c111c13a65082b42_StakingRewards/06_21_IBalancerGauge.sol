// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Deposit and Withdraw LP tokens to Balancer Gauge 
 */
interface IBalancerGauge is IERC20 {
    function deposit(uint256) external;
    function withdraw(uint256) external;
}