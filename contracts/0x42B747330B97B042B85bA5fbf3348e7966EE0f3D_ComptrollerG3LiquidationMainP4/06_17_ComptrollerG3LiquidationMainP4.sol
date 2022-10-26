// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ComptrollerG3Liquidation.sol";

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 */
contract ComptrollerG3LiquidationMainP4 is ComptrollerG3Liquidation {
    function getLiquidationExtraRepayAmount() public view override returns(uint) {
        // we use static address for liquidation proxy
        address liquidationProxy = 0x6b724474f3DE82FE4D37001bbe7235eEC1dE6035;
        if(ILiquidationProxy(liquidationProxy).isNFTLiquidation()) {
            return ILiquidationProxy(liquidationProxy).extraRepayAmount();
        } else {
            return 0;
        }
    }

    function getLiquidationSeizeIndexes() public view override returns(uint[] memory) {
        // we use static address for liquidation proxy
        address liquidationProxy = 0x6b724474f3DE82FE4D37001bbe7235eEC1dE6035;
        if(ILiquidationProxy(liquidationProxy).isNFTLiquidation()) {
            return ILiquidationProxy(liquidationProxy).seizeIndexes();
        } else {
            uint[] memory seizeIndexes;
            return seizeIndexes;
        }
    }
}