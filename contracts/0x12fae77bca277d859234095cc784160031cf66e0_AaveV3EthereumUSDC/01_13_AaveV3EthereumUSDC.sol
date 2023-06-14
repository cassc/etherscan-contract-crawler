// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Defii} from "../Defii.sol";

contract AaveV3EthereumUSDC is Defii {
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant aEthUSDC =
        IERC20(0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c);

    IPool constant pool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

    function hasAllocation() public view override returns (bool) {
        return aEthUSDC.balanceOf(address(this)) > 0;
    }

    function _enter() internal override {
        uint256 usdcBalance = USDC.balanceOf(address(this));
        USDC.approve(address(pool), usdcBalance);
        pool.supply(address(USDC), usdcBalance, address(this), 0);
    }

    function _exit() internal override {
        pool.withdraw(address(USDC), type(uint256).max, address(this));
    }

    function _withdrawFunds() internal override {
        withdrawERC20(USDC);
    }
}