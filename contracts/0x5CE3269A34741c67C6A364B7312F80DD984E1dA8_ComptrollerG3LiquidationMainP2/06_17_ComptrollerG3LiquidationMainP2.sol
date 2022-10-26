// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ComptrollerG3Liquidation.sol";

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 */
contract ComptrollerG3LiquidationMainP2 is ComptrollerG3Liquidation {
    function getLiquidationExtraRepayAmount() public view override returns(uint) {
        // we use static address for liquidation proxy
        address liquidationProxy = 0xfaD844e28b309269bF7D11A7BC6B2ed993175598;
        if(ILiquidationProxy(liquidationProxy).isNFTLiquidation()) {
            return ILiquidationProxy(liquidationProxy).extraRepayAmount();
        } else {
            return 0;
        }
    }

    function getLiquidationSeizeIndexes() public view override returns(uint[] memory) {
        // we use static address for liquidation proxy
        address liquidationProxy = 0xfaD844e28b309269bF7D11A7BC6B2ed993175598;
        if(ILiquidationProxy(liquidationProxy).isNFTLiquidation()) {
            return ILiquidationProxy(liquidationProxy).seizeIndexes();
        } else {
            uint[] memory seizeIndexes;
            return seizeIndexes;
        }
    }
}