// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library LiquidityBurnCalculator {
    function calculateBurn(uint256 liquidityTokensBalance, uint256 liquidityTokensAvailableToBurn, uint256 liquidityBurnTime)
        public
        view
        returns (uint256) {
        if(liquidityTokensAvailableToBurn == 0) {
            return 0;
        }

        if(block.timestamp < liquidityBurnTime + 5 minutes) {
            return 0;
        }

        //Maximum burn of 2% every 5 minutes to prevent
        //huge burns at once
        uint256 maxBurn = liquidityTokensBalance * 2 / 100;

        uint256 burnAmount = liquidityTokensAvailableToBurn;

        if(burnAmount > maxBurn) {
            burnAmount = maxBurn;
        }

        return burnAmount;
    }
}