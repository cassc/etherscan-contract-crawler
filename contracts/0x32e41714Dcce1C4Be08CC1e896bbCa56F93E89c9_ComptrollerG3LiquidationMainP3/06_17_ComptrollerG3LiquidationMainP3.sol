// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ComptrollerG3Liquidation.sol";

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 */
contract ComptrollerG3LiquidationMainP3 is ComptrollerG3Liquidation {
    function getLiquidationExtraRepayAmount() public view override returns(uint) {
        // we use static address for liquidation proxy
        address liquidationProxy = 0x17A78cEA1aBAd58A4F6d87DC94A4a748f2965b20;
        if(ILiquidationProxy(liquidationProxy).isNFTLiquidation()) {
            return ILiquidationProxy(liquidationProxy).extraRepayAmount();
        } else {
            return 0;
        }
    }

    function getLiquidationSeizeIndexes() public view override returns(uint[] memory) {
        // we use static address for liquidation proxy
        address liquidationProxy = 0x17A78cEA1aBAd58A4F6d87DC94A4a748f2965b20;
        if(ILiquidationProxy(liquidationProxy).isNFTLiquidation()) {
            return ILiquidationProxy(liquidationProxy).seizeIndexes();
        } else {
            uint[] memory seizeIndexes;
            return seizeIndexes;
        }
    }
}