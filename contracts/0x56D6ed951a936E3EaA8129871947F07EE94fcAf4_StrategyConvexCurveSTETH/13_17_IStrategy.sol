// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IStrategy {
    event Deposit(uint256 amount);
    event Withdraw(uint256 claimedAmount, uint256 totalAmount);
    event Harvest();
    event RewardToken(address indexed token, uint256 amount);

    function want() external view returns (address);

    function deposit() external;

    function withdrawForSwap(uint256) external returns (uint256);

    function withdraw(address) external returns (uint256 balance);

    function withdraw(uint256) external;

    function withdrawAll() external returns (uint256);

    function balanceOf() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function harvest() external;

    function setController(address _controller) external;
}