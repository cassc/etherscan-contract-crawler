// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { I0xExchangeRouter } from '../interfaces/I0xExchangeRouter.sol';
import { IExecutor } from '../executors/IExecutor.sol';
import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';
import { Registry } from '../registry/Registry.sol';

import { Call } from '../lib/Call.sol';
import { Constants } from '../lib/Constants.sol';

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

contract ZeroXExecutor is IExecutor {
    using SafeERC20 for IERC20;

    // This function is called by the vault via delegatecall cannot access state of this contract
    function swap(
        address sellTokenAddress,
        uint sellAmount,
        address buyTokenAddress,
        uint buyAmount,
        bytes memory zeroXSwapData
    ) external {
        Registry registry = VaultBaseExternal(address(this)).registry();
        require(
            registry.accountant().isDeprecated(buyTokenAddress) == false,
            'outputToken is deprecated'
        );
        _checkSingleSwapPriceImpact(
            registry,
            sellTokenAddress,
            sellAmount,
            buyTokenAddress,
            buyAmount
        );

        address _0xExchangeRouter = registry.zeroXExchangeRouter();

        IERC20(sellTokenAddress).approve(_0xExchangeRouter, sellAmount);

        uint balanceBefore = IERC20(buyTokenAddress).balanceOf(address(this));
        // Blindly execute the call to the 0x exchange router
        Call._call(_0xExchangeRouter, zeroXSwapData);

        uint balanceAfter = IERC20(buyTokenAddress).balanceOf(address(this));
        require(
            balanceAfter - balanceBefore >= buyAmount,
            'ZeroXExecutor: Not enough received'
        );

        VaultBaseExternal(address(this)).updateActiveAsset(sellTokenAddress);
        VaultBaseExternal(address(this)).updateActiveAsset(buyTokenAddress);
    }

    function _checkSingleSwapPriceImpact(
        Registry registry,
        address sellTokenAddress,
        uint sellAmount,
        address buyTokenAddress,
        uint buyAmount
    ) internal view {
        uint priceImpactToleranceBasisPoints = registry
            .zeroXMaximumSingleSwapPriceImpactBips();

        (uint inputValue, ) = registry.accountant().assetValue(
            sellTokenAddress,
            sellAmount
        );
        (uint outputValue, ) = registry.accountant().assetValue(
            buyTokenAddress,
            buyAmount
        );

        if (outputValue >= inputValue) {
            return;
        }

        uint priceImpact = ((inputValue - outputValue) *
            Constants.BASIS_POINTS_DIVISOR) / inputValue;

        require(
            priceImpact <= priceImpactToleranceBasisPoints,
            'ZeroXExecutor: Price impact too high'
        );
    }
}