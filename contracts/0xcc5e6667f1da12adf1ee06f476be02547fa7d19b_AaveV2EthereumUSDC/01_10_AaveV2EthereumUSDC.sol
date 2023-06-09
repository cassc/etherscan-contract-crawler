// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Defii} from "../Defii.sol";

contract AaveV2EthereumUSDC is Defii {
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant aUSDC = IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);

    IPool constant pool = IPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    function hasAllocation() public view override returns (bool) {
        return aUSDC.balanceOf(address(this)) > 0;
    }

    function _enter() internal override {
        uint256 usdcBalance = USDC.balanceOf(address(this));
        USDC.approve(address(pool), usdcBalance);
        pool.deposit(address(USDC), usdcBalance, address(this), 0);
    }

    function _exit() internal override {
        pool.withdraw(address(USDC), type(uint256).max, address(this));
    }

    function _withdrawFunds() internal override {
        withdrawERC20(USDC);
    }
}

interface IPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(address asset, uint256 amount, address to) external;
}