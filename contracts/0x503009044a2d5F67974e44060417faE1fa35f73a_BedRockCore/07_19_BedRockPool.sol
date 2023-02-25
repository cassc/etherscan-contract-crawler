// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/Maths.sol";

import "hardhat/console.sol";

contract BedRockPool {
    using SafeERC20 for IERC20;

    mapping(address => bool) public tokenMapping;
    mapping(address => uint256) public poolAssets;
    mapping(uint256 => address) public tokenArray;
    uint256 public tokenCounter;

    event Saved(address token, uint256 amount);
    event RewardPaid(address account, address token, uint256 amount);

    /**
     * @notice save token to the pool
     * @param token address of token to save. must inherit of IERC20
     * @param amount amount to save
     */
    function _save(address token, uint256 amount) internal {
        if (!tokenMapping[token]) {
            tokenMapping[token] = true;
            tokenCounter++;
            tokenArray[tokenCounter] = token;
        }

        poolAssets[token] += amount;
        emit Saved(token, amount);
    }

    /**
     * @notice swap BedRock token
     * should be called by controller
     * @param amount BedRock amount to swap
     */
    function _swap(uint256 amount) internal {
        uint256 totalSupply = IERC20(address(this)).totalSupply();
        uint256 percent = Maths.normalizeFraction(amount, totalSupply);
        for (uint256 i = 1; i <= tokenCounter; i++) {
            address token = tokenArray[i];
            uint256 rewardAmount = (poolAssets[token] * percent) / INTERNAL_DENOMINATOR;
            IERC20(token).safeTransfer(msg.sender, rewardAmount);

            emit RewardPaid(msg.sender, token, rewardAmount);
        }
    }
}