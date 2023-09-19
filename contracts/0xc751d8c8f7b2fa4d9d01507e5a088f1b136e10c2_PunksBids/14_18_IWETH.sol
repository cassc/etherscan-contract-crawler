// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    /**
     * @dev Send ETH to get the same amount of WETH
     */
    function deposit() external payable;

    /**
     * @dev Unwrap WETH to withdraw the same amount of ETH
     * @param amount Amount of ETH to withdraw
     */
    function withdraw(uint256 amount) external;
}