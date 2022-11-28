// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { IPool } from "@aave/core-v3/contracts/interfaces/IPool.sol";
import { IRewardsController } from "@aave/periphery-v3/contracts/rewards/interfaces/IRewardsController.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Defii } from "../Defii.sol";


contract UsdAaveUsdt is Defii {
    IERC20 constant USDT = IERC20(0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7);
    IERC20 constant aAvaUSDT = IERC20(0x6ab707Aca953eDAeFBc4fD23bA73294241490620);
    IERC20 constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    IPool constant pool = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
    IRewardsController constant rewardsController = IRewardsController(0x929EC64c34a17401F460460D4B9390518E5B473e);

    function hasAllocation() external view override returns (bool) {
        return aAvaUSDT.balanceOf(address(this)) > 0;
    }

    function _enter() internal override {
        uint256 usdtBalance = USDT.balanceOf(address(this));
        USDT.approve(address(pool), usdtBalance);
        pool.supply(address(USDT), usdtBalance, address(this), 0);
    }

    function _exit() internal override {
        _claimRewards();
        pool.withdraw(address(USDT), type(uint256).max, address(this));
    }
    
    function _harvest() internal override {
        _claimRewards();
        withdrawERC20(WAVAX);
    }

    function _withdrawFunds() internal override {
        withdrawERC20(USDT);
        withdrawERC20(WAVAX);
    }

    // Internal logic
    function _claimRewards() internal {
        address[] memory assets = new address[](1);
        assets[0] = address(aAvaUSDT); 
        rewardsController.claimAllRewardsToSelf(assets);
    }
}